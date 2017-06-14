# **Greenhouse IoT 0.1** #

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/nodemcu/nodemcu-firmware/blob/master/LICENSE)

This is the firmware for a greenhouse controler based on
[NodeMCU](https://github.com/nodemcu/nodemcu-firmware/).

It supports 2 GPIO outputs as timers, one meant for a greenery table and
another for perennials. The greenery one fires at every 15 mins, 15 mins
on and 15 mins off. The perennials one is slower, 15mins at every 2
hours.

It will also monitor ambient temperature and huminity via a DHT11 sensor
and the greenery solution temperature via a ds18b20. This data and also
pumps status is then published to a MQTT server.

