# Puppetserver docker file
FROM registry.redhat.io/rhel7:latest

LABEL maintainer="Thomas Meeus <thomas.meeus@cegeka.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building Puppet Server images" \
      io.k8s.display-name="Openshift-puppetserver-image-builder" \
      io.openshift.expose-services="8140:https" \
      io.openshift.tags="openshift,docker,puppet,puppetserver,image,builder"


## Add the s2i scripts.
LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i
COPY ./s2i/bin/ /usr/libexec/s2i

## Install Puppetserver & create Puppet code directory

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet \
    && yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/ \
    && yum -y install puppetserver \
    && yum clean all -y \
    && mkdir -p /etc/puppetlabs/code \
    && mkdir -p /etc/puppetlabs/code/environments/prd/manifests \
    && touch /var/log/puppetlabs/puppetserver/masterhttp.log

## Copy all required config files
COPY ./s2i/config/puppetserver.sh /usr/local/bin/start-puppet-server
COPY ./s2i/config/ca.cfg /etc/puppetlabs/puppetserver/services.d/ca.cfg
COPY ./s2i/config/webserver.conf /etc/puppetlabs/puppetserver/conf.d/webserver.conf
COPY ./s2i/config/hiera.yaml /etc/puppetlabs/code/environments/prd/hiera.yaml
COPY ./s2i/config/site.pp /etc/puppetlabs/code/environments/prd/manifests/site.pp

## Set correct permissions
RUN chmod +x /usr/local/bin/start-puppet-server \
    && chgrp -R 0 /opt/puppetlabs \
    && chgrp -R 0 /etc/puppetlabs \
    && chmod -R 771 /etc/puppetlabs/puppet/ssl \
    && chmod -R 775 /etc/puppetlabs/code \
    && chgrp -R 0 /var/log/puppetlabs \
    && chmod 750 /var/log/puppetlabs/puppetserver \
    && chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log

## Copy over /etc/puppetlabs/code/ for the next builds
ONBUILD COPY /tmp/src/ /etc/puppetlabs/code/

USER 1001

EXPOSE 8140

CMD ["/usr/libexec/s2i/usage"]
