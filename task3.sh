#!/bin/bash
gawk -F, '$3 == 2 && $13 ~ /S/ {print $0}' titanic.csv | sed 's/female/F/g; s/male/M/g' | tee /dev/tty | gawk -F, '$7 != "" { sum += $7; count++ } END {print "Average Age ", sum/count}'
