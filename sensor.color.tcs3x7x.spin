{
    --------------------------------------------
    Filename: sensor.color.tcs3x7x.spin
    Author: Jesse Burt
    Copyright (c) 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

  SLAVE_ADDR        = $29 << 1
  SLAVE_ADDR_W      = SLAVE_ADDR
  SLAVE_ADDR_R      = SLAVE_ADDR|1
  
  DEFAULT_SCL       = 28
  DEFAULT_SDA       = 29
  DEFAULT_HZ        = 400_000
  I2C_MAX_BUS_FREQ  = 400_000

VAR


OBJ

  i2c     : "jm_i2c_fast"
  tcs3x7x : "core.con.tcs3x7x"
  time    : "time"
'  type    : "system.types"

PUB null
''This is not a top-level object

PUB Start: okay                                         'Default to "standard" Propeller I2C pins and 400kHz

  okay := Startx (DEFAULT_SCL, DEFAULT_SDA, DEFAULT_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay | ack

  if lookdown(SCL_PIN: 0..31)                           'Validate pins
    if lookdown(SDA_PIN: 0..31)
      if SCL_PIN <> SDA_PIN
        if I2C_HZ =< I2C_MAX_BUS_FREQ
          if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)      'I2C Object Started?
            time.MSleep (1)
            ifnot Ping
              return okay
            else
              return FALSE
          else
            return FALSE
        else
          return FALSE
      else
        return FALSE
    else
      return FALSE
  else
    return FALSE

PUB Ping: ack

  i2c.start
  ack := i2c.write (SLAVE_ADDR)
  i2c.stop

PUB EnableRGBC(enabled) | cmd, ackbit, tmp, aien, wen, pon

  case enabled
    FALSE:
    OTHER:              ' Anything non-zero will be considered TRUE
      enabled := %1

  tmp := GetEnable      'We need to preserve the other bits in the register
                        'before modifying the state of this bit, so read the reg first
  aien := tmp >> 4 & %1
  wen := tmp >> 3 & %1
  pon := tmp & %1

  tmp := ((aien << 4) | (wen << 3) | (enabled << 1) | pon) & $1F
  cmd.byte[0] := SLAVE_ADDR_W
  cmd.byte[1] := tcs3x7x#CMD | tcs3x7x#TYPE_BYTE | tcs3x7x#REG_ENABLE
  cmd.byte[2] := tmp

  i2c.start
  ackbit := i2c.pwrite (@cmd, 3)
  if ackbit == i2c#NAK
    i2c.stop
    return $DEADBEEF
  i2c.stop

PUB GetAEN

  return ((GetEnable >> 1) & %1) * TRUE

PUB GetAIEN

  return ((GetEnable >> 4) & %1) * TRUE

PUB GetWEN

  return ((GetEnable >> 3) & %1) * TRUE

PUB GetEnable

  return readReg8(tcs3x7x#REG_ENABLE)

PUB GetPartID

  return readReg8(tcs3x7x#REG_DEVID)

PUB GetATIME

  return readReg8(tcs3x7x#REG_ATIME)

PUB GetStatus

  return readReg8(tcs3x7x#REG_STATUS)

PUB GetWTIME

  return readReg8(tcs3x7x#REG_WTIME)

PUB IsPowered | tmp
' Gets the PON bit from the ENABLE register, and promotes to TRUE
  tmp := (GetEnable & %1) * TRUE
  return tmp

PUB IsRGBCEnabled | tmp
' Gets the AEN bit from the ENABLE register, and promotes to TRUE

  tmp := GetAEN * TRUE
  return tmp

PUB Power(powered) | cmd, ackbit, tmp, aien, wen, aen

  case powered
    FALSE:              'If FALSE/zero is passed, leave it alone
    OTHER:              ' anything else will be considered TRUE
      powered := %1

  tmp := GetEnable      'We need to preserve the other bits in the register
                        'before modifying the state of this bit, so read the reg first
  aien := tmp >> 4 & %1
  wen := tmp >> 3 & %1
  aen := tmp >> 1 & %1

  tmp := ((aien << 4) | (wen << 3) | (aen << 1) | powered) & $1F

  cmd.byte[0] := SLAVE_ADDR_W
  cmd.byte[1] := tcs3x7x#CMD | tcs3x7x#TYPE_BYTE | tcs3x7x#REG_ENABLE
  cmd.byte[2] := tmp

  i2c.start
  ackbit := i2c.pwrite (@cmd, 3)
  if ackbit == i2c#NAK
    i2c.stop
    return $DEADBEEF
  i2c.stop

  if powered
    time.USleep (2400)  'Wait 2.4ms per datasheet p.15

PUB readReg8(tcs_reg): data | cmd, ackbit
'PRI
  ifnot lookdown(tcs_reg: $00, $01, $03, $0C, $0D, $0F, $12, $13) 'Validate register passed is an 8bit register
    return

  cmd.byte[0] := SLAVE_ADDR_W
  cmd.byte[1] := tcs3x7x#CMD | tcs3x7x#TYPE_BYTE | tcs_reg  'Set up for single address read

  i2c.start
  ackbit := i2c.pwrite (@cmd, 2)
  if ackbit == i2c#NAK
    i2c.stop
    return $DEADBEEF

  data := readOne

PUB readReg16(tcs_reg): data | cmd, ackbit
'PRI
  ifnot lookdown(tcs_reg: $04, $06, $14, $16, $18, $1A) 'Validate register passed is a 16bit register
    return

  cmd.byte[0] := SLAVE_ADDR_W
  cmd.byte[1] := tcs3x7x#CMD | tcs3x7x#TYPE_BLOCK | tcs_reg

  i2c.start
  ackbit := i2c.pwrite (@cmd, 2)
  if ackbit == i2c#NAK
    i2c.stop
    return $DEADBEEF

  readX (@data, 2)

PUB readFrame(ptr_frame) | cmd, ackbit, read_tmp[2], b
'PRI
  cmd.byte[0] := SLAVE_ADDR_W
  cmd.byte[1] := tcs3x7x#CMD | tcs3x7x#TYPE_BLOCK | tcs3x7x#REG_CDATAL

  i2c.start
  ackbit := i2c.pwrite (@cmd, 2)
  if ackbit == i2c#NAK
    i2c.stop
    return $DEADBEEF

  i2c.start
  i2c.write (SLAVE_ADDR_R)
  i2c.pread (@read_tmp, 8, TRUE)
  i2c.stop

  repeat b from 0 to 7
    byte[ptr_frame][b] := read_tmp.byte[b]

PUB readOne: readbyte
'PRI
  i2c.start
  i2c.write (SLAVE_ADDR_R)
  readbyte := i2c.read (TRUE)
  i2c.stop

PUB readX(ptr_buff, num_bytes)
'PRI
  i2c.start
  i2c.write (SLAVE_ADDR_R)
  i2c.pread (@ptr_buff, num_bytes, TRUE)
  i2c.stop

PUB writeOne(data)
'PRI
  WriteX (data, 1)

PUB WriteX(ptr_buff, num_bytes)
'PRI
  i2c.start
  i2c.write (SLAVE_ADDR_W)
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
