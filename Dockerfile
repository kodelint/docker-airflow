# VERSION 1.10.2
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.6-slim
LABEL maintainer="Puckel_"

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.1
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_GPL_UNIDECODE yes

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install -U pip==19.0.1 setuptools==40.7.0 wheel==0.32.3 \
    && pip install pytz==2018.9  \
    && pip install pyOpenSSL==19.0.0 \
    && pip install ndg-httpsclient==0.5.1 \
    && pip install pyasn1==0.4.5 \
    && pip install psycopg2==2.7.7 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis>=2.10.5' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi 

# Add this back if you need to 
    # && apt-get purge --auto-remove -yqq $buildDeps \
    # && apt-get autoremove -yqq --purge \
    # && apt-get clean \
    # && rm -rf \
    #     /var/lib/apt/lists/* \
    #     /tmp/* \
    #     /var/tmp/* \
    #     /usr/share/man \
    #     /usr/share/doc \
    #     /usr/share/doc-base

RUN  curl -L -o /usr/local/bin/kubectl \
                https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubectl \
        &&  chmod +x /usr/local/bin/kubectl
RUN mkdir -p ${AIRFLOW_HOME}/.kube/ 
COPY config/kube.config ${AIRFLOW_HOME}/.kube/config
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg
COPY config/sparky-aws.yaml ${AIRFLOW_HOME}/sparky-aws.yaml
COPY config/sparky-az.yaml ${AIRFLOW_HOME}/sparky-az.yaml
COPY script/entrypoint.sh /entrypoint.sh
COPY script/sparky-ubuntu /usr/local/bin/sparky
COPY dags/* /usr/local/airflow/dags/

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint
