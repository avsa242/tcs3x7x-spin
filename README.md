# tcs3x7x-spin
---------------

This is a P8X32A/Propeller driver object for AMS's (formerly TAOS) TCS3x7x-series RGB color sensors.

## Salient Features

* I2C connection up to 400kHz
* Adjustable sensor gain
* Optional interrupts (set thresholds, set persistence filter)
* Power management through sensor's built-in wait timer
* Adjustable ADC integration time

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Limitations

* The Propeller doesn't have a dedicated interrupt line, so would be software-implemented. An additional core/cog would typically be devoted to this (the Demo object demonstrates this)

## TODO

* 
