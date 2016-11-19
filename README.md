Introduction
=============

This is my linux configs and vim settings

Getting Started
===============

Install

	$ cd ~
	$ git clone https://github.com/ilcic/config.git
	$ install.sh -a
	$ install.sh -i
	$ source .bashrc

For vim install please check out `vim`

For Synology
===============

build tags

	$ ln -s ~/config/script/syno.build.tags /synosrc/syno.build_tags
	$ cd /synosrc
	$ ./syno.build_tags

syno.build.status

	$ cd ~/config/addon
	$ tar zxvf JSON-2.53.tar.gz
	$ cd JSON-2.53/
	$ perl Makefile.PL
	$ make
	$ make install
