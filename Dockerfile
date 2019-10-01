# bases are in registry.redhat.io
#FROM quay.io/jasonredhat/ubi7
FROM openshift/jenkins-slave-base-centos7
USER root
LABEL maintainer="Jason Dudash <jdudash@redhat.com>"
LABEL name="openshift-wetty-client" \
      architecture="x86_64" \
      io.k8s.display-name="oc tools via wetty running on RHEL7 UBI" \
      io.k8s.description="Provides oc cli tooling in a web browser" \
      io.openshift.tags="openshift,wetty,oc,ubi7"

ENV NODEJS_VERSION=8 \
    NODE_ENV=production \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH \
    WETTY_NUMBER_OF_USERS=60 \
    WETTY_USERNAME_PREFIX=user \
    WETTY_PASSWORD_PREFIX=password

RUN curl -sLo /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v3/clients/3.11.104/linux/oc.tar.gz && \
    tar -xzvf /tmp/oc.tar.gz -C /tmp/ && \
    mv /tmp/oc /usr/local/bin/ && \
    rm -rf /tmp/oc.tar.gz
RUN oc version

RUN yum -y install openssh-server sshpass
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
#ADD sshd_config /etc/ssh/sshd_config 
RUN systemctl enable sshd.service

RUN yum -y install java-1.8.0-openjdk-devel maven

RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN yum -y install nodejs make gcc*
RUN npm install npm@latest -g

# To modify default users, update the WETTY_* environment variables above
# and automate the OpenShift cluster oc login
RUN for ((i=1; i<=$WETTY_NUMBER_OF_USERS; i++)); do useradd -d /home/${WETTY_USERNAME_PREFIX}$i -m -s /bin/bash ${WETTY_USERNAME_PREFIX}$i && echo "${WETTY_USERNAME_PREFIX}$i:${WETTY_PASSWORD_PREFIX}$i" | chpasswd && echo "oc login -u \$(whoami) -p password\$(whoami | egrep -o '[[:digit:]]{1,}' | head -n1)" >> /home/${WETTY_USERNAME_PREFIX}$i/.bashrc; done

RUN npm i -g wetty.js --unsafe-perm=true --allow-root
ADD wetty.conf .
#RUN cp wetty.conf /etc/init

EXPOSE 8888
USER root
ENTRYPOINT ["wetty", "--port", "8888", "--base", "/"]

