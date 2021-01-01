COMMANDS = hubsync checkoutmaster maintenance prlist
REPOS ?= $(wildcard */)
OPTS ?= ;
REPOMAN ?= ~/go/src/moul.io/repoman

.PHONY: $(COMMANDS)
$(COMMANDS):
	@for repo in $(REPOS); do ( set -e; \
	  echo "cd $$repo && make -s -f $(REPOMAN)/Makefile _do.$@ $(OPTS)"; \
	  cd $$repo && make -s -f $(REPOMAN)/Makefile _do.$@ $(OPTS) \
	); done

_do.checkoutmaster: _do.hubsync
	git checkout master

_do.hubsync:
	hub sync

_do.prlist:
	@hub pr list -f "- %pC%>(8)%i%Creset %U - %t% l%n"

_do.maintenance: _do.checkoutmaster
	# renovate.json
	mkdir -p .github
	git mv renovate.json .github/renovate.json || true
	git rm -f renovate.json || true
	cp ~/go/src/moul.io/golang-repo-template/.github/renovate.json .github/ || true
	git add .github/renovate.json || true
	git add renovate.json || true

	# dependabot
	cp ~/go/src/moul.io/golang-repo-template/.github/dependabot.yml .github/ || true
	git add .github/dependabot.yml || true

	# rules.mk
	if [ -f rules.mk ]; then cp ~/go/src/moul.io/rules.mk/rules.mk .; fi || true

	# authors
	if [ -f rules.mk ]; then make generate.authors; git add AUTHORS; fi || true

	# copyright
	set -xe; \
	for prefix in "©" "Copyright" "Copyright (c)"; do \
	  for file in README.md LICENSE-APACHE LICENSE-MIT LICENSE COPYRIGHT; do \
	    if [ -f "$$file" ]; then \
				sed -i "s/$$prefix 2014 /$$prefix 2014-2021 /" $$file; \
			  sed -i "s/$$prefix 2015 /$$prefix 2015-2021 /" $$file; \
			  sed -i "s/$$prefix 2016 /$$prefix 2016-2021 /" $$file; \
	      sed -i "s/$$prefix 2017 /$$prefix 2017-2021 /" $$file; \
	      sed -i "s/$$prefix 2018 /$$prefix 2018-2021 /" $$file; \
	      sed -i "s/$$prefix 2019 /$$prefix 2019-2021 /" $$file; \
	      sed -i "s/$$prefix 2020 /$$prefix 2020-2021 /" $$file; \
	      sed -i "s/$$prefix \([0-9][0-9][0-9][0-9]\)-20[0-9][0-9]/$$prefix \1-2021 /" $$file; \
	      sed -i "s/$$prefix 2021-2021/$$prefix 2021 /" $$file; \
	    fi; \
	  done; \
	done

	# golangci-lint fix
	sed -i "s/version: v1.26/version: v1.28/" .github/workflows/*.yml || true
	sed -i "s/version: v1.27/version: v1.28/" .github/workflows/*.yml || true

	# apply changes
	git diff
	git diff --cached
	git branch -D dev/moul/maintenance || true
	git checkout -b dev/moul/maintenance
	git status
	git commit -s -a -m "chore: repo maintenance 🤖" -m "more details: https://github.com/moul/repoman"
	git push -u origin dev/moul/maintenance -f
	hub pull-request -m "chore: repo maintenance 🤖" -m "more details: https://github.com/moul/repoman" || $(MAKE) -f $(REPOMAN)/Makefile _do.prlist
