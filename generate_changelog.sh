#!/bin/bash

previous=$( git describe --abbrev=0 --tags --exclude="$(git describe --abbrev=0 --tags)" )
current=$( git describe --tags --always --abbrev=0 )

date=$( git log -1 --date=short --format="%ad" )
url=$( git remote get-url origin | sed -e 's/^git@\(.*\):/https:\/\/\1\//' -e 's/\.git$//' )
commits=$( git log --pretty=format:"- "%s --no-merges --cherry-pick ${previous}...${current} )

echo -ne "$commits" > "CHANGELOG.md"
echo -e "[${current}](${url}/tree/${current}) ($date)\n\n[Full Changelog](${url}/compare/${previous}...${current})\n\n$(sort -u "CHANGELOG.md")" > "CHANGELOG.md"
