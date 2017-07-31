FROM ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	vim \
	ctags \
	git \
	wget \
	python \
	golang-go \
	openssh-server \
	&& rm -rf /var/lib/apt/lists/* \
# config sshd
	&& mkdir /var/run/sshd \
	&& sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
	&& echo "Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,aes256-cbc" >> /etc/ssh/sshd_config

COPY files/vimrc_lite /
COPY files/distinguished.vim /
COPY files/docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 22
CMD    ["/usr/sbin/sshd", "-D"]
