# GitHub's "latest" release is unusable here: the repo also publishes SDK
# releases such as @kitlangton/hex@0.3.1. Only stable vX.Y.Z tags count.
auth=()
if [[ -n ${GITHUB_TOKEN:-} ]]; then
  auth=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi

# Picks the newest tag first, so a release whose zip can't be found fails here
# instead of silently pinning an older one. Asset casing has changed upstream.
release=$(
  curl --fail --silent --show-error --location "${auth[@]}" \
    'https://api.github.com/repos/anomalyco/hex/releases?per_page=100' |
    jq --exit-status '
      [ .[] | select((.draft or .prerelease | not) and (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))) ]
      | max_by(.tag_name | ltrimstr("v") | split(".") | map(tonumber))
      | (.tag_name | ltrimstr("v")) as $version
      | .assets[]
      | select((.name | ascii_downcase) == "hex-\($version)-macos-arm64.zip")
      | { version: $version, asset: .name, digest: .digest }
    '
) || {
  echo "The newest Hex release has no macOS zip" >&2
  exit 1
}

version=$(jq --exit-status --raw-output .version <<<"$release")
asset=$(jq --exit-status --raw-output .asset <<<"$release")
digest=$(jq --exit-status --raw-output '.digest | ltrimstr("sha256:")' <<<"$release")
hash=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$digest")

jq --null-input --arg version "$version" --arg asset "$asset" --arg hash "$hash" \
  '{ version: $version, asset: $asset, hash: $hash }' >version.json

echo "Pinned Hex $version ($hash)"
