# The contents of this file are subject to the license and copyright
# detailed in the LICENSE and NOTICE files at the root of the source

#####################
# build environment #
#####################
FROM maven:3.5.0-jdk-8

RUN apt-get update && apt-get install -y \
    figlet \
    git \
    postgresql-client \
    postgresql-contrib \
    rsync

ENV DSPACE_HOME=/dspace
COPY dspace/ ${DSPACE_HOME}
WORKDIR ${DSPACE_HOME}

ENV MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Djava.awt.headless=true"
ENV MAVEN_CLI_OPTS: "--batch-mode --errors --fail-at-end --show-version -DinstallAtEnd=true -DdeployAtEnd=true"

RUN mvn $MAVEN_CLI_OPTS package > /dev/null

RUN figlet "Dspace CRIS" | tee /banner

#######################
# runtime environment #
#######################
FROM tomcat:8.5.20-jre8

RUN apt-get update && apt-get install -y \
    ant \
    postgresql-client \
    postgresql-contrib


ENV DSPACE_HOME=/dspace
ENV PATH=$CATALINA_HOME/bin:${DSPACE_HOME}/bin:$PATH \
    DSPACE_CFG=/${DSPACE_HOME}/config/dspace.cfg

COPY --from=0 ${DSPACE_HOME}/dspace/target/dspace-installer ${DSPACE_HOME}-inst

WORKDIR ${DSPACE_HOME}-inst
RUN ant init_installation init_configs install_code copy_webapps \
    && rm -fr "$CATALINA_HOME/webapps" && mv -f ${DSPACE_HOME}/webapps "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ $CATALINA_HOME/webapps/rest/WEB-INF/web.xml

#RUN useradd -m dspace \
#    && chown -R dspace ${DSPACE_HOME}
#USER dspace

# COPY start scripts
COPY ./fs /

COPY --from=0 /banner /root/.banner
# Build info
RUN . /etc/os-release; echo "$PRETTY_NAME (`uname -rsv`)" >> /root/.built && \
echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
echo "- with Tomcat $TOMCAT_VERSION"  >> /root/.built

WORKDIR ${DSPACE_HOME}
EXPOSE 8080
ENTRYPOINT ["wait-for-postgres.sh", "postgres"]
CMD ["start-dspace"]
