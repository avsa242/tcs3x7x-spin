{
    --------------------------------------------
    Filename: TCS3x7x-Demo.spin
    Author: Jesse Burt
    Copyright (c) 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

  _clkmode  = cfg#_clkmode
  _xinfreq  = cfg#_xinfreq

  SCL       = 28
  SDA       = 29
  I2C_HZ    = 100_000
  LED       = 25

  DISP_HELP     = 1
  PRINT_REGS    = 2
  TOGGLE_POWER  = 3
  TOGGLE_RGBC   = 4
  PRINT_RGBC    = 5
  TOGGLE_INTS   = 6
  WAITING       = 10

OBJ

  cfg   : "core.con.client.flip"
  ser   : "com.serial.terminal"
  time  : "time"
  rgb   : "sensor.color.tcs3x7x"
  debug : "debug"
  io    : "io"
  
VAR

  long  _keyDaemon_stack[100]
  byte  _keyDaemon_cog, _rgb_cog, _ser_cog
  byte  _demo_state, _prev_state
  byte  _max_cols


PUB Main

  Setup

  repeat
    case _demo_state
      PRINT_REGS:   PrintRegs
      DISP_HELP:    Help
      TOGGLE_POWER: TogglePower
      TOGGLE_RGBC:  ToggleRGBC
      PRINT_RGBC:   PrintRGBC
      TOGGLE_INTS:  ToggleInts
      WAITING:      waitkey
      OTHER:
        _demo_state := DISP_HELP

PUB PrintRegs | rec_size, table_offs, icol, regval_tmp

  ser.Clear
  repeat until _demo_state <> PRINT_REGS
    ser.Position (0, 0)
    rule (80, 10, ".")
    rec_size := 9
    icol := 0

    ser.Str (string("TCS3x7x Register Map:", ser#NL))
    repeat table_offs from 1 to (tcs_regmap*8) step rec_size
      ser.Str (@tcs_regmap[table_offs+1])
      ser.Str (string("= "))
      regval_tmp := rgb.readReg8 (tcs_regmap[table_offs])
      ser.Hex (regval_tmp, 2)
      ser.Str (string(" | "))
      icol++
      if icol == _max_cols
        ser.NewLine
        icol := 0

    time.MSleep (100)

PUB PrintRGBC | rgbc_data[2], rdata, gdata, bdata, cdata

  ser.Clear
  repeat until _demo_state <> PRINT_RGBC
    io.High (LED)
    rgb.readFrame (@rgbc_data)
    io.Low (LED)
    '     0       1       2       3       4       5       6       7
    'cdatal, cdatah, rdatal, rdatah, gdatal, gdatah, bdatal, bdatah
    cdata := ((rgbc_data.byte[1] << 8) | rgbc_data.byte[0]) & $FFFF
    rdata := ((rgbc_data.byte[3] << 8) | rgbc_data.byte[2]) & $FFFF
    gdata := ((rgbc_data.byte[5] << 8) | rgbc_data.byte[4]) & $FFFF
    bdata := ((rgbc_data.byte[7] << 8) | rgbc_data.byte[6]) & $FFFF
    ser.Position (0, 0)
    ser.Str (string("TCS3x7x RGBC Data:", ser#NL, ser#NL))

    ser.Str (string("Red  : "))
    ser.Hex (rdata, 4)
    ser.NewLine

    ser.Str (string("Green: "))
    ser.Hex (gdata, 4)
    ser.NewLine

    ser.Str (string("Blue : "))
    ser.Hex (bdata, 4)
    ser.NewLine

    ser.Str (string("Clear: "))
    ser.Hex (cdata, 4)
    ser.NewLine

    ser.Str (string("NAK cnt: "))
    ser.Dec (rgb.getnaks)
    ser.NewLine
    time.MSleep (100)

PUB ToggleInts | tmp

  ser.NewLine
  ser.Str (string("Turning Interrupts "))
  tmp := rgb.IsIntEnabled
  if tmp
    ser.Str (string("off", ser#NL))
  else
    ser.Str (string("on", ser#NL))

  rgb.EnableInts (!tmp)
  waitkey

PUB TogglePower | tmp

  ser.NewLine
  ser.Str (string("Turning Power "))
  tmp := rgb.IsPowered
  if tmp
    ser.Str (string("off", ser#NL))
  else
    ser.Str (string("on", ser#NL))

  rgb.Power (!tmp)
  waitkey

PUB ToggleRGBC | tmp

  ser.NewLine
  ser.Str (string("Turning RGBC "))
  tmp := rgb.IsRGBCEnabled
  if tmp
    ser.Str (string("off", ser#NL))
    rgb.EnableRGBC (FALSE)

  else
    ser.Str (string("on", ser#NL))
    rgb.EnableRGBC (TRUE)

  waitkey

PUB keyDaemon | key_cmd

  repeat
    repeat until key_cmd := ser.CharIn
    case key_cmd
      "h", "H":
        _prev_state := _demo_state
        _demo_state := DISP_HELP

      "a", "A":
        _prev_state := _demo_state
        _demo_state := TOGGLE_RGBC

      "i", "I":
        _prev_state := _demo_state
        _demo_state := TOGGLE_INTS

      "r", "r":
        _prev_state := _demo_state
        _demo_state := PRINT_REGS

      "p", "P":
        _prev_state := _demo_state
        _demo_state := TOGGLE_POWER

      "s", "S":
        _prev_state := _demo_state
        _demo_state := PRINT_RGBC

      OTHER   :
        if _demo_state == WAITING
          _demo_state := _prev_state
        else
          _prev_state := _demo_state
          _demo_state := DISP_HELP

PUB rule(cols, ind, hash_char) | i
''Method to draw a rule on a terminal
  repeat i from 0 to cols-1
    case i
      0:
        ser.char(":")
      OTHER:
        ifnot i//ind
          ser.Char (":")
        else
          ser.Char (hash_char)
  ser.NewLine

PUB waitkey

  _demo_state := WAITING
  ser.Str (string("Press any key", ser#NL))
  repeat until _demo_state <> WAITING

PUB Help

  ser.Clear
  ser.Str (string("Keys: ", ser#NL, ser#NL))
  ser.Str (string("a, A:  Toggle RGBC (ADC)", ser#NL))
  ser.Str (string("h, H:  This help screen", ser#NL))
  ser.Str (string("i, I:  Toggle RGBC Interrupts", ser#NL))
  ser.Str (string("p, P:  Toggle sensor power", ser#NL))
  ser.Str (string("r, R:  Display register contents", ser#NL))
  ser.Str (string("s, S:  Display RGBC sensor data", ser#NL))
  repeat until _demo_state <> DISP_HELP


PUB Setup

  io.Output (LED)
  io.Low (LED)

  repeat until _ser_cog := ser.Start (115_200)
  ser.Clear
  ser.Str (string("Serial terminal started", ser#NL))
  _keyDaemon_cog := cognew(keyDaemon, @_keyDaemon_stack)
  if _rgb_cog := rgb.Start
    ser.Str (string("tcs3x7x object started", ser#NL))
  else
    ser.Str (string("tcs3x7x object failed to start", ser#NL))
    ser.Stop
    debug.LEDSlow (26)
  _max_cols := 4

DAT

  tcs_regmap  byte 13
  byte $00, "ENABLE ", 0
  byte $01, "ATIME  ", 0
  byte $03, "WTIME  ", 0
  byte $04, "AILTL  ", 0
  byte $05, "AILTH  ", 0
  byte $06, "AIHTL  ", 0
  byte $07, "AIHTH  ", 0
  byte $0C, "PERS   ", 0
  byte $0D, "CONFIG ", 0
  byte $0F, "CONTROL", 0
  byte $12, "ID     ", 0
  byte $13, "STATUS ", 0

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
