#!/bin/bash

ARGS=( "$@" )
HELP="delete_experiment - delete an experiment"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
SUBJECT_ID=""
EXPERIMENT_ID=""

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
 --subject_id <subject ID> [mandatory]
 --experiment_id <experiment ID> [mandatory]
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
		;;
	--subject_id)
		let n=n+1
		SUBJECT_ID="${ARGS[$n]}"
		;;
	--experiment_id)
		let n=n+1
		EXPERIMENT_ID="${ARGS[$n]}"
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
if [ -z "$PROJ_ID" ] || [ -z "$SUBJECT_ID" ] || [ -z "$EXPERIMENT_ID" ] ; then
	echo "Error: project, subject and experiment IDs are required" >&2
	exit 1
fi

#run
echo curl -f -X DELETE -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SUBJECT_ID/experiments/$EXPERIMENT_ID"
if ! curl -f -X DELETE -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SUBJECT_ID/experiments/$EXPERIMENT_ID" 2>/dev/null >/dev/null ; then
	echo "Error: server reported an error" >&2 
	exit 1
fi
