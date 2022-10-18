FROM gcr.io/distroless/static-debian11

WORKDIR  /app

COPY ratelimit-example ./

EXPOSE 5000

CMD ["/app/ratelimit-example"]