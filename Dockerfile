FROM ubuntu

RUN apt-get update \
	&& apt-get install -y --no-install-recommends software-properties-common python-software-properties \
	&& add-apt-repository -y ppa:jonathonf/vim \
	&& apt-get install -y --no-install-recommends \
	man-db \
	manpages \
	manpages-dev \
	manpages-posix-dev \
	glibc-doc \
	build-essential \
	curl \
	cmake \
	ctags \
	git \
	wget \
	python \
	python-dev \
	python3-dev \
	openssh-server \
	mercurial \
	clang \
	libncurses5-dev \
	libncursesw5-dev \
	ca-certificates \
	openssl \
	vim \
	&& rm -rf /var/lib/apt/lists/* \
# config sshd
	&& mkdir /var/run/sshd \
	&& sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
	&& echo "Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,aes256-cbc" >> /etc/ssh/sshd_config

COPY files/vimrc_ide /
COPY files/distinguished.vim /
COPY files/docker-entrypoint.sh /
COPY files/ycm_extra_conf.py /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 22
CMD    ["/usr/sbin/sshd", "-D"]
