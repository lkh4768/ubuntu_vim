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

USER_HOME="/home/""$USER_NAME""/"
YOUCOMPLETEME_PATH="$HOME/.vim/bundle/YouCompleteMe"
VIM_BUNDLE_PATH="$HOME/.vim/bundle/Vundle.vim"
VIM_COLORS_PATH="$HOME/.vim/colors"

if id "$USER_NAME" >/dev/null 2>&1; then
	echo "= Already user($USER_NAME) exists ="
else
	useradd -m -s /bin/bash $USER_NAME
fi

# create user password
if [ ! "$USER_PASS" ]
then
	USER_PASS=`date +%s | sha256sum | base64 | head -c 32`
fi

# set user password
echo "$USER_NAME:$USER_PASS" | chpasswd

# show user password
echo "= Create user success ="
echo "$USER_NAME""'s password: ""$USER_PASS"

# install vim-bundle
if [ -e "$VIM_BUNDLE_PATH" ]
then
	echo "= Already vim bundle($VIM_BUNDLE_PATH) exists ="
else
	git clone -q https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
echo "= Install vim Bundle success ="

cp -f /vimrc_ide ~/.vimrc > /dev/null
if [ -e "$VIM_COLORS_PATH" ]
then
	echo "already vim colors($VIM_COLORS_PATH) exists"
else
	mkdir $VIM_COLORS_PATH
fi
echo "= Config vim colors success ="

cp -f /distinguished.vim ~/.vim/colors > /dev/null

# install golnag v1.9
file_env 'GOLANG_INSTALL'
if [ ! "$GOLANG_INSTALL" ]
then
	GOLANG_INSTALL="false"
fi

echo "= GOLANG_INSTALL($GOLANG_INSTALL) ="

if [ "$GOLANG_INSTALL" == "true" ]
then
	GO_PATH="$HOME/golang"
	GOROOT="/usr/local/go"
	VIM_AUTOLOAD_PATH="$HOME/.vim/autoload"
	VIM_GO_PATH="vim-go"

	if [ -e "GOROOT" ]
	then
		echo "= Already golang($GOROOT) exists ="
	else
		cd /tmp
		wget -q https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz > /dev/null
		tar -C /usr/local -xzf go1.9.linux-amd64.tar.gz > /dev/null
		rm -rf /tmp/go1.9.linux-amd64.tar.gz > /dev/null
	fi

	echo "= Install Golang($GOROOT) success ="

	# config env
	if [ -e "$GO_PATH" ]
	then
		echo "= Already GOPATH($GO_PATH) exists ="
	else
		mkdir $GO_PATH > /dev/null
	fi
	export GOPATH=$GO_PATH
	export GOROOT=$GOROOT
	export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

	echo "= Config env val of root for golang sucess ="

	# install vim-go
	if [ -e "$VIM_AUTOLOAD_PATH" ]
	then
		echo "= Already vim autoload($VIM_AUTOLOAD_PATH) exists ="
	else
		mkdir -p $VIM_AUTOLOAD_PATH > /dev/null
	fi

	cd ~/.vim/autoload
	curl -LSso pathogen.vim https://tpo.pe/pathogen.vim > /dev/null

	echo "= Config autoload sucess ="

	cd ~/.vim/bundle
	if [ -e "$VIM_GO_PATH" ]
	then
		echo "= Already vim-go($VIM_GO_PATH) exists ="
	else
		git clone -q https://github.com/fatih/vim-go.git
	fi

	echo "= Install vim-go success ="

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
		github.com/dominikh/go-tools/cmd/keyify > /dev/null

	echo "= Install vim-go plugin success ="

	# config bashrc 
	if [ -z "$(grep "GOPATH=\\\$HOME/golang" $USER_HOME.bashrc)" ]
	then
		echo "export GOPATH=\$HOME/golang" >> "$USER_HOME.bashrc"
	else
		echo "= Already add GOPATH in $USER_HOME.bashrc ="
	fi

	if [ -z "$(grep "PATH=\\\$PATH:\\\$GOPATH/bin:\\\$GOROOT/bin" $USER_HOME.bashrc)" ]
	then
		echo "export PATH=\$PATH:\$GOPATH/bin:\$GOROOT/bin" >> "$USER_HOME.bashrc"
	else
		echo "= Already add PATH in $USER_HOME.bashrc ="
	fi

	echo "= Config env val of $USER_NAME for golang sucecss ="

	# cp go workspace to USER_NAME
	cp -f -r ~/golang $USER_HOME 

	echo "= Copy golang workspace to $USER_NAME from root success="
fi

# install vim-plugin
if [ -e "$YOUCOMPLETEME_PATH" ]
then
	echo "= Already vim YouCompleteMe($VIM_AUTOLOAD_PATH) exists ="
else
	git clone -q https://github.com/Valloric/YouCompleteMe.git $YOUCOMPLETEME_PATH
fi

echo "= Install vim YouCompleteMe($VIM_AUTOLOAD_PATH) success ="

cd ~/.vim/bundle/YouCompleteMe
git submodule -q update --init --recursive
~/.vim/bundle/YouCompleteMe/install.py --clang-completer --gocode-completer > /dev/null
cp -f /ycm_extra_conf.py ~/.vim/.ycm_extra_conf.py > /dev/null
vim +PluginInstall +qall +qa

echo "= Install vim plugin success ="

# cp vim plugin to USER_NAME
cp -f -r ~/.vim $USER_HOME
cp -f ~/.vimrc $USER_HOME
chown -R $USER_NAME:$USER_NAME $USER_HOME

echo "= Copy vim to $USER_NAME from root success ="

echo "= Complete ="

exec "$@"
