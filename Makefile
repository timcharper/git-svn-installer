ALIEN_VERSION := 1.7.17.1
APR_UTIL_VERSION := 1.5.4
APR_VERSION := 1.5.1
SVN_VERSION := 1.8.11
CORES := $(shell bash -c "sysctl hw.ncpu | awk '{print \$$2}'")
PACKAGE_MAKER_APP := $(shell bin/find-dir {/Developer,}/Applications/Utilities/PackageMaker.app)
BUILD_CODE := x86_64-yosemite
VERSION := 0.1

.PHONY: compile download

.SECONDARY:

build/Alien-SVN-v$(ALIEN_VERSION).tar.gz:
	mkdir -p build
	curl -L http://search.cpan.org/CPAN/authors/id/M/MS/MSCHWERN/Alien-SVN-v$(ALIEN_VERSION).tar.gz -o $@

build/apr-util-$(APR_UTIL_VERSION).tar.gz:
	curl -L http://mirror.reverse.net/pub/apache/apr/apr-util-$(APR_UTIL_VERSION).tar.gz -o $@

build/apr-$(APR_VERSION).tar.gz:
	curl -L http://mirror.reverse.net/pub/apache/apr/apr-$(APR_VERSION).tar.gz -o $@


build/subversion-$(SVN_VERSION).tar.gz:
	curl -L http://apache.osuosl.org/subversion/subversion-$(SVN_VERSION).tar.gz -o $@

build/Alien-SVN-v$(ALIEN_VERSION)/Build.PL: build/Alien-SVN-v$(ALIEN_VERSION).tar.gz
	tar xzf build/Alien-SVN-v$(ALIEN_VERSION).tar.gz -C build/
	touch $@ # make it newer than the tarball

download: build/Alien-SVN-v$(ALIEN_VERSION).tar.gz build/apr-util-$(APR_UTIL_VERSION).tar.gz build/apr-util-$(APR_UTIL_VERSION).tar.gz build/subversion-$(SVN_VERSION).tar.gz

# APR

build/apr-$(APR_VERSION)/configure: build/apr-$(APR_VERSION).tar.gz
	tar xzf build/apr-$(APR_VERSION).tar.gz -C build/
	touch $@ # make it newer than the tarball

build/apr-$(APR_VERSION)/config.status: build/apr-$(APR_VERSION)/configure
	cd build/apr-$(APR_VERSION)/; ./configure --prefix=/usr/local/git --mandir=/usr/local/git/share/man

build/apr-$(APR_VERSION)/osx-built: build/apr-$(APR_VERSION)/config.status
	cd build/apr-$(APR_VERSION)/; $(MAKE)
	touch $@

build/apr-$(APR_VERSION)/osx-installed: build/apr-$(APR_VERSION)/osx-built
	cd build/apr-$(APR_VERSION)/; sudo $(MAKE) install
	sudo chown -R `whoami` build/apr-$(APR_VERSION)
	touch $@

# APR UTIL
build/apr-util-$(APR_UTIL_VERSION)/configure: build/apr-util-$(APR_UTIL_VERSION).tar.gz
	tar xzf build/apr-util-$(APR_UTIL_VERSION).tar.gz -C build/
	touch $@ # make it newer than the tarball

build/apr-util-$(APR_UTIL_VERSION)/config.status: build/apr-$(APR_VERSION)/osx-installed build/apr-util-$(APR_UTIL_VERSION)/configure
	cd build/apr-util-$(APR_UTIL_VERSION)/; ./configure --prefix=/usr/local/git --mandir=/usr/local/git/share/man --with-apr=/usr/local/git

build/apr-util-$(APR_UTIL_VERSION)/osx-built: build/apr-util-$(APR_UTIL_VERSION)/config.status
	cd build/apr-util-$(APR_UTIL_VERSION)/; $(MAKE)
	touch $@

build/apr-util-$(APR_UTIL_VERSION)/osx-installed: build/apr-$(APR_VERSION)/osx-installed build/apr-util-$(APR_UTIL_VERSION)/osx-built
	cd build/apr-util-$(APR_UTIL_VERSION)/; sudo $(MAKE) install
	touch $@

# Subversion
# build/subversion-$(SVN_VERSION)/configure: build/subversion-$(SVN_VERSION).tar.gz
# 	tar xzf build/subversion-$(SVN_VERSION).tar.gz -C build/
# 	touch $@ # make it newer than the tarball

# build/subversion-$(SVN_VERSION)/config.status: build/apr-$(APR_VERSION)/osx-installed build/subversion-$(SVN_VERSION)/configure
# 	cd build/subversion-$(SVN_VERSION)/; ./configure --prefix=/usr/local/git --mandir=/usr/local/git/share/man --with-apr=/usr/local/git --with-apr-util=/usr/local/git

# - with-apr = ../apr-1.4.5/apr-1-config - with-apr-util = ../apr-util-1.3.9/apu-1-config - 
# prefix = / usr / local / subversion - without-berkeley-db

# build/subversion-$(SVN_VERSION)/osx-built: build/subversion-$(SVN_VERSION)/config.status
# 	cd build/subversion-$(SVN_VERSION)/; $(MAKE) -j $(CORES)
# 	touch $@

# build/subversion-$(SVN_VERSION)/osx-installed: build/subversion-$(SVN_VERSION)/osx-built
# 	cd build/subversion-$(SVN_VERSION)/; sudo $(MAKE) install
# 	touch $@

compile-apr: build/apr-$(APR_VERSION)/osx-built

compile-apr-util: build/apr-util-$(APR_UTIL_VERSION)/osx-built

build/Alien-SVN-v$(ALIEN_VERSION)/Build: build/Alien-SVN-v$(ALIEN_VERSION)/Build.PL build/apr-util-$(APR_UTIL_VERSION)/osx-installed build/apr-$(APR_VERSION)/osx-installed
	# --libdir=/usr/local/git/lib/perl5/site_perl/5.18.2/darwin-thread-multi-2level/SVN --prefix=/usr/local/git PERL=perl --mandir=/usr/local/git/share/man --with-apr=/usr/local/git --with-apr-util=/usr/local/git
	cd build/Alien-SVN-v1.7.17.1/src/subversion/; ./configure --libdir=/usr/local/git/lib/perl5/site_perl/5.18.2/darwin-thread-multi-2level/SVN --prefix=/usr/local/git PERL=perl --mandir=/usr/local/git/share/man --with-apr=/usr/local/git --with-apr-util=/usr/local/git
	cd build/Alien-SVN-v$(ALIEN_VERSION); perl Build.PL \
		--make=$(MAKE) \
		PREFIX=/usr/local/git \
		INSTALLPRIVLIB=/usr/local/git/lib/perl5 \
		INSTALLVENDORARCH=/usr/local/git/lib/perl5/site_perl/5.18.2/darwin-thread-multi-2level/ \
		INSTALLSCRIPT=/usr/local/git/bin \
		INSTALLSITELIB=/usr/local/git/lib/perl5/site_perl \
		INSTALLBIN=/usr/local/git/bin \
		INSTALLMAN1DIR=/usr/local/git/share/man/man1 \
		INSTALLMAN3DIR=/usr/local/git/share/man/man3

build/Alien-SVN-v$(ALIEN_VERSION)/osx-built: build/Alien-SVN-v$(ALIEN_VERSION)/Build
	cd build/Alien-SVN-v1.7.17.1/src/subversion/; make -j $(CORES)
	cd build/Alien-SVN-v$(ALIEN_VERSION); sudo ./Build
	touch $@

build/Alien-SVN-v$(ALIEN_VERSION)/osx-installed: build/Alien-SVN-v$(ALIEN_VERSION)/osx-built build/apr-util-$(APR_UTIL_VERSION)/osx-installed build/apr-$(APR_VERSION)/osx-installed
	cd build/Alien-SVN-v$(ALIEN_VERSION); sudo ./Build install
	chown -R root /usr/local/git
	touch $@

compile: build/Alien-SVN-v$(ALIEN_VERSION)/osx-built
install: build/Alien-SVN-v$(ALIEN_VERSION)/osx-installed

disk-image/VERSION-$(VERSION)-$(BUILD_CODE):
	rm -f disk-image/*.pkg disk-image/VERSION-* disk-image/.DS_Store
	touch "$@"

disk-image/git-svn-assets-$(VERSION)-$(BUILD_CODE).pkg: disk-image/VERSION-$(VERSION)-$(BUILD_CODE)
	$(SUDO) bash -c "$(PACKAGE_MAKER_APP)/Contents/MacOS/PackageMaker --doc GitSVNInstaller.pmdoc/ -o disk-image/git-svn-assets-$(VERSION)-$(BUILD_CODE).pkg --title 'Git-SVN Assets $(BUILD_CODE)'"

package: disk-image/git-svn-assets-$(VERSION)-$(BUILD_CODE).pkg

git-svn-assets-$(VERSION)-$(BUILD_CODE).dmg: disk-image/git-svn-assets-$(VERSION)-$(BUILD_CODE).pkg
	rm -f git-svn-assets-$(VERSION)-$(BUILD_CODE).dmg
	hdiutil create git-svn-assets-$(VERSION)-$(BUILD_CODE).uncompressed.dmg -srcfolder disk-image -volname "Git-SVN Assets $(VERSION) $(BUILD_CODE)" -ov
	hdiutil convert -format UDZO -o $@ git-svn-assets-$(VERSION)-$(BUILD_CODE).uncompressed.dmg
	rm -f git-svn-assets-$(VERSION)-$(BUILD_CODE).uncompressed.dmg

image: git-svn-assets-$(VERSION)-$(BUILD_CODE).dmg

soft-reinstall:
	sudo rm -rf  build/apr-$(APR_VERSION)/osx-installed build/apr-util-$(APR_UTIL_VERSION)/osx-installed build/Alien-SVN-v$(ALIEN_VERSION)/osx-installed
	$(MAKE) install
reinstall:
	sudo rm -rf /usr/local/git build/apr-$(APR_VERSION)/osx-installed build/apr-util-$(APR_UTIL_VERSION)/osx-installed build/Alien-SVN-v$(ALIEN_VERSION)/osx-installed
	$(MAKE) install


# --libdir=/usr/local/git/lib/perl5/site_perl/5.18.2/darwin-thread-multi-2level/SVN --prefix=/usr/local/git PERL=perl --mandir=/usr/local/git/share/man --with-apr=/usr/local/git --with-apr-util=/usr/local/git
