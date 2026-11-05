FROM ubuntu:latest AS builder
RUN useradd -u 10001 scratchuser
ARG GOVER=1.27.1
ARG TARGETARCH

RUN apt update && apt install curl -y
RUN curl -L https://golang.org/dl/go${GOVER}.linux-${TARGETARCH}.tar.gz \
    --output go${GOVER}.linux-${TARGETARCH}.tar.gz && \
    tar -xzf go${GOVER}.linux-${TARGETARCH}.tar.gz -C /usr/bin && \
    chmod a+x /usr/bin/go/bin && \
    rm go${GOVER}.linux-${TARGETARCH}.tar.gz

WORKDIR /app

COPY main.go go.mod /app/
RUN CGO_ENABLED=0 /usr/bin/go/bin/go build -o webapp

# Run the app using the scratch image to reduce attack surface area
FROM scratch
# Copy the webapp and SSL certificates
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /app/webapp /webapp
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# Run the app as a non-privilledged user
USER scratchuser
EXPOSE 8080
ENTRYPOINT [ "/webapp" ]
