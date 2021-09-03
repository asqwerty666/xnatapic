#!/bin/bash

ARGS=( "$@" )
HELP="delete_pipeline - delete a pipeline from a project (UNDOCUMENTED)"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
PIPELINE=""

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
 --project_id <project id> [mandatory]
 --pipeline <pipeline name> [mandatory]

 WARNING: this command uses an undocumented API call.
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
		;;
	--pipeline)
		let n=n+1
		PIPELINE="${ARGS[$n]}"
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
if [ -z "$PROJ_ID" ] || [ -z "$PIPELINE" ] ; then
	echo "Error: project and pipeline are required" >&2
	exit 1
fi

#run
TMP_RESULTS=$(mktemp)

if curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/pipelines/$PIPELINE" 2>/dev/null >$TMP_RESULTS ; then
	PAT=""
	PTH=""
	
	cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
	sed 's/^items:$\|^end:$/items: /' |\
	grep '^.\+:.\+$' | sed 's/ *: */=/' |\
	while read l ; do
		K="$(echo "$l" | sed 's/=.*$//')"
		V="$(echo "$l" | sed 's/^.*=//')"
		case "$K" in
			path) PTH="$V"
				;;
			appliesTo)
				case "$V" in
					MR*) PAT="xnat:mrSessionData"
					;;
					CT*) PAT="xnat:ctSessionData"
					;;
					PET*) PAT="xnat:petSessionData"
					;;
					*) echo "Error: unknown data type" >&2 && exit 1
					;;
				esac
				;;
		esac
		
		if ! [ -z "$PTH" ] && ! [ -z "$PAT" ] ; then
			if curl -f -X DELETE -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/pipelines?path=$PTH&datatype=$PAT" 2>/dev/null >/dev/null ; then
				break
			else
				echo "Error: could not delete pipeline at $PTH" >&2
				exit 1
			fi
		fi
		
	done
else
	echo "Error: server reported an error" >&2 
	exit 1
fi

#clean up
rm -f $TMP_RESULTS
