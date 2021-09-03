#!/bin/bash

ARGS=( "$@" )
HELP="list_subjects - list subjects in a project"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
SUBJECT_ID=""
DESCR=""

#parse arguments
for ((n=0; n<${#ARGS[@]}; n++)) ; do
	case "${ARGS[$n]}" in
	--help-short)
		echo "$HELP"
		exit 0
		;;
	--help) 
		echo "$HELP"
		cat <<.EOF
 --help: show this help
 --project_id: project
 --subject_id: show only this subject
 --label: show subject label
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJECT_ID="${ARGS[$n]}"
		;;
	--subject_id)
		let n=n+1
		SUBJECT_ID="${ARGS[$n]}"
		;;
	--label)
		LABEL="${ARGS[$n]}"
		;;
	-*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	esac
done

#checks
if [ -z "$PROJECT_ID" ] ; then
	echo "Error: project_id is required" >&2
	exit 1
fi

#run
TMP_RESULTS=$(mktemp)

if curl -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJECT_ID/subjects?format=json" -o $TMP_RESULTS 2>/dev/null ; then
	cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
	grep '^\(ID\|label\|URI\):.\+$' |\
	while read s ; do
		K="$(echo "$s" | sed 's/:.*$//')"
		V="$(echo "$s" | sed 's/^.*://')"
		case "$K" in
			URI)
				if ! ( [ -z "$SID" ] && [ -z "$SLB" ] ) ; then
					if [ -z "$SUBJECT_ID" ] || [ "$SUBJECT_ID" == "$SID" ] || [ "$SUBJECT_ID" == "$SLB" ]; then
						printf "$SID"
						[ -z "$LABEL" ] || printf ",$SLB"
						printf "\n"
					fi
				fi
				SID=""
				SLB=""
			;;
			ID) SID="$V"
			;;
			label) SLB="$V"
			;;
		esac
	done
else
	echo "Error: no valid response from server" >&2
	exit 1
fi

#clean up
rm -f $TMP_RESULTS

