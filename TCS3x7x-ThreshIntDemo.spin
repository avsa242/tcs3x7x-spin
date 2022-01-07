{
    --------------------------------------------
    Filename: TCS3x7x-ThreshIntDemo.spin
    Author: Jesse Burt
    Description: Demo of the TCS3x7x driver
        Threshold interrupt functionality
    Copyright (c) 2022
    Started: Jan 6, 2022
    Updated: Jan 6, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED1            = cfg#LED1
    SER_BAUD        = 115_200

    I2C_SCL         = 28
    I2C_SDA         = 29
    I2C_HZ          = 400_000

    INT1            = 24

' I/O Pin connected to the (optional) on-board white LED
    WH_LED          = 25
' --

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    rgb : "sensor.color.tcs3x7x.i2c"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB Main{}

    outa[WH_LED] := 0
    dira[WH_LED] := 1
    setup{}
    rgb.preset_active{}                         ' default settings, but enable
                                                '   sensor power

    rgb.intclear{}                              ' clear potential false int
    rgb.intsenabled(true)
    rgb.intthresh(0, 15)                        ' (low, high): 0..65535
    rgb.persistence(10)                         ' 0..3, 5..60 (in steps of 5)
    ' Wait for the sensor to read less than the low threshold or greater than
    '   the high threshold. Persistence() sets the umber of measurement cycles
    '   the readings must be outside of the thresholds in order to assert an
    '   interrupt (to reduce false positives)
    ' NOTE: The interrupt applies only to the _clear_ color channel
    ' NOTE: The interrupt is active low, and open drain, so requires a pullup
    '   resistor
    repeat
        if _intflag
            ser.position(0, 8)
            ser.strln(string("interrupt - press any key to clear"))
            ser.charin{}
            rgb.intclear{}
            ser.position(0, 8)
            ser.clearline{}

        ser.position(0, 3)
        ser.printf1(string("Clear: %x\n"), rgb.cleardata{})
        ser.printf1(string("Red:   %x\n"), rgb.reddata{})
        ser.printf1(string("Green: %x\n"), rgb.greendata{})
        ser.printf1(string("Blue:  %x\n"), rgb.bluedata{})

PRI ISR{}
' Interrupt service routine
    dira[INT1] := 0                             ' INT1 as input
    repeat
        waitpne(|< INT1, |< INT1, 0)            ' wait for INT1 (active low)
        _intflag := 1                           '   set flag
        waitpeq(|< INT1, |< INT1, 0)            ' now wait for it to clear
        _intflag := 0                           '   clear flag


PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if rgb.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("TCS3X7X driver started"))
    else
        ser.strln(string("TCS3X7X driver failed to start - halting"))
        repeat

    cognew(isr, @_isr_stack)                    ' start ISR in another core

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
