.PHONY: docker-build
docker-build:
	docker build -t flycheck-ci-env --force-rm --compress ./

.PHONY: docker
docker:
	docker run --rm \
		 --volume `pwd`:/home/flycheck-tester/flycheck \
		--name "FlycheckTesting" \
		--workdir /home/flycheck-tester/flycheck \
		--entrypoint "/bin/bash" \
		-it \
		flycheck-ci-env \
		/bin/bash -c ". ~/.bash_profile && make init check compile specs unit integ"
