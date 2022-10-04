#!/bin/bash

previous=$( git describe --abbrev=0 --tags --exclude="$(git describe --abbrev=0 --tags)" )
current=$( git describe --tags --always --abbrev=0 )

date=$( git log -1 --date=short --format="%ad" )
url=$( git remote get-url origin | sed -e 's/^git@\(.*\):/https:\/\/\1\//' -e 's/\.git$//' )

commitsFromMe=$( git log --pretty=format:"- %s" --no-merges --author="$(git config user.name)" $previous..$current )
commitsFromOthers=$( git log --pretty=format:"- %s (thanks %aN)" --no-merges --author="^(?!$(git config user.name)).*$" --perl-regexp $previous..$current )

echo -ne "$commitsFromMe \n $commitsFromOthers" > "CHANGELOG.md"
echo -e "[${current}](${url}/tree/${current}) ($date)\n\n[Full Changelog](${url}/compare/${previous}...${current})\n\n$(sort -u "CHANGELOG.md")" > "CHANGELOG.md"
