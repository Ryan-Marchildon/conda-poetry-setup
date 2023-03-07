References:

# Conda+Poetry Package Management Demo

This demo provides a starting template for using `conda` + `poetry` together in containerized Python projects. 

Specifically, we use Conda for environment management, and Poetry for dependency management, except in cases where a specific dependency **must** be installed through Conda. 

Where possible we follow the "docker-is-the-only-local-dependency" philosophy, to make developer setup as seamless as possible. As is standard, we use [`GNU make`](https://www.gnu.org/software/make/manual/make.html) to automate routine dev commands. 


## Why use Conda + Poetry?

Here is our justification for approaching package management this way:

- Pip does not provide robust dependency resolution and dependency removal. Poetry and Conda have much better built-in dependency resolvers. 

- Some important data science libraries (like `tensorflow`, especially when CUDA-enabled) are best installed through Conda. 

- Some python packages are not available through Conda channels yet, so we'd still have to install them with pip (and suffer the aforementioned dependency resolution issues), unless we used poetry. 

- Conda and poetry both support lock files. As described [here](https://pythonspeed.com/articles/conda-dependency-management/), this gives you the flexibility of easier dependency upgrades while also ensuring reproducible builds that are fast because the environments were already solved upfront. Lock files bring us closer to the approach used by successful package managers from other languages (e.g. like `yarn` for JavaScript). 

- Poetry provides a cleaner way for defining a python package and its dependencies in one place (i.e. in `pyproject.toml`, instead of a separate `setup.py` and `requirements.txt`). 

- Poetry allows you to cleanly separate and manage production and development dependencies in a single file. This in turn makes it easier to remove unnecessary dependencies during deployment to shrink image sizes. 

## Usage

### Quickstart 

- Build the demo image using `make build`. 

- Modify the dependencies in the `environment.yml` and `pyproject.toml` files. 

- Run `make env-update` to update the lockfiles. 

- Run `make build` to rebuild the image with the new dependencies. 

- Run `make shell` to enter an interactive container. 

> 📝  Note, the image build requires the lock files to already exist. If you are starting a new project and must generate lock files for the first time, first create a lean version of `environment.yml` and `pyproject.toml`, and then run `make env-bootstrap`. In this exceptional case, you will need a local installation of `conda`. 

### Requirements

* A local [Docker](https://docs.docker.com/get-docker/) installation
* `GNU make` (Windows users must enable [WSL](https://learn.microsoft.com/en-us/windows/wsl/about))

### Updating Libraries

If you have made changes to the dependencies in `environment.yml` and/or `pyproject.toml`, run `make env-update` to update the lock files. 

Note that any dependencies specified in the Conda `environment.yml` file will be passed onto Poetry for locking, prior to the locking of other dependencies. This is so that Conda gets the final say on which versions of those dependencies are used.


### Installing Libraries

Installation is automated for you during the container image build. 

Installs outside of docker are discouraged. But given a conda lock file for the target OS (e.g. `conda-linux-64.lock`) and a `poetry.lock` file, you could set up a new local environment as follows:

```bash
conda create -n env --file conda-linux-64.lock
conda activate env
poetry install
```

If the lockfiles are updated and you wanted to update this same environment, the commands would be:

```bash
mamba update --file conda-linux-64.lock
poetry update
```
