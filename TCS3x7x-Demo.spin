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

OBJ

  cfg   : "core.con.client.flip"
  ser   : "com.serial.terminal"
  time  : "time"
  rgb   : "sensor.color.tcs3x7x"
  debug : "debug"
  io    : "io"
  
VAR


PUB Main

  Setup
  ser.Str (string("Present? "))
  if rgb.Ping == 0
    ser.Str (string("Yes", ser#NL))
  else
    ser.Str (string("No", ser#NL))
  ser.NewLine
  
  ser.Str (string("DEVICE = "))
  ser.Hex (rgb.GetPartID, 8)
  ser.NewLine

  ser.Str (string("STATUS = "))
  ser.Hex (rgb.GetStatus, 8)
  ser.NewLine
  debug.LEDFast (26)

PUB Setup

  io.Output (LED)
  io.Low (LED)

  repeat until ser.Start (115_200)
  ser.Clear
  ser.Str (string("Serial terminal started", ser#NL))
  if rgb.Start'rgb.Startx (SCL, SDA, I2C_HZ)
    ser.Str (string("tcs3x7x object started", ser#NL))
  else
    ser.Str (string("tcs3x7x object failed to start", ser#NL))
    ser.Stop
    debug.LEDSlow (26)

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
