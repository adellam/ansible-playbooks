FROM ubuntu:14.04

ENV JAVA_HOME {{ java_home }}
ENV CATALINA_HOME {{ catalina_home }}
ENV GHN_HOME {{ smartgears_user_home }}

WORKDIR {{ smartgears_user_home }}
ADD {{ smartgears_url }} {{ smartgears_user_home }}
ADD smartgears_run.sh {{ smartgears_user_home }}

{% if patch_common_scope %}
  COPY common-scope-maps-patched.ja* {{ smartgears_user_home }}
{% endif %}

{% if patch_common_authorization %}
  COPY common-authorization-patched.ja* {{ smartgears_user_home }}
{% endif %}

RUN \
  #### install either the Oracle JDK or OpenJDK
  apt-get update && \
  apt-get install -y software-properties-common && \
  {% if java_jdk == 'java8-jdk' %}
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer && \
  {% elif java_jdk == 'openjdk-8' %}
    apt-add-repository -y ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk-headless && \
  {% endif %}

  apt-get update && apt-get install -y tomcat7 openssh-client openssh-server python wget && \
  ln -s /var/lib/tomcat7/webapps/ /usr/share/tomcat7/webapps && \
  sed -ie 's/^TOMCAT7_USER=tomcat7/TOMCAT7_USER={{ smartgears_user }}/' /etc/default/tomcat7 && \
  sed -ie 's/^TOMCAT7_GROUP=tomcat7/TOMCAT7_GROUP={{ smartgears_user }}/' /etc/default/tomcat7 && \

  #### set the default JDK for tomcat
  {% if java_jdk == 'java8-jdk' %}
    echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle/" >> /etc/default/tomcat7 && \
  {% elif java_jdk == 'openjdk-8' %}
    echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/" >> /etc/default/tomcat7 && \
  {% endif %}

  echo GHN_HOME={{ smartgears_user_home }} >> /etc/default/tomcat7 && \
  echo CATALINA_HOME={{ catalina_home }} >> /etc/default/tomcat7 && \
  echo CATALINA_OPTS=\"{{ catalina_opts }}\" >> /etc/default/tomcat7 && \
  ln -s /etc/init.d/tomcat7 /etc/init.d/tomcat-instance-9000 && \
  sed -i 's/8080/{{ tomcat_port }}/' /var/lib/tomcat7/conf/server.xml && \
  mkdir /var/run/sshd && \

  #### if an orchestrator ssh key is specified then add it to the authorized_keys
  {% if orchestrator_ssh_key is defined %}
    mkdir -p ~/.ssh/ && touch ~/.ssh/authorized_keys && \
    echo "{{ orchestrator_ssh_key }}" >> ~/.ssh/authorized_keys && \
    echo "{{ orchestrator_user }} ALL=(ALL) ALL" >> /etc/sudoers && \
  {% endif %}

  #### is this pem required?
  wget -O /usr/local/share/ca-certificates/infn-ca-2015.crt https://security.fi.infn.it/CA/mgt/INFNCA.pem && \
  tar xzvf smartgears-distribution-{{ smartgears_distribution_version }}.tar.gz

WORKDIR {{ smartgears_user_home }}/smartgears-distribution-{{ smartgears_distribution_version }}/
RUN \
  ./install -s tomcat

COPY logback.xml {{ smartgears_user_home }}/lib/

WORKDIR {{ smartgears_user_home }}

EXPOSE 22 8080
ENTRYPOINT ["{{ smartgears_user_home }}/smartgears_run.sh"]
