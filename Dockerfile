FROM ubuntu

LABEL org.label-schema.vcs-url="https://github.com/giovtorres/slurm-docker-cluster" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      org.label-schema.name="slurm-docker-cluster" \
      org.label-schema.description="Slurm Docker cluster on CentOS 7" \
      maintainer="Giovanni Torres"

ARG SLURM_VERSION=17.02.9
ARG SLURM_DOWNLOAD_MD5=6bd0b38e6bf08f3426a7dd1e663a2e3c
ARG SLURM_DOWNLOAD_URL=https://download.schedmd.com/slurm/slurm-"$SLURM_VERSION".tar.bz2

ARG GOSU_VERSION=1.10

RUN apt-get update \
    && apt-get -y install \
           wget \
           bzip2 \
           perl \
           build-essential \
           vim \
           git \
           make \
           munge \
	   libmunge2 \
	   libmunge-dev \
	   libmariadbd-dev \
	   libmariadb-client-lgpl-dev \
	   libpam-dev \
	   libnuma-dev \
	   libjson-c-dev \
	   h5utils \
	   openssl \
           python-dev \
           python-pip \
           python3 \
           python3-dev \
           python3-pip \
           mariadb-server \
           psmisc \
           bash-completion \
	   nscd \
	   openssh-server \
	   distcc \
    && apt clean \
    && rm -rf /var/cache/apt
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install nslcd

RUN pip3 install --upgrade pip
RUN pip install --upgrade pip
RUN pip install Cython nose \
    && pip3 install Cython nose

RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
#    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
#    && export GNUPGHOME="$(mktemp -d)" \
#    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
#    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
#    && rm -rf $GNUPGHOME /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN groupadd -r slurm --gid=995 && useradd -r -g slurm --uid=995 slurm

RUN set -x \
    && wget -O slurm.tar.bz2 "$SLURM_DOWNLOAD_URL" \
    && echo "$SLURM_DOWNLOAD_MD5" slurm.tar.bz2 | md5sum -c - \
    && mkdir -p /usr/local/src/slurm \
    && tar jxf slurm.tar.bz2 -C /usr/local/src/slurm --strip-components=1 \
    && rm slurm.tar.bz2 \
    && cd /usr/local/src/slurm \
    && ./configure --enable-debug --prefix=/usr --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin  --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurm.epilog.clean /etc/slurm/slurm.epilog.clean \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && cd \
    && rm -rf /usr/local/src/slurm \
    && mkdir -p /etc/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
	/var/run/sshd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data \
    && touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state \
    && chown -R slurm:slurm /var/*/slurm* \
    && /usr/sbin/create-munge-key \
    && mkdir -p /var/run/munge \
    && chown munge: /var/run/munge

# Install Nvidia CUDA
RUN wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.1.85-1_amd64.deb \
    && dpkg -i cuda-repo-ubuntu1604_9.1.85-1_amd64.deb \
    && apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
RUN apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install cuda \
    && rm cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
# End Nvidia CUDA

# Install Pytorch + tensorflow
RUN apt-get -y install cuda-command-line-tools-9.1 python3-dev python-dev python3-virtualenv python-virtualenv
RUN pip3 install http://download.pytorch.org/whl/cu91/torch-0.3.1-cp35-cp35m-linux_x86_64.whl \
    && pip3 install torchvision && pip install torchvision
RUN pip3 install numpy \
    && pip install numpy
RUN pip3 install tensorflow tensorflow-gpu \
    && pip install tensorflow tensorflow-gpu
# End Pytorch + tensorflow

COPY slurm.conf		/etc/slurm/slurm.conf
COPY slurmdbd.conf	/etc/slurm/slurmdbd.conf
COPY nslcd.conf		/etc/nslcd.conf
COPY nscd.conf		/etc/nscd.conf
COPY nsswitch.conf	/etc/nsswitch.conf
COPY sshd_config	/etc/ssh/sshd_config
COPY pam.d		/etc/pam.d

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
