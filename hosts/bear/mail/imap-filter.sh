set -eu -o pipefail

account_name="$1"
orig_rcpt="$2"

if [[ "$account_name" != "janet@unspecified.systems" ]]; then
	# Exit printing nothing (and thus having no effect).
	exit 0
fi

parse_local_annotation() {
	declare address="$1"
	declare local_prefix="$2"
	declare domain="$3"

	declare removed_prefix="${address#"$local_prefix"}"

	if [[ "$removed_prefix" = "$address" ]]; then
		# No match.
		exit 1
	fi

	declare removed_suffix="${removed_prefix%"@$domain"}"

	if [[ "$removed_suffix" = "$removed_prefix" ]]; then
		# No match.
		exit 1
	fi

	printf '%s\n' "$removed_suffix"
}

capitalize_words() {
	# Split the argument by hyphens.
	declare -a parts
	IFS="-" read -r -a parts <<< "$1"

	declare IFS=" "
	printf "%s\n" "${parts[*]@u}"
}

parse_target_folder() {
	declare address="$1"

	# Apparently IMAP names nested folders using periods.

	if [[ "$address" =~ "accounts+"[^-@]+(-[^-@]+)+"@randomcat.org" ]]; then
		declare annotation
		annotation="$(parse_local_annotation "$address" "accounts+" "randomcat.org")"

		declare account_name
		account_name="$(printf '%s\n' "$annotation" | sed 's/-[^-]\+$//g')"

		if [[ "$account_name" != "" ]]; then
			printf "Accounts.%s\n" "$(capitalize_words "$account_name")"
			return 0
		fi
	fi

	if [[ "$address" =~ "lists+"[^@]+"@randomcat.org" ]]; then
		declare list_name
		list_name="$(parse_local_annotation "$address" "lists+" "randomcat.org")"

		# Special case capitalization.
		if [[ "$list_name" == "npr" ]]; then
			printf "Lists.NPR\n"
			return 0
		fi

		if [[ "$list_name" != "" ]]; then
			printf "Lists.%s\n" "$(capitalize_words "$list_name")"
			return 0
		fi
	fi

	# Otherwise, output nothing (indicating that the destination should not be changed).
}

printf "%s\n" "$(parse_target_folder "$orig_rcpt")"
