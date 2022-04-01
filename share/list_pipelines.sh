#!/bin/bash

ARGS=( "$@" )
HELP="list_pipelines - list pipelines in a project"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
PIPE_AVAILABLES=""

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
 --project_id <project id>: project
 --available: show available (i.e. not active) pipelines
 --path: show path
 --description: show description
 --applies-to: show what data the pipeline is applied to
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
		;;
	--available)
		SHOW_AVAILABLE="${ARGS[$n]}"
		;;
	--path)
		SHOW_PATH="${ARGS[$n]}"
		;;
	--description)
		SHOW_DESCRIPTION="${ARGS[$n]}"
		;;
	--applies-to)
		SHOW_APPLIES="${ARGS[$n]}"
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
if [ -z "$PROJ_ID" ] ; then
	echo "Error: project_id is required" >&2
	exit 1
fi
[ -z "$SHOW_AVAILABLE" ] || SHOW_AVAILABLE="&additional=true"

#run
TMP_RESULTS=$(mktemp)

if curl -X GET -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/pipelines?format=json$SHOW_AVAILABLE" -o $TMP_RESULTS 2>/dev/null ; then
	PTH=""
	PNM=""
	PDS=""
	PAT=""
	cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
	grep '^.\+:.\+$' | sed 's/ *: */=/' | sed 's/\\//g' |\
	while read l ; do
		K="$(echo "$l" | sed 's/=.*$//')"
		V="$(echo "$l" | sed 's/^.*=//')"
		case "$K" in
			Datatype)
				printf "$PNM"
				[ -z "$SHOW_DESCRIPTION" ] || printf ",$PDS"
				[ -z "$SHOW_PATH" ] || printf ",$PTH"
				[ -z "$SHOW_APPLIES"  ] || printf ",$PAT"
				printf "\n"
				PTH=""
				PNM=""
				PDS=""
				PAT=""
			;;
			Path) PTH="$V"
			;;
			Description) PDS="$V"
			;;
			Name) PNM="$V"
			;;
			"Applies To") PAT="$V"
			;;
		esac
	done
else
	echo "Error: no valid response from server" >&2
	exit 1
fi

#clean up
rm -f $TMP_RESULTS

