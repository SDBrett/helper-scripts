#!/bin/bash
source git-diff.config

function echoerr() { echo "$@" 1>&2; }

# Parse inputs to key value pairs
function parse_inputs(){
    for ARGUMENT in "$@"; do
        KEY=$(echo $ARGUMENT | cut -f1 -d=  | tr '[:lower:]' '[:upper:]')
        KEY_LENGTH=${#KEY}
        VALUE="${ARGUMENT:$KEY_LENGTH+1}"
        export "$KEY"="$VALUE"
    done
}

parse_inputs $@

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
MERGE_BRANCH=$SOURCE_ENV-$CURRENT_ENV-merge-$(date +%s) 

echo "Testing if git remote for $SOURCE_ENV repo is configured"
if git remote show $SOURCE_ENV >/dev/null 2>&1
    then
        echo "Found git remote configuration for $SOURCE_ENV repo"
    else
        echo "Git configuration for $SOURCE_ENV not found, attempting to add"
        git remote add $SOURCE_ENV $SOURCE_REPO
fi

echo "Updating git repos"
git remote update
git pull origin main --rebase

echo "Merger branch name: $MERGE_BRANCH"
git checkout -b $MERGE_BRANCH
git diff $MERGE_BRANCH $SOURCE_ENV/main -- . $(echo $EXCLUDED_FILES) > diff.patch

echo "Patch file generated"
if [[ $AUTOPATCH = "yes" ]]; then
    patch --remove-empty-files -p1 < diff.patch
    echo "Patch applied"
fi

echo "Exiting"