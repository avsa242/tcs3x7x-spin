{
    --------------------------------------------
    Filename: TCS3x7x-Demo.spin
    Author: Jesse Burt
    Description: Demo of the TCS3x7x driver
    Copyright (c) 2020
    Started: Jun 24, 2018
    Updated: Mar 24, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

    LED             = cfg#LED1
    SER_RX          = 31
    SER_TX          = 30
    SER_BAUD        = 115_200

    I2C_SCL         = 28
    I2C_SDA         = 29
    I2C_HZ          = 400_000

' I/O Pin connected to the (optional) on-board white LED and INT pin
    WHITE_LED_PIN   = 25
    INT_PIN         = 24

OBJ

    cfg   : "core.con.boardcfg.flip"
    ser   : "com.serial.terminal.ansi"
    time  : "time"
    rgb   : "sensor.color.tcs3x7x.i2c"
    io    : "io"

VAR

    byte _ser_cog, _rgb_cog
    byte _led_enabled

PUB Main | rgbc_data[2], rdata, gdata, bdata, cdata, cmax, i, int, thr, rrow, grow, brow, crow, range

    Setup

    rgb.ClearInt                                            ' Clear interrupts
    rgb.Gain(1)                                             ' 1, 4, 16, 60 (x)
    rgb.WaitTimer(FALSE)                                    ' On-chip timer - wait between measurements
    rgb.InterruptsEnabled (TRUE)                            ' TRUE, FALSE
    rgb.IntThreshold ($1000, $FFFF)                         ' low level, high level: 0..65535 each
    rgb.Persistence (60)                                    ' Num. consecutive cycles measurement must stay outside threshold to actually trigger an interrupt: 0..60 (see Persistence() in driver file)
    rgb.IntegrationTime (12_000)                            ' Sensor ADC integration time, in microseconds (2_400..700_000, multiples of 2_400)
    rgb.Powered(TRUE)                                       ' Power on sensor

    _led_enabled := TRUE

    range := 256
    crow := 4
    rrow := crow + 1
    grow := crow + 2
    brow := crow + 3
    ser.clear
    ser.position (0, 0)
    ser.str (string("Gain: "))
    ser.dec (rgb.Gain(-2))
    ser.str (string("x "))

    ser.str (string("Interrups: "))
    int := ||rgb.InterruptsEnabled(-2)
    ser.str (lookupz(int: string("Off"), string("On ")))

    ser.str (string("  Threshold: "))
    thr := rgb.IntThreshold(-2, -2)
    ser.hex (thr & $FFFF, 4)
    ser.str (string(" .. "))
    ser.hex ((thr >> 16) & $FFFF, 4)

    ser.position (0, crow)
    ser.str (string("Clear"))
    ser.position (0, rrow)
    ser.str (string("Red"))
    ser.position (0, grow)
    ser.str (string("Green"))
    ser.position (0, brow)
    ser.str (string("Blue"))

    ser.HideCursor

    repeat
        rgb.OpMode(rgb#MEASURE)                             ' Turn on the sensor ADCs
        if _led_enabled                                     ' Flash the white LED, if enabled
            io.High (WHITE_LED_PIN)
        repeat until rgb.DataValid                          ' When the chip has taken a set of measurements,
        rgb.RGBCData (@rgbc_data)                           '   read the data
        rgb.OpMode(rgb#PAUSE)                               ' Turn off the sensor ADCs
        if _led_enabled
            io.Low (WHITE_LED_PIN)

        cdata := ((rgbc_data.byte[1] << 8) | rgbc_data.byte[0]) & $FFFF
        rdata := ((rgbc_data.byte[3] << 8) | rgbc_data.byte[2]) & $FFFF
        gdata := ((rgbc_data.byte[5] << 8) | rgbc_data.byte[4]) & $FFFF
        bdata := ((rgbc_data.byte[7] << 8) | rgbc_data.byte[6]) & $FFFF

        ser.color(ser#FG_WHITE, ser#BG_BLACK)               ' Draw bargraphs for each color channel
        Graph (6, crow, cdata, 0, range, 70, TRUE, thr & $FFFF, (thr >> 16) & $FFFF)

        ser.color(ser#FG_RED, ser#BG_BLACK)
        Graph (6, rrow, rdata, 0, range, 70, FALSE, 0, 0)

        ser.color(ser#FG_GREEN, ser#BG_BLACK)
        Graph (6, grow, gdata, 0, range, 70, FALSE, 0, 0)

        ser.color(ser#FG_BLUE, ser#BG_BLACK)
        Graph (6, brow, bdata, 0, range, 70, FALSE, 0, 0)

        ser.color(ser#FG_WHITE, ser#BG_BLACK)

        ser.str(string(ser#CR, ser#LF, "Interrupt: "))                         ' Indicate if an interrupt has been triggered
        if rgb.Interrupt
            ser.str(string("Yes"))
        else
            ser.str(string("No "))

PUB Graph(graphx, graphy, in, inmin, inmax, outrange, grads, exc_lo, exc_hi) | output, scale, inrange, bar 'XXX optimize... too slow!
' Calculate
    scale := 10
    inrange := inmax-inmin
    output := ((((in << scale)-(inmin << scale)) / inrange) * outrange) >> scale

' Graduations
    if grads
        exc_lo := ((((exc_lo << scale)-(inmin << scale)) / inrange) * outrange) >> scale
        exc_hi := ((((exc_hi << scale)-(inmin << scale)) / inrange) * outrange) >> scale
        repeat bar from 0 to outrange
            case bar
                exc_lo:
                    ser.position (graphx + bar, graphy-1)
                    ser.char ("L")
                exc_hi:
                    ser.position (graphx + bar, graphy-1)
                    ser.char ("H")
                0..outrange:
                    if bar//5 == 0
                        ser.position (graphx + bar, graphy-1)
                        ser.char ("|")
' Graph
    repeat bar from 0 to outrange
        ser.position (graphx + bar, graphy)
        if bar =< output
            ser.char ("#")
        else
            ser.char (" ")

PUB Setup

    io.Output (WHITE_LED_PIN)
    io.Low (WHITE_LED_PIN)

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.clear
    ser.str (string("Serial terminal started", ser#CR, ser#LF))
    if _rgb_cog := rgb.Startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.str (string("TCS3X7X driver started", ser#CR, ser#LF))
    else
        ser.str (string("TCS3X7X driver failed to start - halting", ser#CR, ser#LF))
        rgb.Stop
        time.MSleep (500)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

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
