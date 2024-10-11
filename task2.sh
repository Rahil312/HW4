#!/bin/bash
cd dataset1/
# Print files containing "sample" and at least 3 occurrences of "CSC510"
grep -rl "sample" file* | xargs grep -c "CSC510" | \
grep -E ":[3-9][0-9]*$" | \
sort -t: -k2,2nr | \
cut -d: -f1 | \
uniq | \
sed 's/file_/filtered_/' | \
xargs printf "%s\n"

