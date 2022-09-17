FROM golang:1.19.1

ADD main.go main.go

CMD go run main.go
