#!/bin/bash
set -eu

input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output/sentry_ws/scripts"
mkdir -p "$output/sentry_ws/config"
mkdir -p "$output/sentry_ws/logs"
mkdir -p "$output/sentry_ws/tmp"

> "$output/sentry_ws/logs/.keep"
> "$output/sentry_ws/tmp/scratch.txt"

cat > "$output/sentry_ws/scripts/hello.sh" <<'EOF'
#!/bin/bash
echo "Hello, AIM Linux!"
EOF

cat > "$output/sentry_ws/config/robot.conf" <<'EOF'
robot=sentry
mode=training
log_level=INFO
EOF
