#!/bin/sh
set -eu

runtime=${CONTAINER_RUNTIME:-docker}
image=${1:-container-port-forward:test}
network_name="container-port-forward-test-$$"
tcp_backend="${network_name}-tcp-backend"
tcp_forwarder="${network_name}-tcp-forwarder"
udp_backend="${network_name}-udp-backend"
udp_forwarder="${network_name}-udp-forwarder"

cleanup() {
    "$runtime" rm -f \
        "$tcp_backend" "$tcp_forwarder" \
        "$udp_backend" "$udp_forwarder" >/dev/null 2>&1 || true
    "$runtime" network rm "$network_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

"$runtime" run --rm --entrypoint sh "$image" -c '
    command -v socat >/dev/null
    test "$PROTOCOL" = TCP
    test "$DESTINATION" = MISSING_DESTINATION_IP:59136
'

"$runtime" network create "$network_name" >/dev/null

"$runtime" run -d --name "$tcp_backend" --network "$network_name" \
    --entrypoint socat "$image" \
    TCP-LISTEN:9000,reuseaddr,fork EXEC:cat >/dev/null

"$runtime" run -d --name "$tcp_forwarder" --network "$network_name" \
    -e PROTOCOL=TCP \
    -e DESTINATION="${tcp_backend}:9000" \
    "$image" >/dev/null

"$runtime" run -d --name "$udp_backend" --network "$network_name" \
    --entrypoint socat "$image" \
    UDP-RECVFROM:9000,reuseaddr,fork EXEC:cat >/dev/null

"$runtime" run -d --name "$udp_forwarder" --network "$network_name" \
    -e PROTOCOL=UDP \
    -e DESTINATION="${udp_backend}:9000" \
    "$image" >/dev/null

assert_forwarded() {
    protocol=$1
    forwarder=$2
    payload=$3
    attempts=0

    while [ "$attempts" -lt 10 ]; do
        actual=$("$runtime" run --rm --network "$network_name" \
            --entrypoint sh "$image" -c \
            'printf %s "$1" | socat -T 1 - "$2:$3:8888"' \
            sh "$payload" "$protocol" "$forwarder" 2>/dev/null || true)

        if [ "$actual" = "$payload" ]; then
            return
        fi

        attempts=$((attempts + 1))
    done

    printf 'Expected %s payload "%s", got "%s"\n' \
        "$protocol" "$payload" "$actual" >&2
    exit 1
}

assert_forwarded TCP "$tcp_forwarder" tcp-proxy-works
assert_forwarded UDP "$udp_forwarder" udp-proxy-works
