# Multi-stage build for smaller final image
FROM golang:1.21-alpine AS builder

WORKDIR /go/src/github.com/stefanprodan/podinfo

# Cache dependencies and build artifacts
COPY go.mod go.sum ./
RUN go mod download
RUN CGO_ENABLED=0 go build -o cmd/podinfo/podinfo -ldflags "-s -w -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}"

# Separate build stage for the cli tool (optional if rarely used)
RUN CGO_ENABLED=0 go build -o cmd/podcli/podcli -ldflags "-s -w -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}"

# Build final Alpine image
FROM alpine:3.18

ARG BUILD_DATE
ARG VERSION
ARG REVISION

LABEL maintainer="stefanprodan"

# Pre-built dependencies
RUN apk --no-cache add ca-certificates curl netcat-openbsd

# Copy cached binaries from builder stage
COPY --from=builder /go/src/github.com/stefanprodan/podinfo/cmd/podinfo/podinfo ./bin/podinfo
COPY --from=builder /go/src/github.com/stefanprodan/podinfo/cmd/podcli/podcli /usr/local/bin/podcli

# Copy application files (not cached)
COPY --from=builder /go/src/github.com/stefanprodan/podinfo/ui ./ui

# Set user and permissions
RUN chown -R app:app ./
USER app

# Run podinfo executable
CMD ["./bin/podinfo"]

