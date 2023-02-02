FROM golang:1.20.0-alpine3.16 AS builder

WORKDIR /src
COPY . .

RUN apk add --no-cache git && \
    go mod download && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o "serve-zip"

FROM alpine:3.17.0

WORKDIR /

COPY --from=builder "/src/serve-zip" "/"

ENTRYPOINT ["/serve-zip"]
EXPOSE 8080
