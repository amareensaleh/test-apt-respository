
FROM debian:bullseye

RUN apt-get update
RUN apt-get install -y dpkg-dev
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /repo

ENTRYPOINT ["/entrypoint.sh"]