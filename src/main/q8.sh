#!/bin/bash
set -eu

input=${1:?需要输入目录}
output=${2:?需要输出目录}
action=${3:-repair}

source "$input/process.env"

# 判断进程是否仍在运行；僵尸进程视为已退出。
running() {
    local state
    if state=$(ps -p "$1" -o stat=); then
        case "$state" in
            ""|*Z*) return 1 ;;
            *) return 0 ;;
        esac
    fi
    return 1
}

# 发送普通终止信号，并有界等待退出。
stop_process() {
    local pid=$1
    local i

    if running "$pid"; then
        kill -TERM "$pid"
    fi

    for i in {1..30}; do
        if ! running "$pid"; then
            return 0
        fi
        sleep 0.1
    done

    printf '进程未及时退出：%s\n' "$pid" >&2
    return 1
}

case "$action" in
    repair)
        # 一次查询目标进程，获取真实信息。
        details=$(ps -ww -p "$TARGET_PID" \
            -o pid= -o user= -o stat= -o args=)

        read -r pid owner state command <<< "$details"

        case "$state" in
            R*|S*) ;;
            *) exit 1 ;;
        esac

        case "$command" in
            *"$TARGET_TOKEN"*) ;;
            *) exit 1 ;;
        esac

        printf 'pid=%s\nuser=%s\nstate=%s\ncommand=%s\n' \
            "$pid" "$owner" "$state" "$command" \
            > "$output/process.txt"

        # 等待日志中至少有两条 TICK。
        sampled=no
        for i in {1..30}; do
            if grep -c 'TICK' "$WORKER_LOG" \
                > "$output/tick-count.tmp"; then
                ticks=$(cat "$output/tick-count.tmp")
                if [ "$ticks" -ge 2 ]; then
                    sampled=yes
                    break
                fi
            fi
            sleep 0.1
        done

        rm -f "$output/tick-count.tmp"
        [ "$sampled" = yes ]
        cat "$WORKER_LOG" > "$output/collector-sample.log"

        stop_process "$TARGET_PID"
        stop_process "$SERVICE_PID"

        printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' \
            "$TARGET_PORT" > "$output/server.conf"

        bash "$START_TOOL" \
            "$output/server.conf" "$output/service"

        # 有界等待 HTTP 服务就绪。
        ready=no
        for i in {1..20}; do
            if code=$(curl --silent --show-error \
                --connect-timeout 0.2 --max-time 0.5 \
                --output "$output/http-body.txt" \
                --write-out '%{http_code}' \
                "http://127.0.0.1:$TARGET_PORT/status" \
                2> "$output/curl-error.tmp"); then

                if [ "$code" = 200 ] &&
                    [ "$(cat "$output/http-body.txt")" = "SENTRY READY" ]; then
                    printf '%s\n' "$code" > "$output/http-status.txt"
                    ready=yes
                    break
                fi
            fi
            sleep 0.1
        done

        rm -f "$output/curl-error.tmp"
        [ "$ready" = yes ]
        ;;

    cleanup)
        pid=$(cat "$output/service/pid")
        stop_process "$pid"

        released=no
        for i in {1..30}; do
            listeners=$(ss -H -ltn "sport = :$TARGET_PORT")
            if [ -z "$listeners" ]; then
                released=yes
                break
            fi
            sleep 0.1
        done

        [ "$released" = yes ]
        ;;

    *)
        printf '未知动作：%s\n' "$action" >&2
        exit 1
        ;;
esac
