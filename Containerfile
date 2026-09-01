FROM alpine:3.24


RUN apk add --no-cache socat

# Defaults — override with environment variables at runtime
ENV PROTOCOL=TCP
ENV DESTINATION=MISSING_DESTINATION_IP:59136


ENTRYPOINT ["sh", "-c", "socat -t 28 ${PROTOCOL}-LISTEN:8888,fork ${PROTOCOL}:${DESTINATION}"]