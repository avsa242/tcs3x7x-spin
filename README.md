# tcs3x7x-spin
--------------

This is a P8X32A/Propeller 1, P2X8C4M64P/Propeller 2 driver object for AMS's (formerly TAOS) TCS3x7x-series RGB color sensors.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Adjustable sensor gain
* Optional interrupts (set thresholds, set persistence filter)
* Power management through sensor's built-in wait timer
* Adjustable ADC integration time

## Requirements

P1/SPIN1:
* spin-standard-library
* P1: 1 extra core/cog for the PASM I2C engine

P2/SPIN2:
* p2-spin-standard-library

Optional:
* 3rd I/O pin for a white LED used to illuminate sample
* 4th I/O pin for reading interrupt pin state

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): OK, tested with 1.00.81
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.7-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.7-beta~~
* P2/SPIN2 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build

