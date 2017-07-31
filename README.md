# ubuntu_vim docker-image

Development environment using vim editor (python, c ++, c, golang)
<<<<<<< HEAD
=======

## Quick Start

```
$ docker run -d -p 22:22 --name=vim wes4768/ubuntu_vim
```

default username and userpass :
	- username : user
	- password : show `docker logs <container-name>`

	```
	$ docker logs vim
	user's password: YmQ5YmYwZjQzZWFlM2JjNmMyN2ZiNDdh
	Cloning into '/root/.vim/bundle/Vundle.vim'...
	...
	```
## setting username and user's password and start
	
```
$ docker run -d -p 22:22 -e USER_NAME="test" -e USER_PASS="test1" --name=vim wes4768/ubuntu_vim
```

## Available Configuration Parameters

- USER_NAME: The os user. Default `user`
- USER_PASS: The os user's password. Default `user's password: <USER_PASS>` in `docker logs <container-name>`
>>>>>>> release/v1.2
