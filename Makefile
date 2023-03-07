PYTHON_VERSION:=3.10

# NOTE: a Makefile will execute each line in a separate shell session. 
# Therefore, we'll create a helper alias to get 'conda activate' working.
SHELL = /bin/zsh
CONDA_ACTIVATE = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate

.PHONY: build
build:
	docker build --tag demo-image .

.PHONY: shell
shell:
	docker container run -it demo-image bash

# First-time generation of lockfiles from 'environment.yml' and 'pyproject.toml',
# if needed, so that the image build can succeed. Requires Conda. 
.PHONY: env-bootstrap
.ONESHELL:
env-bootstrap:
	conda create -p /tmp/bootstrap -c conda-forge \
		mamba conda-lock poetry='1.3' python=$(PYTHON_VERSION) -y
	$(CONDA_ACTIVATE) /tmp/bootstrap ; \
	conda-lock -k explicit --conda mamba ; \
	poetry update ; \
	conda deactivate ; \
	rm -rf /tmp/bootstrap

# Update the conda and poetry lockfiles based on the current 
# contents of 'environment.yml' and 'pyproject.toml'
.PHONY: env-update
env-update:
	chmod +x ./bin/env-update.sh
	docker container run -v $(PWD):/src/ demo-image conda run -n env --live-stream /src/bin/env-update.sh

# Prune untagged docker images
.PHONY: docker-prune
docker-prune:
	docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
