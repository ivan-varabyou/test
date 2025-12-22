#!/bin/bash -e

# print error and exit
die() {
    echo "ERROR: $@" >&2
    exit 1
}

# up minor version 1.2.3 -> 1.3.0
bump_minor() {
    IFS=. read major minor patch <<< "$1"
    echo "$major.$((minor+1)).0"
}

# check jq
command -v jq &> /dev/null || die "jq not installed"

# get project info: name, branch, remote, current version
project=$(jq -r .name < ./package.json 2>/dev/null || die "Cannot read package.json")
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || die "Not a git repository")
remote=$(git remote | head -n 1)
current_version=$(jq -r .version < ./package.json 2>/dev/null || die "Cannot read version")

# print project info
echo "Project: $project"
echo "Branch: $branch"
echo "Version: $current_version"
echo ""

# check if run from develop branch
[ "$branch" != "develop" ] && die "Must run from develop branch"

# pull latest changes
echo "Pulling latest changes..."
[ -n "$remote" ] && git pull "$remote" develop

# calculate new version
new_version=$(bump_minor "$current_version")
type="minor"

# set release branch name
release_branch="release-v${new_version}"

# print release info and ask for confirmation
echo ""
echo "Release: $type"
echo "Version: $current_version -> $new_version"
echo "Branch: $release_branch"
echo ""
read -p "Confirm? (y/n): " confirm
[ "$confirm" != "y" ] && die "Cancelled"

# check if release branch or tag already exists
git rev-parse --verify "$release_branch" &>/dev/null && die "Branch $release_branch already exists"
git rev-parse --verify "v${new_version}" &>/dev/null && die "Tag v${new_version} already exists"

# create release branch
echo "Creating branch $release_branch..."
git checkout -b "$release_branch"

# update version in package.json and package.ver
echo "Updating version..."
jq ".version = \"$new_version\"" package.json > package.json.tmp && mv package.json.tmp package.json
echo "$new_version" > package.ver

# commit changes
git add package.json package.ver
git commit -m "SCR #0 - $type: $release_branch"

# push release branch
echo "Pushing..."
[ -n "$remote" ] && git push "$remote" "$release_branch"

# print done message next steps
echo ""
echo "Done! Branch $release_branch created and pushed"
echo ""
echo "Manual steps:"
echo "1. Create MR to master and merge"
echo "2. Run build"
echo "3. [Optional] Add tag to master (only on master)"
echo "4. [Optional] Create MR master -> develop to sync them"
