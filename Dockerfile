# Base build image
FROM golang:1.11-alpine AS build_base
 
# Install some dependencies needed to build the project
RUN apk add bash ca-certificates git gcc g++ libc-dev
WORKDIR /go/src/github.com/ory/hydra
 
# Force the go compiler to use modules
ENV GO111MODULE=on
  
# We want to populate the module cache based on the go.{mod,sum} files.
COPY go.mod .
COPY go.sum .
 
#This is the ‘magic’ step that will download all the dependencies that are specified in 
# the go.mod and go.sum file.
# Because of how the layer caching system works in Docker, the  go mod download 
# command will _ only_ be re-run when the go.mod or go.sum file change 
# (or when we add another docker instruction this line)
RUN go mod download
 
# This image builds the weavaite server
FROM build_base AS server_builder
# Here we copy the rest of the source code
COPY . .
# And compile the project
RUN GO111MODULE=on CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build
 
# To compile this image manually run:
#
# $ GO111MODULE=on GOOS=linux GOARCH=amd64 go build && docker build -t oryd/hydra:v1.0.0-rc.7_oryOS.10 . && rm hydra
FROM alpine:3.9 AS my-hydra

RUN apk add -U --no-cache ca-certificates

COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=server_builder /go/src/github.com/ory/hydra/hydra /usr/bin/hydra
COPY .releaser/LICENSE.txt /LICENSE.txt

ENTRYPOINT ["hydra"]
CMD ["serve", "all"]
