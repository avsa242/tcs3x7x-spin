{
    --------------------------------------------
    Filename: sensor.color.tcs3x7x.i2c.spin
    Author: Jesse Burt
    Description: Driver for the TAOS TCS3x7x RGB color sensor
    Copyright (c) 2020
    Started: Jun 24, 2018
    Updated: Dec 21, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = SLAVE_WR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    CMD_BYTE        = (core#CMD | core#TYPE_BYTE) << 8 | SLAVE_WR
    CMD_BLOCK       = (core#CMD | core#TYPE_BLOCK) << 8 | SLAVE_WR
    CMD_SF          = (core#CMD | core#TYPE_SPECIAL) << 8 | SLAVE_WR

' Some symbolic constants that can be used with the Gain method
    GAIN_DEF        = 1
    GAIN_LOW        = 4
    GAIN_MED        = 16
    GAIN_HI         = 60

' Operating modes
    PAUSE           = 0
    MEASURE         = 1

OBJ

    core  : "core.con.tcs3x7x"
    i2c   : "com.i2c"
    time  : "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(1)
                if i2c.present(SLAVE_WR)
                    if lookdown(deviceid{}: core#DEVID_3472_1_5,{
}                   core#DEVID_3472_3_7)
                        return okay
    return FALSE                                ' something above failed

PUB Stop{}

    opmode(PAUSE)
    powered(FALSE)
    i2c.terminate{}

PUB Defaults{}
' Factory defaults
    intsenabled(FALSE)
    waittimer(FALSE)
    opmode(PAUSE)
    powered(FALSE)
    integrationtime(2_400)
    waittime(2_400)
    intthreshold(0, 0)
    persistence(0)
    waitlongtimer(FALSE)
    gain(1)

PUB DataReady{}: flag
' Flag indicating new RGBC data sample ready
'   Returns TRUE if so, FALSE if not
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag & 1) == 1)

PUB DeviceID{}: id
' Read device ID
'   Returns:
'       $44: TCS34721 and TCS34725
'       $4D: TCS34723 and TCS34727
    id := 0
    readreg(core#DEVID, 1, @id)

PUB Gain(factor): curr_gain
' Set sensor amplifier gain, as a multiplier
'   Valid values: 1, 4, 16, 60
'   Any other value polls the chip and returns the current setting
    curr_gain := 0
    readreg(core#CONTROL, 1, @curr_gain)
    case factor
        1, 4, 16, 60:
            factor := lookdownz(factor: 1, 4, 16, 60)
        other:
            curr_gain &= core#AGAIN_BITS
            return lookupz(curr_gain: 1, 4, 16, 60)

    factor &= core#CONTROL_MASK
    writereg(core#CONTROL, 1, factor)

PUB IntClear{}
' Clears an asserted interrupt
' NOTE: This clears an active interrupt asserting the INT pin, as well as
'   the flag readable using the Interrupt() method
    writereg(core#SF_CLR_INT_CLR, 0, 0)

PUB IntegrationTime(usec): curr_itime
' Set sensor integration time, in microseconds
'   Valid values: 2_400 to 700_000, in multiples of 2_400
'   Any other value polls the chip and returns the current setting
'   NOTE: Setting will be rounded, if an even multiple of 2_400 isn't given
'   NOTE: Max effective resolution achieved with 154_000..700_000
'   Each cycle is approx 2.4ms (exception: 256 cycles is 700ms)
'
'   Cycles      Time    Effective range:
'   1           2.4ms   10 bits     (max count: 1024)
'   10          24ms    13+ bits    (max count: 10240)
'   42          101ms   15+ bits    (max count: 43008)
'   64          154ms   16 bits     (max count: 65535)
'   256         700ms   16 bits     (max count: 65535)
    curr_itime := 0
    readreg(core#ATIME, 1, @curr_itime)
    case usec
        2_400..612_000:
            usec := 256-(usec/2_400)
        700_000:
            usec := 0
        other:
            case curr_itime
                $01..$FF:
                    curr_itime := (256-curr_itime) * 2_400
                $00:
                    curr_itime := 700_000
            return
    writereg(core#ATIME, 1, usec)

PUB Interrupt{}: flag
' Flag indicating an interrupt has been triggered
'   Returns TRUE (-1) or FALSE
'   NOTE: An active interrupt will always be visible using Interrupt(),
'       however, to be visible on the INT pin, IntsEnabled()
'       must be set to TRUE
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag >> core#AINT) & 1) == 1

PUB IntsEnabled(state): curr_state
' Allow interrupts to assert the INT pin
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1: state := ||(state) << core#AIEN
        other:
            return ((curr_state >> core#AIEN) & 1) == 1

    curr_state &= core#AIEN_MASK
    curr_state := (curr_state | state) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, curr_state)

PUB IntThreshold(low, high): curr_thr | tmp
' Sets low and high thresholds for triggering an interrupt
'   Valid values: 0..65535 for both low and high thresholds
'   Any other value polls the chip and returns the current setting
'      Low threshold is returned in the least significant word
'      High threshold is returned in the most significant word
'   NOTE: This works only with the CLEAR data channel
    curr_thr := 0
    readreg(core#AILTL, 4, @curr_thr)
    case low
        0..65535:
        other:
            return curr_thr

    case high
        0..65535:
            tmp := (high << 16) | low
        other:
            return curr_thr

    writereg(core#AILTL, 4, tmp)

PUB OpMode(mode): curr_mode
' Set sensor operating mode
'   Valid values:
'       PAUSE (0): Pause measurement
'       MEASURE (1): Continuous measurement
'   Any other value polls the chip and returns the current setting
' NOTE: If disabling the sensor, the previously acquired data will remain latched in sensor
' (during same power cycle - doesn't survive resets).
    curr_mode := 0
    readreg(core#ENABLE, 1, @curr_mode)
    case mode
        PAUSE, MEASURE:
            mode <<= core#AEN
        other:
            return (curr_mode >> core#AEN) & 1

    curr_mode &= core#AEN_MASK
    curr_mode := (curr_mode | mode) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, curr_mode)

PUB Persistence(cycles): curr_cyc
' Set number of consecutive cycles necessary to generate an interrupt
'   Valid values:
'       *0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
'       Special cases:
'           0: Every cycle generates an interrupt, regardless of value
'           1: Any value outside the threshold generates an interrupt
'   Any other value polls the chip and returns the current setting
    curr_cyc := 0
    readreg(core#PERS, 1, @curr_cyc)
    case cycles
        0..3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60:
            cycles := lookdownz(cycles: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35,{
}           40, 45, 50, 55, 60) & core#APERS_BITS
        other:
            curr_cyc &= core#APERS_BITS
            return lookupz(curr_cyc: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35,{
}           40, 45, 50, 55, 60)

    curr_cyc &= core#PERS_MASK
    writereg(core#PERS, 1, cycles)

PUB Powered(state): curr_state
' Enable power to the sensor
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1: state := ||(state) << core#PON
        other:
            return ((curr_state >> core#PON) & 1) == 1

    curr_state &= core#PON_MASK
    curr_state := (curr_state | state) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, curr_state)

    if state
        time.usleep(2400)                       'Wait 2.4ms per datasheet p.15

PUB RGBCData(ptr_buff)
' Get sensor data into ptr_buff
'   Data format:
'       WORD 0: Clear channel
'       WORD 1: Red channel
'       WORD 2: Green channel
'       WORD 3: Blue channel
' IMPORTANT: This buffer needs to be 4 words in length
    readreg(core#CDATAL, 8, ptr_buff)

PUB WaitTime(cycles): curr_cyc
' Wait time, in cycles (see WaitTimer)
'   Each cycle is approx 2.4ms
'   unless long waits are enabled (WaitLongEnabled(TRUE))
'   then the wait times are 12x longer
'   Any other value polls the chip and returns the current setting
    curr_cyc := 0
    readreg(core#WTIME, 1, @curr_cyc)
    case cycles
        1..256:
            cycles := 256-cycles
        other:
            return 256-curr_cyc

    writereg(core#WTIME, 1, cycles)

PUB WaitTimer(state): curr_state
' Enable sensor wait timer
'   Valid values: FALSE, TRUE or 1
'   Any other value polls the chip and returns the current setting
'   NOTE: Used for power management - allows sensor to wait in between
'       acquisition cycles. If state, use WaitTime() to specify
'       number of cycles.
    curr_state := 0
    readreg(core#ENABLE, 1, @curr_state)
    case ||(state)
        0, 1: state := ||(state) << core#WEN
        other:
            return ((curr_state >> core#WEN) & 1) == 1

    curr_state &= core#WEN_MASK
    curr_state := (curr_state | state) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, curr_state)

PUB WaitLongTimer(state) | curr_state
' Enable longer wait time cycles
'   If state, wait cycles set using the SetWaitTime method are increased by a factor of 12x
'   Valid values: FALSE, TRUE or 1
'   Any other value polls the chip and returns the current setting
' XXX Investigate merging this functionality with WaitTimer to simplify use
    curr_state := 0
    readreg(core#CONFIG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state)) << core#WLONG
        other:
            return ((curr_state >> core#WLONG) & 1) == 1

    state &= core#CONFIG_MASK
    writereg(core#CONFIG, 1, state)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    case nr_bytes
        0:
            return
        1:
            cmd_pkt.word[0] := CMD_BYTE | (reg_nr << 8)
        other:
            cmd_pkt.word[0] := CMD_BLOCK | (reg_nr << 8)

    i2c.start{}
    i2c.wr_block(@cmd_pkt, 2)

    i2c.start{}
    i2c.write(SLAVE_RD)
    i2c.rd_block(ptr_buff, nr_bytes, TRUE)
    i2c.stop{}

PRI writeReg(reg_nr, nr_bytes, val) | cmd_pkt[2]
' Write nr_nr_bytes in val to device
    case nr_bytes
        0:
            cmd_pkt.word[0] := CMD_SF | (reg_nr << 8)
            nr_bytes := val := 0
        1:
            cmd_pkt.word[0] := CMD_BYTE | (reg_nr << 8)
            cmd_pkt.byte[2] := val
        2:
            cmd_pkt.word[0] := CMD_BLOCK | (reg_nr << 8)
            cmd_pkt.word[1] := val
        4:
            cmd_pkt.word[0] := CMD_BLOCK | (reg_nr << 8)
            cmd_pkt.word[1] := val.word[0]
            cmd_pkt.word[2] := val.word[1]

        other:
            return

    i2c.start{}
    i2c.wr_block(@cmd_pkt, nr_bytes + 2)
    i2c.stop{}

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
