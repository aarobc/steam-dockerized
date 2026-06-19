FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o server main.go

FROM alpine:latest
# Install docker-cli-compose to run docker compose commands
RUN apk add --no-cache docker-cli docker-cli-compose
WORKDIR /app
COPY --from=builder /app/server .
# Copy index.html so it can be served
COPY index.html .
CMD ["./server"]
