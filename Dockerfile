FROM alpine:latest as gocd-agent-unzip

ARG UID=1000

RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/21.2.0-12498/generic/go-agent-21.2.0-12498.zip" > /tmp/go-agent-21.2.0-12498.zip

RUN unzip /tmp/go-agent-21.2.0-12498.zip -d /
RUN mv /go-agent-21.2.0 /go-agent && chown -R ${UID}:0 /go-agent && chmod -R g=u /go-agent

FROM debian:buster

LABEL gocd.version="21.2.0" \
  description="GoCD agent based on debian version 10" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="21.2.0-12498" \
  gocd.git.sha="1e23a06e496205ced5f1a8e83d9b209fc0a290cb"

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64 /usr/local/sbin/tini

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
# add user to root group for gocd to work on openshift
  groupadd -g 998 docker && \
  useradd -u ${UID} -g root -G docker -d /home/go -m go && \
  apt-get --allow-unauthenticated update && \
  apt-get install -y ca-certificates && \
  echo "deb [trusted=yes] https://download.docker.com/linux/debian buster stable" >> /etc/apt/sources.list.d/docker.list && \
  apt-get --allow-unauthenticated update && \
  apt-get install -y git subversion mercurial openssh-client bash unzip curl locales procps sysvinit-utils coreutils docker-ce-cli docker-compose gnupg2 pass && \
  apt-get autoclean && \
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
  curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.2%2B12/OpenJDK14U-jre_x64_linux_hotspot_14.0.2_12.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-agent /docker-entrypoint.d /go /godata

ADD docker-entrypoint.sh /


COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/

RUN chown -R go:root /docker-entrypoint.d /go /godata /docker-entrypoint.sh \
    && chmod -R g=u /docker-entrypoint.d /go /godata /docker-entrypoint.sh

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs

ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
