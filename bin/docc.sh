#!/bin/bash

export BUILDING_FOR_DOCUMENTATION_GENERATION=1

set -eu

# A `realpath` alternative using the default C implementation.
filepath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

ROOT="$(dirname $(dirname $(filepath $0)))"
TARGET="CoreDataPlus"
HOSTING_BASE_PATH="CoreDataPlus"
# Set current directory to the repository root
cd "$ROOT"

# Use git worktree to checkout the gh-pages branch of this repository in a gh-pages sub-directory
git fetch
git worktree add --checkout gh-pages origin/gh-pages

# Pretty print DocC JSON output so that it can be consistently diffed between commits
export DOCC_JSON_PRETTYPRINT="YES"

# Generate documentation for the 'CoreDataPlus' target and output it
# to the /docs subdirectory in the gh-pages worktree directory.
swift package \
    --allow-writing-to-directory "$ROOT/gh-pages/docs" \
    generate-documentation \
    --target "$TARGET" \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path "$HOSTING_BASE_PATH" \
    --include-extended-types \
    --output-path "$ROOT/gh-pages/docs"

# Save the current commit we've just built documentation from in a variable
CURRENT_COMMIT_HASH=`git rev-parse --short HEAD`

# Commit and push our changes to the gh-pages branch
cd gh-pages
git add docs

if [ -n "$(git status --porcelain)" ]; then
    echo "Documentation changes found. Commiting the changes to the 'gh-pages' branch and pushing to origin."
    git commit -m "Update GitHub Pages documentation site to $CURRENT_COMMIT_HASH"
    git push origin HEAD:gh-pages
else
  # No changes found, nothing to commit.
  echo "No documentation changes found."
fi

# Delete the git worktree we created
cd ..
git worktree remove gh-pages