#!/bin/sh
set -eu

runtime=${CONTAINER_RUNTIME:-docker}
image=${1:-container-port-forward:test}
container_name="container-port-forward-test-$$"

cleanup() {
    "$runtime" rm -f "$container_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

"$runtime" run --rm --entrypoint sh "$image" -c '
    command -v socat >/dev/null
    test "$PROTOCOL" = TCP
    test "$DESTINATION" = MISSING_DESTINATION_IP:59136
'

"$runtime" run -d --name "$container_name" \
    -e PROTOCOL=TCP \
    -e DESTINATION=127.0.0.1:9 \
    "$image" >/dev/null

test "$("$runtime" inspect --format "{{.State.Running}}" "$container_name")" = true