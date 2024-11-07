FROM golang:1.23.3-alpine AS builder

WORKDIR /src
COPY . .

RUN apk add --no-cache git && \
    go mod download && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o "serve-zip"

FROM alpine:3.20.3

WORKDIR /

COPY --from=builder "/src/serve-zip" "/"

ENTRYPOINT ["/serve-zip"]
EXPOSE 8080
