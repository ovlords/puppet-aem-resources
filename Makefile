ci: clean deps lint package

deps:
	gem install bundler --version=1.17.3
	bundle config --local path vendor/bundle
	bundle install --binstubs -j4
	bundle exec r10k puppetfile install --verbose --moduledir modules
	cd test/integration/ && bundle exec r10k puppetfile install --verbose --moduledir modules

clean:
	rm -rf bin/ pkg/ stage/ vendor/ modules/
	rm -rf test/integration/.tmp/ \
	  test/integration/modules/ \
	  /tmp/shinesolutions/puppet-aem-resources/

lint:
	bundle exec puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		test/integration/*/*.pp \
		manifests/*.pp
	puppet epp validate templates/*.epp
	bundle exec rubocop --config .rubocop.yml lib/ Gemfile
	bundle exec yaml-lint .*.yml
	# since pdk bundles its own rubies, we need to run pdk when there's no Gemfile.lock
	# this is due to Gemfile.lock being created by environment bundler which is of a different
	# version to the available bundler bundled within pdk's ruby
	mv Gemfile.lock Gemfile.lock.orig && PDK_DISABLE_ANALYTICS=true pdk validate metadata && mv Gemfile.lock.orig Gemfile.lock

test-integration:
	# set up module
	mkdir -p test/integration/modules/aem_resources/
	cp -R lib test/integration/modules/aem_resources/
	cp -R manifests test/integration/modules/aem_resources/
	cp -R templates test/integration/modules/aem_resources/
	# set up test fixtures
	useradd aem || echo "User might already exist"
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author/somepackagegroup/somepackage/1.2.3/
	cp test/fixtures/* /tmp/shinesolutions/puppet-aem-resources/
	cp test/fixtures/somepackage-1.2.3.zip /tmp/shinesolutions/puppet-aem-resources/author/somepackagegroup/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-primary-6.2/crx-quickstart/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-primary-6.2/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-primary-6.2/crx-quickstart/install/
	cp test/fixtures/start-env /tmp/shinesolutions/puppet-aem-resources/author-primary-6.2/crx-quickstart/bin/
	cp test/fixtures/start /tmp/shinesolutions/puppet-aem-resources/author-primary-6.2/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-primary-6.3/crx-quickstart/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-primary-6.3/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-primary-6.3/crx-quickstart/install/
	cp test/fixtures/start-env /tmp/shinesolutions/puppet-aem-resources/author-primary-6.3/crx-quickstart/bin/
	cp test/fixtures/start /tmp/shinesolutions/puppet-aem-resources/author-primary-6.3/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-standby-6.2/crx-quickstart/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-standby-6.2/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-standby-6.2/crx-quickstart/install/
	cp test/fixtures/start-env /tmp/shinesolutions/puppet-aem-resources/author-standby-6.2/crx-quickstart/bin/
	cp test/fixtures/start /tmp/shinesolutions/puppet-aem-resources/author-standby-6.2/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-standby-6.3/crx-quickstart/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-standby-6.3/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/author-standby-6.3/crx-quickstart/install/
	cp test/fixtures/start-env /tmp/shinesolutions/puppet-aem-resources/author-standby-6.3/crx-quickstart/bin/
	cp test/fixtures/start /tmp/shinesolutions/puppet-aem-resources/author-standby-6.3/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/publish/crx-quickstart/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/publish/crx-quickstart/bin/
	mkdir -p /tmp/shinesolutions/puppet-aem-resources/publish/crx-quickstart/install/
	cp test/fixtures/start-env /tmp/shinesolutions/puppet-aem-resources/publish/crx-quickstart/bin/
	cp test/fixtures/start /tmp/shinesolutions/puppet-aem-resources/publish/crx-quickstart/bin/
	cp test/fixtures/cert_ssl.crt /tmp/shinesolutions/puppet-aem-resources/
	cp test/fixtures/cert_ssl.der /tmp/shinesolutions/puppet-aem-resources/
	cp test/fixtures/cert_ssl2.crt /tmp/shinesolutions/puppet-aem-resources/
	cp test/fixtures/cert_ssl2.der /tmp/shinesolutions/puppet-aem-resources/
	# test manifests
	# author_port needs to be set here for test/integration/manifests/30_deploy_pakages.pp scenario
	for test in test/integration/manifests/*.pp; do \
	  author_port=$$aem_port bundle exec puppet apply --modulepath=test/integration/modules/ $$test; \
	done
	# test resources
	# author_port needs to be set here for test/integration/resources/10_aem_bundle_stopped.pp scenario
	for test in test/integration/resources/*.pp; do \
	  author_port=$$aem_port bundle exec puppet apply --modulepath=test/integration/modules/ $$test; \
	done

test-fixtures:
	rm -f test/fixtures/aem.key test/fixtures/aem.cert
	# use 'somekeystorepassword' when prompted
	# this is due to java_ks using the same password for
	# both keystore and the key inside the keystore
	# so for integration testing, we're passing the same
	# password
	openssl req \
		-new \
		-newkey rsa:4096 \
		-days 365 \
		-x509 \
		-subj "/C=AU/ST=Victoria/L=Melbourne/O=Sample Organisation/CN=aem.cert" \
		-keyout test/fixtures/aem.key \
		-out test/fixtures/aem.cert

package: deps
	# since pdk bundles its own rubies, we need to run pdk when there's no Gemfile.lock
	# this is due to Gemfile.lock being created by environment bundler which is of a different
	# version to the available bundler bundled within pdk's ruby
	mv Gemfile.lock Gemfile.lock.orig && PDK_DISABLE_ANALYTICS=true pdk build --force && mv Gemfile.lock.orig Gemfile.lock

release-major:
	rtk release --release-increment-type major

release-minor:
	rtk release --release-increment-type minor

release-patch:
	rtk release --release-increment-type patch

release: release-minor

publish:
	pdk release publish --force --forge-token=$(forge_token)

.PHONY: ci deps clean lint test-integration test-fixtures package release release-major release-minor release-patch publish
