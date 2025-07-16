FROM docker.io/golang:1.24-bookworm AS builder
ARG VERSION=dev
ENV GOPATH=/go
WORKDIR /go/src/headscale

RUN apt-get update \
  && apt-get install --no-install-recommends --yes less jq sqlite3 dnsutils ca-certificates \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean
RUN mkdir -p /var/run/headscale

COPY go.mod go.sum /go/src/headscale/
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags="-s -w" -trimpath ./cmd/headscale &&\
  cp headscale /tmp/headscale

##############
FROM gcr.io/distroless/static AS runner

COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /tmp/headscale /usr/local/bin/headscale

ENTRYPOINT ["/usr/local/bin/headscale"]

EXPOSE 8080/tcp
EXPOSE 9090/tcp

CMD ["serve"]
