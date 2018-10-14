{
    --------------------------------------------
    Filename: core.con.tcs3x7x.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Jun 24, 2018
    Updated: Oct 14, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

  I2C_MAX_FREQ      = 400_000
  SLAVE_ADDR        = $29 << 1

' COMMAND REGISTER:
' MSB
' 7     6     5     4     3     2     1     0
' C.....T.....T.....A.....A.....A.....A.....A
' |     |_____|     |_______________________|
' CMD   TYPE        ADDR (REG)/SF

' CMD - bit 7
  CMD               = %1  << 7

' TYPE - bits 6..5
  TYPE_BYTE         = %00 << 5  'Don't auto-increment address pointer - use for reading single register
  TYPE_BLOCK        = %01 << 5  'Auto-increment address pointer - use for reading multiple sequential registers
  TYPE_SPECIAL      = %11 << 5  'Special Function


' ADDR/SF - bits 4..0
  SF_CLR_INT_CLR    = %00110

  REG_ENABLE        = $00       'AIEN bit 4, WEN bit 3, AEN bit 1, PON BIT 0
  REG_ATIME         = $01       '2'S COMP; 2.4MS TO 614MS
  REG_WTIME         = $03       'WAIT TIME
  REG_AILTL         = $04       'CLEAR INTERRUPT LOW THRESHOLD
  REG_AILTH         = $05
  REG_AIHTL         = $06       'CLEAR INTERRUPT HIGH THRESHOLD
  REG_AIHTH         = $07
  REG_APERS         = $0C       'PERSISTENCE FILTER - BITS 3..0
  REG_CONFIG        = $0D
  REG_CONTROL       = $0F       'AGAIN BITS 1..0, 1X, 4X, 16X, 60X GAIN, 2'S COMP

  REG_DEVID         = $12
  REG_STATUS        = $13

  REG_CDATAL        = $14       'CLEAR DATA
  REG_CDATAH        = $15
  REG_RDATAL        = $16       'RED DATA
  REG_RDATAH        = $17
  REG_GDATAL        = $18       'GREEN DATA
  REG_GDATAH        = $19
  REG_BDATAL        = $1A       'BLUE DATA
  REG_BDATAH        = $1B

PUB null
''This is not a top-level object


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
