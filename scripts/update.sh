# GitHub's "latest" release is unusable here: the repo also publishes SDK
# releases such as @kitlangton/hex@0.3.1. Only stable vX.Y.Z tags with a macOS
# zip count.
auth=()
if [[ -n ${GITHUB_TOKEN:-} ]]; then
  auth=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi

release=$(
  curl --fail --silent --show-error --location "${auth[@]}" \
    'https://api.github.com/repos/anomalyco/hex/releases?per_page=100' |
    jq --exit-status '
      [
        .[]
        | select((.draft or .prerelease | not) and (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$")))
        | (.tag_name | ltrimstr("v")) as $version
        | {
            version: $version,
            digest: (.assets[] | select(.name == "Hex-\($version)-macos-arm64.zip") | .digest)
          }
      ]
      | max_by(.version | split(".") | map(tonumber))
    '
)

version=$(jq --exit-status --raw-output .version <<<"$release")
digest=$(jq --exit-status --raw-output '.digest | ltrimstr("sha256:")' <<<"$release")
hash=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$digest")

jq --null-input --arg version "$version" --arg hash "$hash" \
  '{ version: $version, hash: $hash }' >version.json

echo "Pinned Hex $version ($hash)"
