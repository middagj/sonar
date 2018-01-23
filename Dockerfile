FROM sonarqube:6.7.1-alpine
RUN apk update && apk add bash unzip

RUN apk add --update curl && \
    rm -rf /var/cache/apk/*

ADD ./plugins /tmp/plugins
RUN chmod +x /tmp/plugins/install-plugins.sh
RUN ls /tmp/plugins -l
RUN /tmp/plugins/install-plugins.sh

WORKDIR /opt/sonarqube
COPY ./start-with-profile.sh .
RUN chmod +x start-with-profile.sh

ADD ./rules /tmp/rules

CMD ["./start-with-profile.sh"]