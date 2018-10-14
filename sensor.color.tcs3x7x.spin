{
    --------------------------------------------
    Filename: sensor.color.tcs3x7x.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Jun 24, 2018
    Updated: Oct 14, 2018
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

    tmp := GetEnable    'We need to preserve the other bits in the register
                        'before modifying the state of this bit, so read the reg first
    wen := tmp >> 3 & %1
    aen := tmp >> 1 & %1
    pon := tmp & %1

    tmp := ((enabled << 4) | (wen << 3) | (aen << 1) | pon) & $1F
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_ENABLE
    cmd.byte[2] := tmp

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

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
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_ENABLE
    cmd.byte[2] := tmp

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
  i2c.stop

PUB EnableWait(enabled) | cmd, tmp, aien, aen, pon

    case ||enabled
        0, 1: enabled := || enabled
        OTHER:  return FALSE

    tmp := GetEnable    'We need to preserve the other bits in the register
                        'before modifying the state of this bit, so read the reg first
    aien := tmp >> 4 & %1
    aen := tmp >> 1 & %1
    pon := tmp & %1

    tmp := ((aien << 4) | (enabled << 3) | (aen << 1) | pon) & $1F
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_ENABLE
    cmd.byte[2] := tmp

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

PUB EnableWaitLong(enabled) | cmd, tmp, aien, aen, pon
'' Wait (long) time
''  If enabled, wait cycles set using the SetWaitTime method are increased 12x
'' XXX Investigate merging this functionality with SetWaitTime to simplify use
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER: return FALSE

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_CONFIG
    cmd.byte[2] := enabled << 1

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

' XXX Should any of the Get* methods that return other than boolean values return parsed values?
PUB GetAEN

  return (GetEnable >> 1) & %1

PUB GetAIEN

  return (GetEnable >> 4) & %1

PUB GetConfig

  return (readReg8(core#REG_CONFIG) >> 1) & %1

PUB GetGain

  return readReg8(core#REG_CONTROL) & %11

PUB GetWEN

  return (GetEnable >> 3) & %1

PUB GetEnable

  return readReg8(core#REG_ENABLE)

PUB GetPartID

  return readReg8(core#REG_DEVID)

PUB GetATIME

  return readReg8(core#REG_ATIME)

PUB GetStatus

  return readReg8(core#REG_STATUS)

PUB GetWTIME

  return readReg8(core#REG_WTIME)

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

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_ENABLE
    cmd.byte[2] := tmp

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

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

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_CONTROL
    cmd.byte[2] := again & %11

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

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
'  return atime '*** DEBUG
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_ATIME
    cmd.byte[2] := atime

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

PUB SetIntThreshold(word__low_thresh, word__high_thresh) | cmd{should this be 2? review}, long_threshold, i
'' RGBC Interrupt Threshold
''  Sets low and high thresholds for triggering an interrupt
''  Out-of-bounds values get clamped to the minimum and maximum allowed values (0..65535)
''  NOTE: This works only with the CLEAR data channel
    word__low_thresh := 0 #> word__low_thresh <# $FFFF  ' Clamp values to 0..65535
    word__high_thresh := 0 #> word__high_thresh <# $FFFF  ' Clamp values to 0..65535

    long_threshold.word[0] := word__low_thresh
    long_threshold.word[1] := word__high_thresh

    '  return long_threshold    '*** DEBUG
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BLOCK | core#REG_AILTL
    cmd.word[1] := long_threshold.word[0]
    cmd.word[2] := long_threshold.word[1]

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 6)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

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

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BLOCK | core#REG_APERS
    cmd.byte[2] := apers

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

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

'  return wtime '*** DEBUG
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | core#REG_WTIME
    cmd.byte[2] := wtime

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 3)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    i2c.stop

PUB readReg8(tcs_reg): data | cmd
'PRI
    ifnot lookdown(tcs_reg: $00, $01, $03..$07, $0C, $0D, $0F, $12..$1B) 'Validate register passed is an 8bit register
        return

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BYTE | tcs_reg  'Set up for single address read

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 2)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    data := readOne

PUB readReg16(tcs_reg): data | cmd
'PRI
    ifnot lookdown(tcs_reg: $04, $06, $14, $16, $18, $1A) 'Validate register passed is a 16bit register
        return $DEADC0DE  'XXX For testing only; remove for production

    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BLOCK | tcs_reg

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 2)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE
    readX (@data, 2)

PUB readFrame(ptr_frame) | cmd, read_tmp[2], b
'PRI
    cmd.byte[0] := SLAVE_WR
    cmd.byte[1] := core#CMD | core#TYPE_BLOCK | core#REG_CDATAL

    i2c.start
    _ackbit := i2c.pwrite (@cmd, 2)
    if _ackbit == i2c#NAK
        i2c.stop
        return FALSE

    i2c.start
    i2c.write (SLAVE_RD)
    i2c.pread (@read_tmp, 8, TRUE)
    i2c.stop

    repeat b from 0 to 7
        byte[ptr_frame][b] := read_tmp.byte[b]

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

PUB readOne: readbyte
'PRI
    i2c.start
    i2c.write (SLAVE_RD)
    readbyte := i2c.read (TRUE)
    i2c.stop

PUB readX(ptr_buff, num_bytes)
'PRI
    i2c.start
    i2c.write (SLAVE_RD)
    i2c.pread (@ptr_buff, num_bytes, TRUE)
    i2c.stop

PUB writeOne(data)
'PRI
    WriteX (data, 1)

PUB WriteX(ptr_buff, num_bytes)
'PRI
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
