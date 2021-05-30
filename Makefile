GOPKG ?=	moul.io/repoman
DOCKER_IMAGE ?=	moul/repoman
GOBINS ?=	.
NPM_PACKAGES ?=	.

include rules.mk

generate: install
	GO111MODULE=off go get github.com/campoy/embedmd
	mkdir -p .tmp

	echo 'foo@bar:~$$ repoman -h' > .tmp/usage.txt
	repoman -h 2>> .tmp/usage.txt

	for sub in maintenance doctor version template-post-clone info; do \
	  echo 'foo@bar:~$$ repoman '$$sub' -h' > .tmp/usage-$$sub.txt; \
	  repoman $$sub -h 2>> .tmp/usage-$$sub.txt; \
	done

	echo 'foo@bar:~$$ repoman info .' > .tmp/example-info.txt
	repoman info . >> .tmp/example-info.txt

	embedmd -w README.md
	rm -rf .tmp
.PHONY: generate

lint:
	cd tool/lint; make
.PHONY: lint
