#!/bin/bash

set -xeuo pipefail

DEST=build
RELEASES_URL="https://api.github.com/repos/$PACKAGE/releases?per_page=1"

mkdir $DEST

get_releases() {
  curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    "$RELEASES_URL"
}

download_bin () {
  get_releases \
    | jq -r '
        .[0].assets[]
          | select(.name | index("linux-x86_64"))
          | .browser_download_url
      ' \
    | xargs curl -sL \
    | tar zx
}

for N in {1..10}
do
  if download_bin
  then
    break;
  fi

  sleep 1m

  # Print response from the GitHub API before retry.
  get_releases
done

time ./releasesfeed > $DEST/feed.xml

git add $DEST
TREE=$(git write-tree --prefix=$DEST)

COMMIT=$(git -c user.name=bot \
             -c user.email=bot@actions \
             commit-tree -m "Update feed" "$TREE")

git push -f origin "$COMMIT":refs/heads/gh-pages
