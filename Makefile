

################################################################################


BUILD               = $(shell git rev-parse HEAD)

PLATFORMS           = linux_amd64 linux_386 linux_armv5 linux_armv6 linux_armv7 linux_armv8 darwin_amd64 darwin_386 freebsd_amd64 freebsd_386 freebsd_armv5 freebsd_armv6 freebsd_armv7 windows_amd64 windows_386

FLAGS_all           = GOPATH=$(GOPATH)

FLAGS_linux_amd64   = $(FLAGS_all) GOOS=linux GOARCH=amd64
FLAGS_linux_386     = $(FLAGS_all) GOOS=linux GOARCH=386
FLAGS_linux_armv5   = $(FLAGS_all) GOOS=linux GOARCH=arm GOARM=5
FLAGS_linux_armv6   = $(FLAGS_all) GOOS=linux GOARCH=arm GOARM=6
FLAGS_linux_armv7   = $(FLAGS_all) GOOS=linux GOARCH=arm GOARM=7
FLAGS_linux_armv8   = $(FLAGS_all) GOOS=linux GOARCH=arm64
FLAGS_darwin_amd64  = $(FLAGS_all) GOOS=darwin GOARCH=amd64
FLAGS_darwin_386    = $(FLAGS_all) GOOS=darwin GOARCH=386
FLAGS_freebsd_amd64 = $(FLAGS_all) GOOS=freebsd GOARCH=amd64
FLAGS_freebsd_386   = $(FLAGS_all) GOOS=freebsd GOARCH=386
FLAGS_freebsd_armv5 = $(FLAGS_all) GOOS=freebsd GOARCH=arm GOARM=5
FLAGS_freebsd_armv6 = $(FLAGS_all) GOOS=freebsd GOARCH=arm GOARM=6
FLAGS_freebsd_armv7 = $(FLAGS_all) GOOS=freebsd GOARCH=arm GOARM=7
FLAGS_windows_386   = $(FLAGS_all) GOOS=windows GOARCH=386
FLAGS_windows_amd64 = $(FLAGS_all) GOOS=windows GOARCH=amd64

EXTENSION_windows_386=.exe
EXTENSION_windows_amd64=.exe

msg=@printf "\n\033[0;01m>>> %s\033[0m\n" $1


################################################################################


.DEFAULT_GOAL := build

build: guard-BUILD_VERSION guard-BUILD_REVISION guard-BUILD_DATE deps
	$(call msg,"Build binary")
	$(FLAGS_all) go build -ldflags '-X "main.version=${BUILD_VERSION}" -X "main.revision=${BUILD_REVISION}" -X "main.date=${BUILD_DATE}"' -o docker-volume-glusterfs$(EXTENSION_$GOOS_$GOARCH) *.go
	./docker-volume-glusterfs -version
.PHONY: build

deps:
	$(call msg,"Get dependencies")
	go get -t ./...
	go get -d github.com/golang/lint/golint
	go get -d github.com/Sirupsen/logrus
	go get -d github.com/coreos/go-systemd/activation
	go get -d github.com/opencontainers/runc/libcontainer/user
	go get -d github.com/Microsoft/go-winio
	go get -d golang.org/x/sys/windows
.PHONY: deps

install: build
	$(call msg,"Install docker-volume-glusterfs")
	mkdir -p /usr/local/bin/
	cp docker-volume-glusterfs /usr/local/bin/
.PHONY:	install

uninstall:
	$(call msg,"Uninstall docker-volume-glusterfs")
	rm -f /usr/local/bin/docker-volume-glusterfs
.PHONY:	uninstall

test: deps
	$(call msg,"Run tests")
	$(FLAGS_all) go test $(wildcard ../*.go)
.PHONY: test

clean:
	$(call msg,"Clean directory")
	rm -f docker-volume-glusterfs
	rm -rf dist
.PHONY: clean

build-all: deps guard-BUILD_VERSION guard-BUILD_REVISION guard-BUILD_DATE \
$(foreach PLATFORM,$(PLATFORMS),dist/$(PLATFORM)/.built)
.PHONY: build-all

dist: guard-BUILD_VERSION build-all \
$(foreach PLATFORM,$(PLATFORMS),dist/docker-volume-glusterfs-$(BUILD_VERSION)-$(PLATFORM).zip) \
$(foreach PLATFORM,$(PLATFORMS),dist/docker-volume-glusterfs-$(BUILD_VERSION)-$(PLATFORM).tar.gz)
.PHONY:	dist

changelog: guard-GITHUB_TOKEN
	github_changelog_generator -u amarkwalder -p docker-volume-glusterfs -t ${GITHUB_TOKEN}
.PHONY: changelog

release: guard-BUILD_VERSION dist
	$(call msg,"Create and push release")
	git tag -a "v$(BUILD_VERSION)" -m "Release $(BUILD_VERSION)"
	git push --tags
.PHONY: release


################################################################################

dist/%/.built:
	$(call msg,"Build binary for $*")
	rm -f $@
	mkdir -p $(dir $@)
	$(FLAGS_$*) go build -ldflags '-X "main.version=${BUILD_VERSION}" -X "main.revision=${BUILD_REVISION}" -X "main.date=${BUILD_DATE}"' -o dist/$*/docker-volume-glusterfs$(EXTENSION_$*) $(wildcard ../*.go)
	touch $@

dist/docker-volume-glusterfs-$(BUILD_VERSION)-%.zip:
	$(call msg,"Create ZIP for $*")
	rm -f $@
	mkdir -p $(dir $@)
	zip -j $@ dist/$*/* -x .built

dist/docker-volume-glusterfs-$(BUILD_VERSION)-%.tar.gz:
	$(call msg,"Create TAR for $*")
	rm -f $@
	mkdir -p $(dir $@)
	tar czf $@ -C dist/$* --exclude=.built .

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi


################################################################################
