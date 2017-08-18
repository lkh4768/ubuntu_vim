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

# set user
file_env 'USER_NAME'
if [ ! "$USER_NAME" ]
then
	USER_NAME="user"
fi

# add user
if id "$USER_NAME" >/dev/null 2>&1; then
	echo "already user($USER_NAME) exists"
else
	useradd -m -s /bin/bash $USER_NAME
fi

# create user password
if [ ! "$USER_PASS" ]
then
	USER_PASS=`date +%s | sha256sum | base64 | head -c 32`
fi

# show user password
echo "$USER_NAME""'s password: ""$USER_PASS"
# set user password
echo "$USER_NAME:$USER_PASS" | chpasswd

# config env
GO_PATH="$HOME/golang"
if [ -e "$GO_PATH" ]
then
	echo "already GOPATH($GO_PATH) exists"
else
	mkdir $GO_PATH
fi
export GOPATH=$GO_PATH
export PATH=$PATH:$GOPATH/bin

# install vim-bundle
VIM_BUNDLE_PATH="$HOME/.vim/bundle/Vundle.vim"
if [ -e "$VIM_BUNDLE_PATH" ]
then
	echo "already vim bundle($VIM_BUNDLE_PATH) exists"
else
	git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

cp -f /vimrc_ide ~/.vimrc

VIM_COLORS_PATH="$HOME/.vim/colors"
if [ -e "$VIM_COLORS_PATH" ]
then
	echo "already vim colors($VIM_COLORS_PATH) exists"
else
	mkdir $VIM_COLORS_PATH
fi

cp -f /distinguished.vim ~/.vim/colors

# install vim-go
VIM_AUTOLOAD_PATH="$HOME/.vim/autoload"
if [ -e "$VIM_AUTOLOAD_PATH" ]
then
	echo "already vim autoload($VIM_AUTOLOAD_PATH) exists"
else
	mkdir -p $VIM_AUTOLOAD_PATH
fi

cd ~/.vim/autoload
curl -LSso pathogen.vim https://tpo.pe/pathogen.vim

cd ~/.vim/bundle
VIM_GO_PATH="vim-go"
if [ -e "$VIM_GO_PATH" ]
then
	echo "already vim-go($VIM_GO_PATH) exists"
else
	git clone https://github.com/fatih/vim-go.git
fi

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
YOUCOMPLETEME_PATH="$HOME/.vim/bundle/YouCompleteMe"
if [ -e "$YOUCOMPLETEME_PATH" ]
then
	echo "already vim YouCompleteMe($VIM_AUTOLOAD_PATH) exists"
else
	git clone https://github.com/Valloric/YouCompleteMe.git $YOUCOMPLETEME_PATH
fi

cd ~/.vim/bundle/YouCompleteMe
git submodule update --init --recursive
~/.vim/bundle/YouCompleteMe/install.py --clang-completer --gocode-completer
cp -f /ycm_extra_conf.py ~/.vim/.ycm_extra_conf.py
vim +PluginInstall +qall +qa

# config bashrc 
USER_HOME="/home/""$USER_NAME""/"
echo "$USER_HOME"
if [ -z "$(grep "GOPATH=\\\$HOME/golang" $USER_HOME.bashrc)" ]
then
	echo "export GOPATH=\$HOME/golang" >> "$USER_HOME.bashrc"
else
	echo "already add GOPATH in $USER_HOME.bashrc"
fi

if [ -z "$(grep "PATH=\\\$PATH:\\\$GOPATH/bin" $USER_HOME.bashrc)" ]
then
	echo "export PATH=\$PATH:\$GOPATH/bin" >> "$USER_HOME.bashrc"
else
	echo "already add PATH in $USER_HOME.bashrc"
fi

# cp vim plugin and go workspace to USER_NAME
cp -f -r ~/golang $USER_HOME 
cp -f -r ~/.vim $USER_HOME
cp -f ~/.vimrc $USER_HOME
chown -R $USER_NAME:$USER_NAME $USER_HOME

exec "$@"
