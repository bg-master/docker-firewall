FROM alpine

RUN apk add --no-cache tini iptables

ADD configure-firewall.sh /bin

ENV FIREWALL_CHAIN "DOCKER-FIREWALL"
ENV FIREWALL_OPEN_TCP_PORTS "22"
ENV FIREWALL_OPEN_UDP_PORTS ""
ENV FIREWALL_ACCEPT_ALL_FROM ""

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/bin/configure-firewall.sh"]
