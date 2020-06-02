FROM ubuntu:18.04 AS base

ARG MAVEN_OPTS
ENV CANTALOUPE_VERSION="4.1.5"

EXPOSE 8080

# Update packages and install tools
# net-tools is added below to have netstat available for debugging
RUN apt update -y && \
    apt install -y --no-install-recommends \
      wget unzip curl net-tools \
      graphicsmagick imagemagick ffmpeg python \
      maven default-jre \
      stunnel4
RUN rm -rf /var/lib/apt/lists/*

# Run non privileged
RUN adduser --system datapunt

WORKDIR /tmp

RUN echo 'rebuilding'
# Get and unpack Cantaloupe release archive
RUN wget -O cantaloupe-git.zip https://github.com/cantaloupe-project/cantaloupe/archive/v${CANTALOUPE_VERSION}.zip
RUN unzip cantaloupe-git.zip

# Add mirrors for maven central since they were offline
# Inspired by https://github.com/geosolutions-it/imageio-ext/issues/214#issuecomment-616111007
RUN mkdir ~/.m2 && cp /etc/maven/settings.xml ~/.m2/settings.xml && \
    MIRRORS="\n    <mirror>\n      <id>central<\/id>\n      <name>central<\/name>\n      <url>https:\/\/repo1.maven.org\/maven2<\/url>\n      <mirrorOf>central.maven.org<\/mirrorOf>\n    <\/mirror>\n    <mirror>\n      <id>osgeo-release<\/id>\n      <name>OSGeo Repository<\/name>\n      <url>https:\/\/repo.osgeo.org\/repository\/release\/<\/url>\n      <mirrorOf>osgeo<\/mirrorOf>\n    <\/mirror>\n    <mirror>\n      <id>geoserver-releases<\/id>\n      <name>Boundless Repository<\/name>\n      <url>https:\/\/repo.osgeo.org\/repository\/Geoserver-releases\/<\/url>\n      <mirrorOf>boundless<\/mirrorOf>\n    <\/mirror>\n" && \
    sed -i "s/<mirrors>/<mirrors>\n$MIRRORS/" ~/.m2/settings.xml

RUN cd /tmp/cantaloupe-${CANTALOUPE_VERSION} && mvn clean package -DskipTests
RUN cd /usr/local \
      && unzip /tmp/cantaloupe-${CANTALOUPE_VERSION}/target/cantaloupe-${CANTALOUPE_VERSION}.zip \
      && ln -s cantaloupe-${CANTALOUPE_VERSION} cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R datapunt /var/log/cantaloupe /var/cache/cantaloupe \
    && cp /usr/local/cantaloupe/deps/Linux-x86-64/lib/* /usr/lib/

RUN mkdir -p /var/log/gatekeeper \
    && chown -R datapunt /var/log/gatekeeper

RUN mkdir -p /app && chown datapunt /app

#
# Server
#
FROM base as server

# Cantaloupe
RUN mkdir -p /app/cantaloupe
ENV GEM_PATH="/app/cantaloupe:${GEM_PATH}"
COPY config/ /app/cantaloupe/
COPY example-images/ /images/
USER datapunt
WORKDIR /app/cantaloupe
COPY scripts ./scripts/
CMD "./scripts/start-services.sh"


#
# (unit) tester
#
FROM base AS tester

# Install jruby interpreter to mimick Cantaloupe script behavior
RUN apt update -y && \
    apt install -y jruby && \
    rm -rf /var/lib/apt/lists/*
RUN rm /usr/bin/ruby && ln -s /usr/bin/jruby /usr/bin/ruby

USER datapunt
WORKDIR /home/datapunt/
COPY config/ ./config/
COPY scripts ./scripts/
CMD ./scripts/run_test_local.sh
