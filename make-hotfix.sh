#!/bin/bash -e

# print error and exit
die() {
    echo "ERROR: $@" >&2
    exit 1
}

# check that we have one argument
[ $# -ne 1 ] && die "Usage: $0 <suffix>\nExample: $0 scrXXXXXX"

# check that suffix is valid
suffix="$1"
[[ ! "$suffix" =~ ^[a-zA-Z0-9_-]+$ ]] && die "Invalid suffix, use only letters, numbers, - and _"

# check that we are on master
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || die "Not a git repository")
remote=$(git remote | head -n 1)

# check that we are on master
if git show-ref --verify --quiet refs/heads/master; then
    default_branch="master"
else
    die "Cannot find master branch"
fi

# print info
echo "Branch: $branch"
echo "Suffix: $suffix"
echo ""

# check that we are on master
[ "$branch" != "$default_branch" ] && die "Must run from $default_branch branch"

# pull latest changes
echo "Pulling latest..."
[ -n "$remote" ] && git pull "$remote" "$default_branch"

# set hotfix branch name
date_stamp=$(date +%Y%m%d)
hotfix_branch="hotfix-${date_stamp}-${suffix}"

# check that hotfix branch does not exist
git rev-parse --verify "$hotfix_branch" &>/dev/null && die "Branch $hotfix_branch already exists"

# create hotfix branch
echo "Creating $hotfix_branch..."
git checkout -b "$hotfix_branch"

# print done message and manual steps
echo ""
echo "Done! Next manual steps:"
echo ""
echo "1. Cherry-pick commits (example: git cherry-pick <commit-hash>)"
echo "2. Push to remote (example: git push $remote $hotfix_branch)"
echo "3. Create MR to master"
echo "4. Merge MR to master"
echo "5. Run build" 
