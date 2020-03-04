# tcs3x7x-spin
--------------

This is a P8X32A/Propeller 1, P2X8C4M64P/Propeller 2 driver object for AMS's (formerly TAOS) TCS3x7x-series RGB color sensors.

## Salient Features

* I2C connection at up to 400kHz
* Adjustable sensor gain
* Optional interrupts (set thresholds, set persistence filter)
* Power management through sensor's built-in wait timer
* Adjustable ADC integration time

## Requirements

* P1: 1 extra core/cog for the PASM I2C driver
* P2: N/A

## Compiler compatibility

- [x] P1/SPIN1: OpenSpin (tested with 1.00.81)
- [x] P2/SPIN2: FastSpin (tested with 4.0.3-beta)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO
- [ ] Improve the Wait timer API
