

################################################################################


BUILD               = $(shell git rev-parse HEAD)

msg=@printf "\n\033[0;01m>>> %s\033[0m\n" $1


################################################################################


.DEFAULT_GOAL := build

build: guard-VERSION deps
	$(call msg,"Build binary")
	GOPATH=$(GOPATH) go build -ldflags "-X main.version=${VERSION} -X main.commit=${BUILD} -X main.date=`date +%FT%TZ`" -o docker-volume-glusterfs$(EXTENSION_$GOOS_$GOARCH) *.go
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

install: guard-VERSION build
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
	GOPATH=$(GOPATH) go test $(wildcard ../*.go)
.PHONY: test

clean:
	$(call msg,"Clean directory")
	rm -f docker-volume-glusterfs
	rm -rf dist
.PHONY: clean

dist-snapshot:
	curl -sL https://git.io/goreleaser | bash -s -- --rm-dist --snapshot
.PHONY: dist-snapshot

dist-release: guard-GITHUB_TOKEN
	curl -sL https://git.io/goreleaser | bash -s -- --rm-dist
.PHONY: dist-release

release: guard-VERSION
	$(call msg,"Create and push release")
	git tag -a "v$(VERSION)" -m "Release $(VERSION)"
	git push --tags
.PHONY: release


################################################################################


guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi


################################################################################
