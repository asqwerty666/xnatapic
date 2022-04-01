#!/bin/bash

ARGS=( "$@" )
HELP="delete_project - delete a project owned by the user"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""

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
 --project_id: project to be deleted
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
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

#run
if curl -f -X DELETE -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID" 2>/dev/null ; then
	echo "Project $PROJ_ID deleted from server" >&2
else
	echo "Error: invalid response from server" >&2
fi

#clean up

