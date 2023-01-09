#!/usr/bin/env bash
# John Boero - use at your own risk!
# This is experimental and not without bugs.
# Create a bash function "jqr" that calls jq with query and file args reversed.
# This enables bash completion and browsing.
# Note this will not worth with flags/getopts and should not be used with production data.

function _jqr_completions()
{
	if [ "$3" == "jqr" ]; then
		COMPREPLY+=($(ls -d "$2"* 2>/dev/null))
		return
	fi

	# Try the current path as a query.
	path=$2
	q="$path|keys_unsorted|join(\" \")"
	keys=$(/usr/bin/jq -r "$q" "$3" 2>/dev/null)

	# If we have an exact match just list the keys.
	if [[ $keys == "null" ]] || [[ "$keys" == "" ]]; then
		filename="${path%.*}"
		filename="${filename:-.}"
		extension="${path##*.}"

		q="$filename|keys_unsorted|map(select(startswith(\"${extension}\")))|join(\" \")"
		keys=$(/usr/bin/jq -r "$q" "$3" 2>/dev/null)

		q="$filename|map(type)|join(\" \")"
		types=$(/usr/bin/jq -r "$q" "$3" 2>/dev/null)
	else
	# If we aren't an exact match find the closest options in our root.
		if [[ $path != *. ]]; then
			path="${path}."
		fi

		prefix=$path
		q="$path|map(type)|join(\" \")"
		types=$(/usr/bin/jq -r "$q" "$3" 2>/dev/null)
	fi

	# Now we should have approximate keys and types.
	keys=($keys)
	types=($types)

	for i in "${!keys[@]}"; do
		key="${keys[$i]}"
		type="${types[$i]}"

		# Arrays and objects get indicative suffixes.
		case $type in
			array)
				key="${key}[0]"
			;;
			object)
				key="${key}."
			;;
		esac
		rep="$prefix$key"
		COMPREPLY+=($rep)
	done
}

function jqr()
{
	a1=$1
	shift
	a2=$1
	shift

	jq $a2 $a1 $@ 2>/dev/null
}

complete -F _jqr_completions jqr
