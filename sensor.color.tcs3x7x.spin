{
    --------------------------------------------
    Filename: sensor.color.tcs3x7x.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Jun 24, 2018
    Updated: Oct 15, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = SLAVE_WR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 400_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR

    byte _ackbit

OBJ

    core  : "core.con.tcs3x7x"
    i2c   : "jm_i2c_fast"
    time  : "time"

PUB null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (1)
                ifnot Ping
                    return okay

    return FALSE                                                'If we got here, something went wrong

PUB Ping: ack

    i2c.start
    ack := i2c.write (SLAVE_WR)
    i2c.stop

PUB EnableInts(enabled) | cmd, tmp, aen, wen, pon

    case ||enabled
        0, 1: enabled := ||enabled
        OTHER:
            return

    tmp := GetEnable        'We need to preserve the other bits in the register
                            'before modifying the state of this bit, so read the reg first
    wen := tmp >> 3 & %1
    aen := tmp >> 1 & %1
    pon := tmp & %1

    tmp := ((enabled << 4) | (wen << 3) | (aen << 1) | pon) & $1F
    writeReg8 (core#REG_ENABLE, tmp)

PUB EnableRGBC(enabled) | cmd, tmp, aien, wen, pon

    case ||enabled
        0, 1: enabled := ||enabled
        OTHER: return FALSE

    tmp := GetEnable        'We need to preserve the other bits in the register
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

    tmp := GetEnable        'We need to preserve the other bits in the register
                            'before modifying the state of this bit, so read the reg first
    aien := tmp >> 4 & %1
    aen := tmp >> 1 & %1
    pon := tmp & %1

    tmp := ((aien << 4) | (enabled << 3) | (aen << 1) | pon) & $1F
    writeReg8 (core#REG_ENABLE, tmp)

PUB EnableWaitLong(enabled) | cmd, tmp, aien, aen, pon
'' Wait (long) time
''  If enabled, wait cycles set using the SetWaitTime method are increased 12x
'' XXX Investigate merging this functionality with SetWaitTime to simplify use
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER: return FALSE

    writeReg8 (core#REG_CONFIG, enabled << 1)

' XXX Should any of the Get* methods that return other than boolean values return parsed values?
PUB GetAEN

  return (GetEnable >> 1) & %1

PUB GetAIEN

  return (GetEnable >> 4) & %1

PUB GetConfig: reg_config

  readRegX(core#REG_CONFIG, 1, @reg_config)
  reg_config := (reg_config >> 1) & %1

PUB GetGain: gain

  readRegX(core#REG_CONTROL, 1, @gain)
  gain &= %11

PUB GetWEN

    return (GetEnable >> 3) & %1

PUB GetEnable: reg_enable

    readRegX(core#REG_ENABLE, 8, @reg_enable)

PUB GetPartID: reg_devid

    readRegX(core#REG_DEVID, 8, @reg_devid)

PUB GetATIME: reg_atime

    readRegX(core#REG_ATIME, 8, @reg_atime)

PUB GetStatus: reg_status

    readRegX(core#REG_STATUS, 8, @reg_status)

PUB GetWTIME: reg_wtime

    readRegX(core#REG_WTIME, 8, @reg_wtime)

PUB GetRGBC(ptr_frame)

    readRegX (core#REG_CDATAL, 8, ptr_frame)

PUB IsIntEnabled | tmp
' Is the RGBC interrupt enabled?
' Gets the AIEN bit from the ENABLE register, and promotes to TRUE
  tmp := GetAIEN * TRUE
  return tmp

PUB IsPowered | tmp
' Is the sensor powered up?
' Gets the PON bit from the ENABLE register, and promotes to TRUE
  tmp := (GetEnable & %1) * TRUE
  return tmp

PUB IsRGBCEnabled | tmp
' Are the sensor's RGBC ADC's enabled?
' Gets the AEN bit from the ENABLE register, and promotes to TRUE

  tmp := GetAEN * TRUE
  return tmp

PUB IsWaitEnabled | tmp
' Is the sensor's wait timer enabled?
' Gets the WEN bit from the ENABLE register, and promotes to TRUE

  tmp := GetWEN * TRUE
  return tmp

PUB IsWaitLongEnabled | tmp
' Are long wait times enabled?
' Gets the WLONG bit from the CONFIG register, and promotes to TRUE

  tmp := GetConfig * TRUE
  return tmp

PUB Power(powered) | cmd, tmp, aien, wen, aen

    case ||powered
        0, 1: powered := ||powered
        OTHER: return FALSE

    tmp := GetEnable    'We need to preserve the other bits in the register
                        'before modifying the state of this bit, so read the reg first
    aien := tmp >> 4 & %1
    wen := tmp >> 3 & %1
    aen := tmp >> 1 & %1

    tmp := ((aien << 4) | (wen << 3) | (aen << 1) | powered) & $1F

    writeReg8 (core#REG_ENABLE, tmp)

    if powered
        time.USleep (2400)  'Wait 2.4ms per datasheet p.15

PUB SetGain (factor) | again, cmd
'' RGBC Gain Control
''  Set amplifier gain to 1x (power-on default), 4x, 16x or 60x
    case factor
        1:  again := %00
        4:  again := %01
        16: again := %10
        60: again := %11
        OTHER:
            return FALSE

    writeReg8 (core#REG_CONTROL, again & %11)

PUB SetIntegrationTime (cycles) | atime, cmd
'' ADC Integration time, in cycles
''  Each cycle is approx 2.4ms (exception: 256 cycles is 700ms)
''  Max resolution (65535 ADC counts) achieved with 64..256
''  Default or invalid value sets 0 (power on value)
    case cycles
        1..256:
            atime := 256-cycles
        OTHER:
            return FALSE

    writeReg8 (core#REG_ATIME, atime)

PUB SetIntThreshold(low_thresh, high_thresh)
'' RGBC Interrupt Threshold
''  Sets low and high thresholds for triggering an interrupt
''  Out-of-bounds values get clamped to the minimum and maximum allowed values (0..65535)
''  NOTE: This works only with the CLEAR data channel
    low_thresh := 0 #> low_thresh <# $FFFF  ' Clamp values to 0..65535
    high_thresh := 0 #> high_thresh <# $FFFF  ' Clamp values to 0..65535

    writeReg16 (core#REG_AILTL, low_thresh, high_thresh)

PUB SetPersistence (cycles) | cmd, apers
'' Interrupt persistence, in cycles
''  How many consecutive measurements that have to be outside the set threshold
''  before an interrupt is actually triggered
''  Valid values:
''    0 - Every measurement triggers an interrupt, regardless
''    1 - Every measurement outside the set threshold triggers an interrupt
''    2 - Must be 2 consecutive measurements outside the set threshold to trigger an interrupt
''    3 - ditto
''    5..60 (multiples of 5)
''    Invalid values will be ignored
    case cycles
        0..3:   apers := cycles
        5..60:  apers := cycles / 5 + 3
        OTHER:  return FALSE

    writeReg8 (core#REG_APERS, apers)

PUB SetWaitTime (cycles) | cmd, wtime
'' Wait time, in cycles
''  Each cycle is approx 2.4ms
''  unless the WLONG bit in the CONFIG register is set,
''  then the wait times are 12x longer
''  Default or invalid value ignored
    case cycles
        1..256:
            wtime := 256-cycles
        OTHER:
            return FALSE

    writeReg8 (core#REG_WTIME, wtime)

PUB readRegX(reg, bytes, dest) | cmd
'PRI
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

PUB readThresh: thresh | cmd, read_tmp

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
