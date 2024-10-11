#!/bin/bash

gawk -F',' '($3 == "2" && $13 ~ /S/) { print $0 }' "titanic.csv" | sed 's/female/F/; s/male/M/' > "titanic_with_filled_data.csv"

gawk -F',' '
BEGIN {
    total_age = 0;  
    passenger_count = 0; 
    count_temp=0
}
{
    if ($7 > 0) {
        total_age += $7; 
        passenger_count++;   
    }
}
END { average_age = (passenger_count > 0) ? total_age / passenger_count : 0;print "Average age of these passengers:", average_age;
}' "titanic_with_filled_data.csv"



