pwd=$(shell pwd)
home=$(shell ls -d ~/)
home_configs=ctags screenrc gitconfig vim inputrc jslintrc tmux.conf
home_targets=${home_configs:%=${home}.%}
targets=${home_targets} ${home}.vimrc ${home}bin
cmd=@echo "new config:"

.PHONY: all install

all:cmd=@echo "new config:"
all: ${targets}
	@echo "*** use 'make install' to install ***"

install:cmd=ln -sf
install: ${targets} ${home}.tmp
	@echo "please modify [user] session in gitconfig and TagPath in script/daily_build.sh"

${home_targets}: $(subst ${home}.,,$@)
	${cmd} ${pwd}/$(subst ${home}.,,$@) $@

${home}.vimrc: vim/vimrc
	${cmd} ${pwd}/$< $@

${home}bin: script
	${cmd} ${pwd}/$< $@

${home}.tmp:
	mkdir $@

${home}.gitconfig: gitconfig

gitconfig: gitconfig.in
	sed -e 's%@USER@%$(shell whoami)%g' $< > $@
