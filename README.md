configs
=============

my linux configs

make install

edit .bashrc, uncomment the following lines to enable auto complete

        if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
            . /etc/bash_completion
        fi

edit .bashrc, append the following lines

        for f in ~/config/bashrc.d/*; do
                source $f;
                done
        PATH="~/bin:$PATH"

start new bash env, you can login again or simply:

        source .bashrc

install packages

        apt-get install ctags cscope

link syno.build_tags

        ln -s ~/config/script/syno.build.tags /synosrc/syno.build_tags

build tags

        cd /synosrc
        ./syno.build_tags

syno.build.status

        cd ~/config/addon
        tar zxvf JSON-2.53.tar.gz
        cd JSON-2.53/
        perl Makefile.PL
        make
        make install # root permission
