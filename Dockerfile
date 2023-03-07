# ==========================
# Conda Environment Creation
# ==========================
# NOTES: 
# - Instruction set is ARM for Apple M1 chips; otherwise AMD. 
# - Small Conda image tips: https://jcristharif.com/conda-docker-tips.html 
# - To remove untagged images: docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force

FROM continuumio/miniconda3:4.10.3-alpine as builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create target environment
RUN conda install --channel=conda-forge --name=base nomkl conda-lock==1.4.0
COPY ["./conda-linux-64.lock", "./poetry.lock", "./pyproject.toml", "./"]
RUN conda create -n env --file conda-linux-64.lock && conda clean -afy

# Initialize Conda so we can activate environments
# (--login ensures both ~/.profile and ~/.bashrc are sourced)
SHELL [ "/bin/bash", "--login", "-c" ]
RUN conda init bash

# Install runtime dependencies
RUN conda activate env && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-root

# =============================
# Dev/Runtime Shared Base Image
# =============================
FROM bitnami/minideb:bullseye-snapshot-20220620T152414Z-amd64 as python_base

# Copy over the pre-built Conda environment
ENV CONDA_DIR="/opt/conda"
COPY --from=builder ${CONDA_DIR} ${CONDA_DIR}

# === Make it easier to work with Conda ===
# ENV EXECUTABLES_DIR="${CONDA_DIR}/envs/env/bin/"
SHELL [ "/bin/bash", "--login", "-c" ]

# NOTE: The following adds Conda and to PATH for both login and
# interactive shells, and that this env is active by default 
# for interactive sessions. 
ENV PATH $CONDA_DIR/bin:$PATH
RUN export PATH="$CONDA_DIR/bin:$PATH" && \
    echo "export PATH='$CONDA_DIR/bin:$PATH'" >> /root/.bashrc && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /root/.profile && \
    conda init bash && \
    echo "source activate env" >> /root/.bashrc

# make a directory for mounts
RUN mkdir src/
WORKDIR /src/


# ================
# Development Image
# ================
# Makes a few modifications on top of the runtime image
# to set up the development environment. 
FROM python_base as dev

# Install all poetry deps, to add the missing dev ones.
COPY ["./poetry.lock", "./pyproject.toml", "/src/"]
RUN poetry install --no-root
