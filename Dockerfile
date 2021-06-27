# Multi-stage Build: Stage 1—golang and Certificates
FROM golang:alpine AS build
RUN apk add --no-cache ca-certificates

WORKDIR /build

# Grab the necessary go modules for the build
COPY go.mod .
COPY go.sum .
RUN go mod download

# Copy over the source
COPY . .

# Build a statically linked Go executable
ENV CGO_ENABLED=0

# To build this properly have to build from the cmd/cloud-dyndns-client directory
RUN cd cmd/cloud-dyndns-client \
    && go build -o main

WORKDIR /dist

RUN cp /build/cmd/cloud-dyndns-client/main .

# Multi-stage Build: Stage 2—Grab only the Go executable and the certificates
FROM scratch

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /dist/main /cloud-dyndns-client

# Link container to Package Repo
LABEL org.opencontainers.image.source=https://github.com/jdries3/cloud-dyndns-client

# Define the health check address for /_status/healthz
EXPOSE 8080

# Invoke Google Cloud DNS Dynamic DNS client
ENTRYPOINT ["/cloud-dyndns-client"]
