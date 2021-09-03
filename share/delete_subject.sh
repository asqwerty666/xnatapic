#!/bin/bash

ARGS=( "$@" )
HELP="delete_subject - delete a subject in a project"

#local variables

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#parse arguments
PROJ_ID=""
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
 --project_id: subject's project
 --subject_id: subject's ID
 --label: subject's label
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
	--label)
		let n=n+1
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
SBJ=""
if [ -z "$SUBJECT_ID" ] ; then
	if [ -z "$PROJ_ID" ] ; then
		echo "Error: project_id is required if no subject_id is given" >&2
		exit 1
	else
		SBJ="$LABEL"
	fi
else
	SBJ="$SUBJECT_ID"
fi

if [ -z "$SBJ" ] ; then
	echo "Error: subject ID or label are required" >&2
	exit 1
fi

#run
if [ -z "$PROJ_ID" ] ; then
	if ! curl -f -X DELETE -u "$USER:$PASSWORD" "$HOST/data/subjects/$SBJ" >/dev/null 2>/dev/null ; then
		echo "Error: invalid request" >&2
		exit 1
	fi
else
	if ! curl -f -X DELETE -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SBJ" >/dev/null 2>/dev/null ; then
		echo "Error: invalid request" >&2
		exit 1
	fi
fi


#clean up

