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

# check node
command -v node &> /dev/null || die "node not installed"

# get project info: name, branch, remote, current version
project=$(node -p "require('./package.json').name" 2>/dev/null || die "Cannot read package.json")
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || die "Not a git repository")
remote=$(git remote | head -n 1)
current_version=$(node -p "require('./package.json').version" 2>/dev/null || die "Cannot read version")

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

# update version in package.json
echo "Updating version..."
node -e "const fs = require('fs'); const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8')); pkg.version = '$new_version'; fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');"

# commit changes
git add package.json
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
