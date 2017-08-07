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

# config env
echo "------config env------"
mkdir ~/golang
export GOPATH=$HOME/golang
export PATH=$PATH:$GOPATH/bin

# install vim-bundle
echo "------install vim-bundle------"
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp /vimrc_ide ~/.vimrc
mkdir ~/.vim/colors
cp -f /distinguished.vim ~/.vim/colors

# install vim-go
echo "------install vim-go------"
mkdir -p ~/.vim/autoload ~ 
cd ~/.vim/autoload
curl -LSso pathogen.vim https://tpo.pe/pathogen.vim
cd ~/.vim/bundle
git clone https://github.com/fatih/vim-go.git
go get -u github.com/nsf/gocode \
	github.com/alecthomas/gometalinter \
	golang.org/x/tools/cmd/goimports \
	golang.org/x/tools/cmd/guru \
	golang.org/x/tools/cmd/gorename \
	github.com/golang/lint/golint \
	github.com/rogpeppe/godef \
	github.com/kisielk/errcheck \
	github.com/jstemmer/gotags \
	github.com/klauspost/asmfmt/cmd/asmfmt \
	github.com/fatih/motion \
	github.com/fatih/gomodifytags \
	github.com/zmb3/gogetdoc \
	github.com/josharian/impl \
	github.com/dominikh/go-tools/cmd/keyify

# install vim-plugin
echo "------install vim-plugin(YouCompleteMe)------"
git clone https://github.com/Valloric/YouCompleteMe.git ~/.vim/bundle/YouCompleteMe
cd ~/.vim/bundle/YouCompleteMe
git submodule update --init --recursive
~/.vim/bundle/YouCompleteMe/install.py --clang-completer --gocode-completer
cp -f /ycm_extra_conf.py ~/.vim/.ycm_extra_conf.py
vim +PluginInstall +qall +qa

# config bashrc 
USER_HOME="/home/""$USER_NAME""/"
echo "export GOPATH=\$HOME/golang" >> "$USER_HOME"".bashrc"
echo "export PATH=\$PATH:\$GOPATH/bin" >> "$USER_HOME"".bashrc"

# cp vim plugin and go workspace to USER_NAME
cp -r ~/golang $USER_HOME 
cp -r ~/.vim $USER_HOME
cp ~/.vimrc $USER_HOME
chown -R $USER_NAME:$USER_NAME $USER_HOME

exec "$@"
