all: remote.1/HEAD remote.2/HEAD

remote.1/HEAD : remote.1.vendor.rb
	rm -rf remote.1 remote.wip
	mkdir remote.wip
	cp remote.1.vendor.rb remote.wip/Vendorfile
	@set -e -x ; \
	    cd remote.wip ; \
	    git init ; \
	    git add Vendorfile ; \
	    git commit -m Vendorfile ; \
	    vendor install
	git clone --mirror --bare remote.wip remote.1
	cd remote.1 ; git gc --aggressive
ifndef KEEP_WIP
	rm -rf remote.wip
endif

remote.2/HEAD: remote.2.vendor.rb remote.1/HEAD
	rm -rf remote.2 remote.wip
	git clone remote.1 remote.wip
	cp remote.2.vendor.rb remote.wip/Vendorfile
	@set -e -x ; \
	    cd remote.wip ; \
	    git checkout --detach ; \
	    git fetch origin '+refs/*:refs/*' ; \
	    git checkout master ; \
	    git add Vendorfile ; \
	    git commit -m bump ; \
	    vendor update
	git clone --mirror --bare remote.wip remote.2
	cd remote.2 ; git gc --aggressive
ifndef KEEP_WIP
	rm -rf remote.wip
endif
