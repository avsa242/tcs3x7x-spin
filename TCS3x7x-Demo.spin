{
    --------------------------------------------
    Filename: TCS3x7x-Demo.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Jun 24, 2018
    Updated: Oct 15, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

  _clkmode          = cfg#_clkmode
  _xinfreq          = cfg#_xinfreq

  LED               = 25

  DISP_HELP         = 1
  TOGGLE_POWER      = 2
  TOGGLE_RGBC       = 3
  PRINT_RGBC        = 4
  TOGGLE_INTS       = 5
  TOGGLE_WAIT       = 6
  TOGGLE_LED        = 7
  TOGGLE_WAITLONG   = 8
  WAITING           = 9

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
  byte  _led_enabled

PUB Main

  Setup

  rgb.SetPersistence (5)
  rgb.SetWaitTime (1)
  rgb.SetGain (1)

  repeat
    case _demo_state
      DISP_HELP:        Help
      TOGGLE_POWER:     TogglePower
      TOGGLE_RGBC:      ToggleRGBC
      PRINT_RGBC:       PrintRGBC
      TOGGLE_INTS:      ToggleInts
      TOGGLE_WAIT:      ToggleWait
      TOGGLE_LED:       ToggleLED
      TOGGLE_WAITLONG:  ToggleWaitLong
      WAITING:          waitkey
      OTHER:
        _demo_state := DISP_HELP

PUB PrintRGBC | rgbc_data[2], rdata, gdata, bdata, cdata, cmax, i

  ser.Clear
  ser.Position (0, 0)
  ser.Str (string("TCS3x7x RGBC Data (dominant color channel surrounded by [ ]):"))

  ser.Position (1, 2)
  ser.Str (string(" Red"))
  ser.Position (1, 3)
  ser.Str (string(" Green"))
  ser.Position (1, 4)
  ser.Str (string(" Blue"))
  ser.Position (1, 5)
  ser.Str (string(" Clear"))

  repeat until _demo_state <> PRINT_RGBC
    if _led_enabled
      io.High (LED)
    rgb.GetRGBC (@rgbc_data)
    io.Low (LED)

    '     0       1       2       3       4       5       6       7
    'cdatal, cdatah, rdatal, rdatah, gdatal, gdatah, bdatal, bdatah
    cdata := ((rgbc_data.byte[1] << 8) | rgbc_data.byte[0]) & $FFFF
    rdata := ((rgbc_data.byte[3] << 8) | rgbc_data.byte[2]) & $FFFF
    gdata := ((rgbc_data.byte[5] << 8) | rgbc_data.byte[4]) & $FFFF
    bdata := ((rgbc_data.byte[7] << 8) | rgbc_data.byte[6]) & $FFFF

    cmax := %00
    if rdata > gdata and rdata > bdata
      cmax := %01
    if gdata > rdata and gdata > bdata
      cmax := %10
    if bdata > rdata and bdata > gdata
      cmax := %11

    ser.Position (10, 2)
    ser.Hex (rdata, 4)

    ser.Position (10, 3)
    ser.Hex (gdata, 4)

    ser.Position (10, 4)
    ser.Hex (bdata, 4)

    ser.Position (10, 5)
    ser.Hex (cdata, 4)

    repeat i from %01 to %11
      if cmax == i
        ser.Position (0, i + 1)
        ser.Char ("[")
        ser.Position (8, i + 1)
        ser.Str (string("] "))
      else
        ser.Position (0, i + 1)
        ser.Char (" ")
        ser.Position (8, i + 1)
        ser.Str (string("  "))

    time.MSleep (100)

PUB ToggleLED

  ser.NewLine
  ser.Str (string("Turning LED "))

  if _led_enabled
    _led_enabled := FALSE
    ser.Str (string("off", ser#NL))
    io.Low (LED)  'Turn off explicitly, just to be sure
  else
    ser.Str (string("on", ser#NL))
    _led_enabled := TRUE
  waitkey

PUB ToggleInts | tmp

  ser.NewLine
  ser.Str (string("Turning Interrupts "))
  tmp := rgb.IntsEnabled
  if tmp
    ser.Str (string("off", ser#NL))
    rgb.EnableInts (FALSE)
  else
    ser.Str (string("on", ser#NL))
    rgb.EnableInts (TRUE)
    rgb.SetIntThreshold ($0001, $00A0)
  waitkey

PUB TogglePower | tmp

  ser.NewLine
  ser.Str (string("Turning Power "))
  tmp := rgb.Powered
  if tmp
    ser.Str (string("off", ser#NL))
    rgb.Power (FALSE)
  else
    ser.Str (string("on", ser#NL))
    rgb.Power (TRUE)

  waitkey

PUB ToggleRGBC | tmp

  ser.NewLine
  ser.Str (string("Turning RGBC "))
  tmp := rgb.SensorEnabled
  if tmp
    ser.Str (string("off", ser#NL))
    rgb.EnableSensor (FALSE)
  else
    ser.Str (string("on", ser#NL))
    rgb.EnableSensor (TRUE)

  waitkey

PUB ToggleWait | tmp

  ser.NewLine
  ser.Str (string("Turning Wait timer "))
  tmp := rgb.WaitEnabled
  if tmp
    ser.Str (string("off", ser#NL))
    rgb.EnableWait (FALSE)

  else
    ser.Str (string("on", ser#NL))
    rgb.EnableWait (TRUE)

  waitkey

PUB ToggleWaitLong | tmp

  ser.NewLine
  ser.Str (string("Turning Long Waits "))
  tmp := rgb.WaitLongEnabled
  if tmp
    ser.Str (string("off", ser#NL))
    rgb.EnableWaitLong (FALSE)

  else
    ser.Str (string("on", ser#NL))
    rgb.EnableWaitLong (TRUE)

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

      "l", "L":
        _prev_state := _demo_state
        _demo_state := TOGGLE_LED

      "p", "P":
        _prev_state := _demo_state
        _demo_state := TOGGLE_POWER

      "q", "Q":
        _prev_state := _demo_state
        _demo_state := TOGGLE_WAITLONG

      "s", "S":
        _prev_state := _demo_state
        _demo_state := PRINT_RGBC

      "w", "W":
        _prev_state := _demo_state
        _demo_state := TOGGLE_WAIT

      OTHER   :
        if _demo_state == WAITING
          _demo_state := _prev_state
        else
          _prev_state := _demo_state
          _demo_state := DISP_HELP

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
  ser.Str (string("l, L:  Toggle LED Strobe", ser#NL))
  ser.Str (string("p, P:  Toggle sensor power", ser#NL))
  ser.Str (string("q, Q:  Toggle Long Waits", ser#NL))
  ser.Str (string("s, S:  Display RGBC sensor data", ser#NL))
  ser.Str (string("w, W:  Toggle Wait timer", ser#NL))

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
    time.MSleep (500)
    ser.Stop
    debug.LEDSlow (cfg#LED1)
  _max_cols := 1

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
