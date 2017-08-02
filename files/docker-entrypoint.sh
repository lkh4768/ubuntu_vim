#!/bin/bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

#add user
file_env 'USER_NAME'
if [ ! "$USER_NAME" ]
then
	USER_NAME="user"
fi

#set user password
useradd -m -s /bin/bash $USER_NAME
if [ ! "$USER_PASS" ]
then
	USER_PASS=`date +%s | sha256sum | base64 | head -c 32`
fi

# show user password
echo "$USER_NAME""'s password: ""$USER_PASS"
echo "$USER_NAME:$USER_PASS" | chpasswd

# install vim plugin to root
git config --global http.sslVerify false
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp /vimrc_lite ~/.vimrc
mkdir ~/.vim/colors
cp -f /distinguished.vim ~/.vim/colors
vim +PluginInstall +qall +qa

# cp vim plugin to USER_NAME
USER_HOME="/home/""$USER_NAME""/"
echo "git config --global http.sslVerify false" >> "$USER_HOME"".bashrc"
cp -r ~/.vim $USER_HOME
cp ~/.vimrc $USER_HOME
chown -R $USER_NAME:$USER_NAME $USER_HOME

exec "$@"
