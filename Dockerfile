FROM golang:1.26.5-alpine AS builder

WORKDIR /src
COPY . .

RUN apk add --no-cache git && \
    go mod download && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o "serve-zip"

FROM alpine:3.23.2

WORKDIR /

COPY --from=builder "/src/serve-zip" "/"

ENTRYPOINT ["/serve-zip"]
EXPOSE 8080
