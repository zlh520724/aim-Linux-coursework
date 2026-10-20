#!/bin/bash
set -eu

input=${1:?需要输入目录}
output=${2:?需要输出目录}


cd "$input/handover"
pwd > "$output/location.txt"
cat .robot-id > "$output/robot-id.txt"
cat "$input/notes/welcome.txt" > "$output/welcome.txt"
