#!/bin/bash
#
# This script updates the conda and poetry lock files
# based on the most recent versions of 'environment.yml'
# and 'pyproject.toml'.

# Ensure any failing statement causes the whole script to fail.
set -e

# Ensures these executables are present.
conda --version
yq --version
poetry --version

# =================
# (1) Update poetry lock and 'pyproject.toml' based on 'environment.yml'
# =================
echo "Updating poetry lock and 'pyproject.toml' based on 'environment.yml'..."
# Get all dependencies specified in the conda env file
DEPENDENCIES=($(yq -r .dependencies environment.yml | tr -d '[],'))

# Filter this to include only the deps of relevance to poetry. 
# We exclude those in the "OMIT_LIST" because they are unnecessary. 
OMIT_LIST=("python" "pip" "poetry" "mamba" "conda-pack")

for target in "${OMIT_LIST[@]}"; do
    for i in "${!DEPENDENCIES[@]}"; do
        if [[ ${DEPENDENCIES[i]} == \"$target* ]]; then
            unset 'DEPENDENCIES[i]'
        fi
    done
done

# Apply as locks to poetry, to ensure conda has the final say
# on the versions of these dependencies.
echo "Applying poetry locks for the following deps: ${DEPENDENCIES[@]}"
for index in "${!DEPENDENCIES[@]}"; do
    poetry add --lock ${DEPENDENCIES[index]//\"/}
done

# =================
# (2) Update conda lock file based on 'environment.yml'
# =================
echo "Updating conda lock file based on 'environment.yml'..."
conda-lock -k explicit --conda mamba

# =================
# (3) Further update poetry lock file based on 'pyproject.toml'
# =================
echo "Updating poetry lock file based on 'pyproject.toml'..."
poetry update

echo "SUCCESS: Lockfile and 'pyproject.toml' updates complete!"