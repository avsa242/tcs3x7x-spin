{
    --------------------------------------------
    Filename: sensor.color.tcs3x7x.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Jun 24, 2018
    Updated: Nov 26, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = SLAVE_WR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 400_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    GAIN_DEF        = 1
    GAIN_LOW        = 4
    GAIN_MED        = 16
    GAIN_HI         = 60

VAR

    byte _ackbit

OBJ

    core  : "core.con.tcs3x7x"
    i2c   : "jm_i2c_fast"
    time  : "time"

PRI Null
'' This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                if i2c.present (SLAVE_WR)
                    return okay

    return FALSE                                                'If we got here, something went wrong

PUB EnableInts(enabled) | cmd, tmp, aen, wen, pon

    case ||enabled
        0, 1: enabled := ||enabled
        OTHER:
            return

    tmp := getReg_ENABLE        'We need to preserve the other bits in the register
                                'before modifying the state of this bit, so read the reg first
    wen := tmp >> 3 & %1
    aen := tmp >> 1 & %1
    pon := tmp & %1

    tmp := ((enabled << 4) | (wen << 3) | (aen << 1) | pon) & $1F
    writeReg8 (core#REG_ENABLE, tmp)

PUB EnableSensor(enabled) | cmd, tmp, aien, wen, pon

    case ||enabled
        0, 1: enabled := ||enabled
        OTHER: return FALSE

    tmp := getReg_ENABLE        'We need to preserve the other bits in the register
                                'before modifying the state of this bit, so read the reg first
    aien := tmp >> 4 & %1
    wen := tmp >> 3 & %1
    pon := tmp & %1

    tmp := ((aien << 4) | (wen << 3) | (enabled << 1) | pon) & $1F
    writeReg8 (core#REG_ENABLE, tmp)

PUB EnableWait(enabled) | cmd, tmp, aien, aen, pon

    case ||enabled
        0, 1: enabled := || enabled
        OTHER:  return FALSE

    tmp := getReg_ENABLE        'We need to preserve the other bits in the register
                                'before modifying the state of this bit, so read the reg first
    aien := tmp >> 4 & %1
    aen := tmp >> 1 & %1
    pon := tmp & %1

    tmp := ((aien << 4) | (enabled << 3) | (aen << 1) | pon) & $1F
    writeReg8 (core#REG_ENABLE, tmp)

PUB EnableWaitLong(enabled) | cmd, tmp, aien, aen, pon
' Wait (long) time
'  If enabled, wait cycles set using the SetWaitTime method are increased 12x
' XXX Investigate merging this functionality with SetWaitTime to simplify use
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER: return FALSE

    writeReg8 (core#REG_CONFIG, enabled << 1)

PUB Gain
' Returns current gain setting
    readRegX(core#REG_CONTROL, 1, @result)
    return lookupz((result & %11): 1, 4, 16, 60)

PUB GetStatus: reg_status

    readRegX(core#REG_STATUS, 1, @reg_status)

PUB GetRGBC(buff_addr)
' Get sensor data into buff_addr
' IMPORTANT: This buffer needs to be 8 bytes in length
    readRegX (core#REG_CDATAL, 8, buff_addr)

PUB IntsEnabled
' Are interrupts enabled?
'   Returns TRUE or FALSE
    return ((getReg_ENABLE >> 4) & %1) * TRUE

PUB IntThreshold: thresh | cmd, read_tmp
' Get currently set interrupt thresholds
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BLOCK | core#REG_AILTL

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 2)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE

    i2c.start
    i2c.write (SLAVE_RD)
    i2c.pread (@thresh, 4, TRUE)
    i2c.stop

PUB PartID: reg_devid
' Returns part number of sensor
'  $44: TCS34721 and TCS34725
'  $4D: TCS34723 and TCS34727
    readRegX(core#REG_DEVID, 1, @reg_devid)

PUB Power(enabled) | cmd, tmp, aien, wen, aen
' Enable power to the sensor
'   Valid values: FALSE, TRUE or 1
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER: return FALSE

    tmp := getReg_ENABLE    'We need to preserve the other bits in the register
                            'before modifying the state of this bit, so read the reg first
    aien := tmp >> 4 & %1
    wen := tmp >> 3 & %1
    aen := tmp >> 1 & %1

    tmp := ((aien << 4) | (wen << 3) | (aen << 1) | enabled) & $1F

    writeReg8 (core#REG_ENABLE, tmp)

    if enabled
        time.USleep (2400)  'Wait 2.4ms per datasheet p.15

PUB Powered | tmp
' Is the sensor powered up?
'   Returns TRUE or FALSE
    tmp := (getReg_ENABLE & %1) * TRUE
    return tmp

PUB SensorEnabled
' Is the sensor's data acquisition enabled?
'   Returns TRUE or FALSE
    return ((getReg_ENABLE >> 1) & %1) * TRUE

PUB WaitEnabled
' Checks if the sensor's wait timer enabled?
'   Returns TRUE or FALSE
    return ((getReg_ENABLE >> 3) & %1) * TRUE

PUB WaitLongEnabled
' Checks if long waits are enabled (multiplies wait timer value by a factor of 12)
'   Returns TRUE or FALSE
    readRegX(core#REG_CONFIG, 1, @result)
    result := ((result >> 1) & %1) * TRUE

PUB SetGain (factor) | again
' Set sensor amplifier gain
'   Valid values: 1 (default), 4, 16, 60
'   Invalid values ignored
    case factor
        1:  again := %00
        4:  again := %01
        16: again := %10
        60: again := %11
        OTHER:
            return FALSE

    writeReg8 (core#REG_CONTROL, again & %11)

PUB SetIntegrationTime (cycles) | atime
' Set sensor integration time, in cycles
'   Each cycle is approx 2.4ms (exception: 256 cycles is 700ms)
'
'   Cycles      Time    Effective resolution:
'   1           2.4ms   10 bits     (max count: 1024)
'   10          24ms    13+ bits    (max count: 10240)
'   42          101ms   15+ bits    (max count: 43008)
'   64          154ms   16 bits     (max count: 65535)
'   256         700ms   16 bits     (max count: 65535)
'   Max effective resolution (65535 ADC counts) achieved with 64..256
'   Valid values: 1 to 256
'   Invalid values ignored
    case cycles
        1..256:
            atime := 256-cycles
        OTHER:
            return FALSE

    writeReg8 (core#REG_ATIME, atime)

PUB SetIntThreshold(low_thresh, high_thresh)
' Set CLEAR sensor channel interrupt threshold
'   Sets low and high thresholds for triggering an interrupt
'   Invalid values get clamped to the minimum and maximum allowed values (0..65535)
'   NOTE: This works only with the CLEAR data channel
    low_thresh := 0 #> low_thresh <# $FFFF  ' Clamp values to 0..65535
    high_thresh := 0 #> high_thresh <# $FFFF  ' Clamp values to 0..65535

    writeReg16 (core#REG_AILTL, low_thresh, high_thresh)

PUB SetPersistence (cycles) | apers
' Interrupt persistence, in cycles
'   How many consecutive measurements that have to be outside the set threshold
'   before an interrupt is actually triggered
'   Valid values:
'       0 - Every measurement triggers an interrupt, regardless
'       1 - Every measurement outside the set threshold triggers an interrupt
'       2 - Must be 2 consecutive measurements outside the set threshold to trigger an interrupt
'       3 - Must be 3 consecutive measurements outside the set threshold to trigger an interrupt
'       5..60 (multiples of 5)
'   Invalid values ignored
    case cycles
        0..3:   apers := cycles
        5..60:  apers := cycles / 5 + 3
        OTHER:  return FALSE

    writeReg8 (core#REG_APERS, apers)

PUB SetWaitTime (cycles) | wtime
' Wait time, in cycles
'   Each cycle is approx 2.4ms
'   unless long waits are enabled (WaitLongEnabled(TRUE))
'   then the wait times are 12x longer
'   Invalid values ignored
    case cycles
        1..256:
            wtime := 256-cycles
        OTHER:
            return FALSE

    writeReg8 (core#REG_WTIME, wtime)

PRI getReg_ATIME: reg_atime

    readRegX(core#REG_ATIME, 8, @reg_atime)

PRI getReg_ENABLE: reg_enable

    readRegX(core#REG_ENABLE, 8, @reg_enable)

PRI getReg_WTIME: reg_wtime

    readRegX(core#REG_WTIME, 8, @reg_wtime)

PRI readRegX(reg, bytes, dest) | cmd

    case bytes
        0:
            return
        1:
            cmd.byte[0] := SLAVE_WR
            cmd.byte[1] := core#CMD | core#TYPE_BYTE | reg
        OTHER:
            cmd.byte[0] := SLAVE_WR
            cmd.byte[1] := core#CMD | core#TYPE_BLOCK | reg

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 2)

    i2c.start
    i2c.write (SLAVE_RD)
    i2c.pread (dest, bytes, TRUE)
    i2c.stop

PRI writeReg8(reg, data) | cmd

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | reg
'    cmd.word[0] := CMD_BYTE | (reg << 8) ' up-and-coming change
    cmd.byte[2] := data

    i2c.start
    _ackbit := i2c.pwrite(@cmd, 3)
    i2c.stop

PRI writeReg16(reg, data_h, data_l) | cmd[2]

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BLOCK | reg
'    cmd.word[0] := CMD_BLOCK | (reg << 8) ' up-and-coming change
    cmd.word[1] := data_h
    cmd.word[2] := data_l

    i2c.start
    _ackbit := i2c.pwrite(@cmd, 6)
    i2c.stop

PRI WriteX(ptr_buff, num_bytes)

    i2c.start
    i2c.write (SLAVE_WR)
    i2c.pwrite (ptr_buff, num_bytes)
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
