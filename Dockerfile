# Stage 1: Build
FROM golang:1.21-alpine as builder

ARG REVISION

WORKDIR /podinfo

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -ldflags "-s -w \
    -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" \
    -a -o bin/podinfo cmd/podinfo/*

RUN CGO_ENABLED=0 go build -ldflags "-s -w \
    -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" \
    -a -o bin/podcli cmd/podcli/*

# Stage 2: Final Image
FROM alpine:3.18

ARG BUILD_DATE
ARG VERSION
ARG REVISION

LABEL maintainer="stefanprodan"

RUN addgroup -S app \
    && adduser -S -G app app \
    && apk --no-cache add \
    ca-certificates curl netcat-openbsd

WORKDIR /home/app

COPY --from=builder /podinfo/bin/podinfo .
COPY --from=builder /podinfo/bin/podcli /usr/local/bin/podcli
COPY --from=builder /podinfo/ui ./ui
RUN chown -R app:app ./

USER app

CMD ["./podinfo"]
