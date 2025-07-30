FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        rsyslog rsyslog-gnutls ca-certificates gettext-base && \
    rm -rf /var/lib/apt/lists/*

COPY rsyslog.conf.tmpl /etc/rsyslog.conf.tmpl
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 514/tcp 514/udp
HEALTHCHECK CMD pgrep rsyslogd >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
