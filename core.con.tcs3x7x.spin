{
    --------------------------------------------
    Filename: core.con.tcs3x7x.spin
    Author: Jesse Burt
    Copyright (c) 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

' COMMAND REGISTER:
' 7     6     5     4     3     2     1     0
' CMD   TYPE        ADDR/SF

' CMD
  CMD           = %1  << 7

' TYPE
  TYPE_BYTE     = %00 << 5
  TYPE_BLOCK    = %01 << 5
  TYPE_SPECIAL  = %11 << 5


' ADDR/SF
  SF_CLR_INT_CLR= %00110

  ENABLE        = $00       'ENABLE; AIEN , PON BIT 0
  ATIME         = $01       '2'S COMP; 2.4MS TO 614MS
  WTIME         = $03       'WAIT TIME
  AILTL         = $04       'CLEAR INTERRUPT LOW THRESHOLD
  AILTH         = $05
  AIHTL         = $06       'CLEAR INTERRUPT HIGH THRESHOLD 
  AIHTH         = $07
  APERS         = $0C       'PERSISTENCE FILTER - BITS 3..0
  CONFIG        = $0D
  CONTROL       = $0F       'AGAIN BITS 1..0, 1X, 4X, 16X, 60X GAIN, 2'S COMP

  DEVID         = $12
  STATUS        = $13

  CDATAL        = $14       'CLEAR DATA
  CDATAH        = $15
  RDATAL        = $16       'RED DATA
  RDATAH        = $17
  GDATAL        = $18       'GREEN DATA
  GDATAH        = $19
  BDATAL        = $1A       'BLUE DATA
  BDATAH        = $1B

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
