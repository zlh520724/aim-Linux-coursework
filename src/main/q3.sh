#!/bin/bash
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output/sentry_ws/scripts"
mkdir -p "$output/sentry_ws/config"
mkdir -p "$output/sentry_ws/backup"
mkdir -p "$output/sentry_ws/archive"

cp "$input/hello.sh" "$output/sentry_ws/scripts/hello.sh"
cp "$input/robot.conf" "$output/sentry_ws/config/robot.conf"
cp "$input/draft.conf" "$output/sentry_ws/config/draft.conf"

cp "$output/sentry_ws/config/robot.conf" "$output/sentry_ws/backup/robot.conf"

mv -f "$output/sentry_ws/config/draft.conf" "$output/sentry_ws/archive/draft.conf.old"

rm -rf "$output/sentry_ws/tmp"

chmod 750 "$output/sentry_ws/scripts/hello.sh"
chmod 640 "$output/sentry_ws/config/robot.conf"

"$output/sentry_ws/scripts/hello.sh" > "$output/hello-output.txt"
