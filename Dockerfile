FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o api-service main.go

FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/api-service .

EXPOSE 8080

CMD ["./api-service"]