# container-port-forward

Port forwarding using just a container. It runs
[`socat`](http://www.dest-unreach.org/socat/) in a small Alpine image to forward
**UDP** or **TCP** traffic to any reachable `host:port`.

This is useful when you don't want to deal with `ip route` and you want your
configuration to live alongside your other containers. It also brings the
possibility of keeping port forwarding in version control, just like the rest of
your compose configuration.

## Configuration

Override these environment variables:

| Variable      | Default               | Description                                  |
| ------------- | --------------------- | -------------------------------------------- |
| `PROTOCOL`    | `UDP`                 | Protocol to forward: `UDP` or `TCP`.         |
| `DESTINATION` | `otherserverip:51820` | Target as `host:port` to forward traffic to. |

The container always listens on port `8888`. Map it to any host port via the
`ports` mapping.

## Usage

### Compose

See [compose.yml](compose.yml):

```yaml
services:
  socat_raspi:
    build: .
    container_name: socat_raspi
    restart: unless-stopped
    environment:
      DESTINATION: "raspi:51820"
    ports:
      - "51801:8888/udp"
```

Host UDP port `51801` now forwards to `raspi:51820`.

For TCP, add `PROTOCOL: "TCP"` and use `/tcp` in the port mapping.

### Command line

You can run this with Docker or with [Podman](https://podman.io/). (just replace `podman` with `docker`)

```sh


podman run -d --name socat_raspi \
  -e DESTINATION=otherserverip:51820 \
  -p 51801:8888/udp \
  trisky/container-port-forward
```

For TCP, add `-e PROTOCOL=TCP` and use `/tcp` in the port mapping.

## Notes

- The `host` in `DESTINATION` must be resolvable from inside the container.
- Match the protocol in the `ports` mapping (`/udp` or `/tcp`) with `PROTOCOL`.
