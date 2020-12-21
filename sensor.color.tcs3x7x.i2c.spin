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

PUB Null
' This is not a top-level object

PUB Start: okay                                                 ' Default to "standard" Propeller I2C pins and 400kHz

    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)    ' I2C Object Started?
                time.msleep(1)
                if i2c.present(SLAVE_WR)
                    if lookdown(deviceid: core#DEVID_3472_1_5, core#DEVID_3472_3_7)
                        return okay                             ' Is it really a TCS3472x part?
    return FALSE                                                ' If we got here, something went wrong

PUB Stop

    opmode(PAUSE)
    powered(FALSE)
    i2c.terminate

PUB Defaults
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

PUB ClearInt
' Clears an asserted interrupt
' NOTE: This affects both the state of the sensor's INT pin,
' as well as the interrupt flag in the STATUS register, as read by the Interrupt method.
    writereg(core#SF_CLR_INT_CLR, 0, 0)

PUB DataReady
' Check if the sensor data is valid (i.e., has completed an integration cycle)
'   Returns TRUE if so, FALSE if not
    result := FALSE
    readreg(core#STATUS, 1, @result)
    result := (result & %1) * TRUE

PUB DeviceID
' Read device ID
'   Returns:
'       $44: TCS34721 and TCS34725
'       $4D: TCS34723 and TCS34727
    result := $00
    readreg(core#DEVID, 1, @result)

PUB Gain(factor) | tmp
' Set sensor amplifier gain, as a multiplier
'   Valid values: 1, 4, 16, 60
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#CONTROL, 1, @tmp)
    case factor
        1, 4, 16, 60:
            factor := lookdownz(factor: 1, 4, 16, 60)
        OTHER:
            result := tmp & core#AGAIN_BITS
            return lookupz(result: 1, 4, 16, 60)

    factor &= core#CONTROL_MASK
    writereg(core#CONTROL, 1, factor)

PUB IntegrationTime (usec) | tmp
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
    tmp := $00
    readreg(core#ATIME, 1, @tmp)
    case usec
        2_400..612_000:
            usec := 256-(usec/2_400)
        700_000:
            usec := 0
        OTHER:
            case tmp
                $01..$FF:
                    result := (256-tmp) * 2_400
                $00:
                    result := 700_000
            return
    writereg(core#ATIME, 1, usec)

PUB Interrupt
' Flag indicating an interrupt has been triggered
'   Returns TRUE (-1) or FALSE
    result := $00
    readreg(core#STATUS, 1, @result)
    result := ((result >> core#AINT) & %1) * TRUE
    return

PUB IntsEnabled(enabled) | tmp
' Allow interrupts to assert the INT pin
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
'   Returns: TRUE if an interrupt occurs, FALSE otherwise.
'   NOTE: This doesn't affect the interrupt flag in the STATUS register.
    tmp := $00
    readreg(core#ENABLE, 1, @tmp)
    case ||(enabled)
        0, 1: enabled := ||(enabled) << core#AIEN
        OTHER:
            result := ((tmp >> core#AIEN) & %1) * TRUE
            return

    tmp &= core#AIEN_MASK
    tmp := (tmp | enabled) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, tmp)

PUB IntThreshold(low, high) | tmp
' Sets low and high thresholds for triggering an interrupt
'   Valid values: 0..65535 for both low and high thresholds
'   Any other value polls the chip and returns the current setting
'      Low threshold is returned in the least significant word
'      High threshold is returned in the most significant word
'   NOTE: This works only with the CLEAR data channel
    tmp := $00
    readreg(core#AILTL, 4, @tmp)
    case low
        0..65535:
        OTHER:
            return tmp

    case high
        0..65535:
            tmp := (high << 16) | low
        OTHER:
            return tmp

    writereg(core#AILTL, 4, tmp)

PUB OpMode(mode) | tmp
' Set sensor operating mode
'   Valid values:
'       PAUSE (0): Pause measurement
'       MEASURE (1): Continuous measurement
'   Any other value polls the chip and returns the current setting
' NOTE: If disabling the sensor, the previously acquired data will remain latched in sensor
' (during same power cycle - doesn't survive resets).
    tmp := $00
    readreg(core#ENABLE, 1, @tmp)
    case mode
        PAUSE, MEASURE:
            mode <<= core#AEN
        OTHER:
            result := (tmp >> core#AEN) & %1
            return

    tmp &= core#AEN_MASK
    tmp := (tmp | mode) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, tmp)

PUB Persistence (cycles) | tmp
' Set Interrupt persistence, in cycles
'   Defines how many consecutive measurements must be outside the interrupt threshold (Set with IntThreshold)
'   before an interrupt is actually triggered (e.g., to reduce false positives)
'   Valid values:
'       0 - _Every measurement_ triggers an interrupt, _regardless_
'       1 - Every measurement _outside your set threshold_ triggers an interrupt
'       2 - Must be 2 consecutive measurements outside the set threshold to trigger an interrupt
'       3 - Must be 3 consecutive measurements outside the set threshold to trigger an interrupt
'       5..60 - _n_ consecutive measurements, in multiples of 5
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#PERS, 1, @tmp)
    case cycles
        0..3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60:
            cycles := lookdownz(cycles: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60) & core#APERS_BITS
        OTHER:
            result := tmp & core#APERS_BITS
            return lookupz(result: 0, 1, 2, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60)

    tmp &= core#PERS_MASK
    writereg(core#PERS, 1, cycles)

PUB Powered(enabled) | tmp
' Enable power to the sensor
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#ENABLE, 1, @tmp)
    case ||(enabled)
        0, 1: enabled := ||(enabled) << core#PON
        OTHER:
            result := ((tmp >> core#PON) & %1) * TRUE
            return

    tmp &= core#PON_MASK
    tmp := (tmp | enabled) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, tmp)

    if enabled
        time.USleep (2400)  'Wait 2.4ms per datasheet p.15

PUB RGBCData(buff_addr)
' Get sensor data into buff_addr
'   Data format:
'       WORD 0: Clear channel
'       WORD 1: Red channel
'       WORD 2: Green channel
'       WORD 3: Blue channel
' IMPORTANT: This buffer needs to be 4 words in length
    readreg(core#CDATAL, 8, buff_addr)

PUB WaitTime (cycles) | tmp
' Wait time, in cycles (see WaitTimer)
'   Each cycle is approx 2.4ms
'   unless long waits are enabled (WaitLongEnabled(TRUE))
'   then the wait times are 12x longer
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#WTIME, 1, @tmp)
    case cycles
        1..256:
            cycles := 256-cycles
        OTHER:
            return result := 256-tmp

    writereg(core#WTIME, 1, cycles)

PUB WaitTimer(enabled) | tmp
' Enable sensor wait timer
'   Valid values: FALSE, TRUE or 1
'   Any other value polls the chip and returns the current setting
'   NOTE: Used for power management - allows sensor to wait in between acquisition cycles
'       If enabled, use SetWaitTime to specify number of cycles
    tmp := $00
    readreg(core#ENABLE, 1, @tmp)
    case ||(enabled)
        0, 1: enabled := ||(enabled) << core#WEN
        OTHER:
            result := ((tmp >> core#WEN) & %1) * TRUE
            return

    tmp &= core#WEN_MASK
    tmp := (tmp | enabled) & core#ENABLE_MASK
    writereg(core#ENABLE, 1, tmp)

PUB WaitLongTimer(enabled) | tmp
' Enable longer wait time cycles
'   If enabled, wait cycles set using the SetWaitTime method are increased by a factor of 12x
'   Valid values: FALSE, TRUE or 1
'   Any other value polls the chip and returns the current setting
' XXX Investigate merging this functionality with WaitTimer to simplify use
    tmp := $00
    readreg(core#CONFIG, 1, @tmp)
    case ||(enabled)
        0, 1:
            enabled := (||(enabled)) << core#WLONG
        OTHER:
            result := (tmp >> core#WLONG)
            result := (result & %1) * TRUE
            return


    enabled &= core#CONFIG_MASK
    writereg(core#CONFIG, 1, enabled)

PRI readReg(reg, bytes, dest) | cmd

    case bytes
        0:
            return
        1:
            cmd.word[0] := CMD_BYTE | (reg << 8)
        OTHER:
            cmd.word[0] := CMD_BLOCK | (reg << 8)

    i2c.start
    i2c.wr_block(@cmd, 2)

    i2c.start
    i2c.write(SLAVE_RD)
    i2c.rd_block(dest, bytes, TRUE)
    i2c.stop

PRI writeReg(reg, bytes, val) | cmd[2]

    case bytes
        0:
            cmd.word[0] := CMD_SF | (reg << 8)
            bytes := val := 0
        1:
            cmd.word[0] := CMD_BYTE | (reg << 8)
            cmd.byte[2] := val
        2:
            cmd.word[0] := CMD_BLOCK | (reg << 8)
            cmd.word[1] := val
        4:
            cmd.word[0] := CMD_BLOCK | (reg << 8)
            cmd.word[1] := val.word[0]
            cmd.word[2] := val.word[1]

        OTHER:
            return

    i2c.start
    i2c.wr_block(@cmd, bytes + 2)
    i2c.stop

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
