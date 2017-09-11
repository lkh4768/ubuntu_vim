# ubuntu_vim docker-image

Development environment using vim editor (python, c++, c, golang, hugo)

## Quick Start

```
$ docker run -d -p 22:22 --name=vim wes4768/ubuntu_vim
```

default username and userpass :
- username : `user`
- password : random, show `docker logs <container-name>`

```
$ docker logs vim
/* user's password */
user's password: YmQ5YmYwZjQzZWFlM2JjNmMyN2ZiNDdh 
Cloning into '/root/.vim/bundle/Vundle.vim'...
...
```
	
### setting username and user's password and start

```
$ docker run -d -p 22:22 -e USER_NAME="test" -e USER_PASS="test1" --name=vim wes4768/ubuntu_vim
```

### install golang

```
$ docker run -d -p 22:22 -p 1313:1313 -e GOLANG_INSTALL="true" --name=vim wes4768/ubuntu_vim
```

## Available Configuration Parameters

- USER_NAME: The os user. Default `user`.
- USER_PASS: The os user's password. Default `user's password: <USER_PASS>` in `docker logs <container-name>`.
- GOLANG_INSTALL: Install hugo. Default false.

## Export Port

- 22: connecting sshd
