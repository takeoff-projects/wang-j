FROM golang:1.17.0-alpine3.13
RUN mkdir /app
ADD ./go/src/cr /app
WORKDIR /app
RUN go build -o main .
CMD ["/app/main"]