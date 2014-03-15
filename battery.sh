#!/usr/bin/env bash

ioreg -n AppleSmartBattery -r | awk '$1~/Capacity/{c[$1]=$3} END{OFMT="%.2f%%"; max=c["\"MaxCapacity\""]; printf("%d", max>0? 100*c["\"CurrentCapacity\""]/max: "?")}'
