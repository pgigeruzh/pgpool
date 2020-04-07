FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y pgpool2

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["pgpool", "-n"]
