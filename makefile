CS=node_modules/coffee-script/bin/coffee
VERSION=`$(CS) build/bumper.coffee --version`
MOCHA_PHAMTOM=node_modules/mocha-phantomjs/bin/mocha-phantomjs
POLVO=bin/polvo

setup:
	npm link
	@cd tests && make setup



watch:
	$(CS) -wmco lib src

build:
	$(CS) -mco lib src



test: test.dev test.release


test.dev:
	@echo ''
	@echo '★  testing `development` version'
	@echo ''
	@$(POLVO) -c tests
	@echo ''
	@$(MOCHA_PHAMTOM) tests/www/index.html

# testing release version
test.release:
	@echo ''
	@echo '★  testing `release` version'
	@echo ''
	@$(POLVO) -r tests
	@echo ''
	@$(MOCHA_PHAMTOM) tests/www/index.html


bump.minor:
	$(CS) build/bumper.coffee --minor

bump.major:
	$(CS) build/bumper.coffee --major

bump.patch:
	$(CS) build/bumper.coffee --patch



publish:
	git tag $(VERSION)
	git push origin $(VERSION)
	git push origin master
	npm publish

re-publish:
	git tag -d $(VERSION)
	git tag $(VERSION)
	git push origin :$(VERSION)
	git push origin $(VERSION)
	git push origin master -f
	npm publish -f



.PHONY: build