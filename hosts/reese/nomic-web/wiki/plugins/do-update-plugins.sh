#!/usr/bin/env bash

set -eu -o pipefail

# This isn't documented and may theoretically not be stable, but we should fail
# loudly if it changes, and it seems unlikely to change very often.
plugins_index="https://extdist.wmflabs.org/dist/extensions/"

cd -- "$(dirname -- "$BASH_SOURCE")"

mw_raw_version="$(nix eval --raw .#nixosConfigurations.reese.config.services.mediawiki.package.version)"

if ! [[ "$mw_raw_version" =~ ^.+\..*\..+$ ]]; then
	{
		echo "Unexpected MediaWiki version: $mw_raw_version"
		echo "Expected a.b.c"
	} > /dev/stderr

	exit 1
fi


mw_release="$(printf '%s\n' "$mw_raw_version" | sed -E 's/^(.+)\.(.+)\.(.+)$/REL\1_\2/')"

{
	echo "Raw version: $mw_raw_version"
	echo "Release: $mw_release"
} > /dev/stderr

work="$(mktemp -d)"

cleanup() {
	rm -rf -- "$work"
}

trap cleanup EXIT

curl -- "$plugins_index" \
	| htmlq --base "$plugins_index" --attribute href a \
	> "$work/plugin-urls"

# We will use jq to build a json object and build the arguments in this array.
jq_args=()

ia_snapshot_to_raw() {
	printf '%s\n' "$1" | sed -E 's/\/web\/([0-9]+)\//\/web\/\1if_\//'
}

while read -r plugin_name; do
	echo "Plugin: $plugin_name" > /dev/stderr

	plugin_url="$(cat -- "$work/plugin-urls" | grep -F -- "extensions/${plugin_name}-${mw_release}")"

	if [[ "$(printf '%s\n' "$plugin_url" | wc -l)" != "1" ]]; then
		echo "Found unexpected plugin urls:" > /dev/stderr
		printf '%s\n' "$plugin_url"
	fi

	existing_url="$(curl 'http://archive.org/wayback/available' -G --data "url=$plugin_url" | jq -r '.archived_snapshots.closest.url // empty')"

	if [[ "$existing_url" ]]; then
		effective_url="$(ia_snapshot_to_raw "$existing_url")"
	else
		# Since this URL is not guaranteed to be stable, try to archive it with the
		# Internet Archive and use a snapshot URL. If this doesn't work, fall back
		# to just using the original URL.
		# 
		# We add if_ after the IA snapshot timestamp because this tells IA to just
		# give us the raw file. (I do not know if or where this is documented, but
		# it works.)
		effective_url="$(ia_snapshot_to_raw "$(savepagenow -c "$plugin_url")")" \
			|| effective_url="$plugin_url"

	fi

	prefetch_hash="$(nix store prefetch-file --unpack --json -- "$plugin_url" | jq -r '.hash')"

	{
		echo "Raw URL: $plugin_url"
		echo "Effective URL: $effective_url"
		echo "Hash: $prefetch_hash"
	} > /dev/stderr

	jq_args+=(--argjson "$plugin_name" "$(jq -n '$ARGS.named' --arg 'url' "$effective_url" --arg 'hash' "$prefetch_hash")")
done < ./plugin-names.txt

mkdir -p data
jq -n '$ARGS.named' "${jq_args[@]}" > "data/plugins-${mw_release}.json"
