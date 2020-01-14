FROM alpine

RUN apk add --no-cache tini iptables

COPY /script/* /script/
RUN mv /script/configure-firewall.sh /usr/local/bin && \
    chmod +x /usr/local/bin/configure-firewall.sh && \
    ln -s /usr/local/bin/configure-firewall.sh /

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["configure-firewall.sh"]
