FROM golang:1.20-alpine AS build

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY cmd/ops-test-app ./cmd/ops-test-app
RUN CGO_ENABLED=0 GOOS=linux go build -o app ./cmd/ops-test-app

FROM alpine:3.18

WORKDIR /app

USER nobody:nobody
COPY --from=build /app/app .

ENV PORT=8080
EXPOSE $PORT

CMD ["./app"]
