#!/bin/bash

set -e

# github_latest_release $repo $regex
github_latest_release() {
    local repo="$1"
    local regex="$2"
    local include_prerelease="${3:-false}"

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required" >&2
        return 1
    fi

    local url="https://api.github.com/repos/${repo}/releases"

    local jq_filter
    if [[ "$include_prerelease" == "true" ]]; then
        jq_filter="[ .[] | select(.tag_name | test(\$re)) ][0].tag_name"
    else
        jq_filter="[ .[] | select(.prerelease == false) | select(.tag_name | test(\$re)) ][0].tag_name"
    fi

    local tag
    tag=$(curl -s "$url" | jq -r --arg re "$regex" "$jq_filter")

    if [[ "$tag" == "null" || -z "$tag" ]]; then
        echo "No matching release found for $repo with regex $regex" >&2
        return 1
    fi

    echo "$tag"
}

version=$(github_latest_release "zhboner/realm" '^v.+$')
echo -n $version
