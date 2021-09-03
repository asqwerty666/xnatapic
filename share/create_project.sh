#!/bin/bash

ARGS=( "$@" )
HELP="create_project - create a Xnat project"

#local variables
PROJ_ID=""
PROJ_NAME=""
PROJ_DESC=""
PROJ_PI=""
PROJ_KEYS=""
PROJ_ACCESS=""

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

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
 --name <project name> [defaults to <project id>
 --desc <project description> [defaults to <project id>]
 --PI <apellidos,nombre>
 --keywords <key,key,key>
 --access <private,public,protected> [defaults to protected]
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
		;;
	--name)
		let n=n+1
		PROJ_NAME="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
		;;
	--desc)
		let n=n+1
		PROJ_DESC="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
		;;
	--PI)
		let n=n+1
		PROJ_PI="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
		;;
	--keywords)
		let n=n+1
		PROJ_KEYS="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
		;;
	--access) #undocumented option!
		let n=n+1
		PROJ_ACCESS="$(echo "${ARGS[$n]}" | sed 's/^[pP][rR][iI].*$/private/' | sed 's/^[pP][rR][oO].*$/protected/' | sed 's/^[pP][uU].*$/public/')"
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
if [ -z "$PROJ_ID" ]; then
	echo "Error: a project ID is required" >&2
	exit 1
fi
if [ -z "$PROJ_PI" ] && ! [ -z "$USERNAME" ] ; then
	PROJ_PI="$USERNAME"
fi
if ! [ -z "$PROJ_PI" ] ; then
	PROJ_PI_L="$( echo "$PROJ_PI" | sed 's/ *,.*$//' | sed 's/[ \t\r]\+/+/g')"
	PROJ_PI_F="$( echo "$PROJ_PI" | sed 's/^.*, *//' | sed 's/[ \t\r]\+/+/g')"
	PROJ_PI="&pi_firstname=$PROJ_PI_F&pi_lastname=$PROJ_PI_L"
fi
if ! [ -z "$PROJ_NAME" ] ; then
	PROJ_KEYS="&name=$PROJ_NAME"
fi
if ! [ -z "$PROJ_DESC" ] ; then
	PROJ_KEYS="&description=$PROJ_DESC"
fi
if ! [ -z "$PROJ_KEYS" ] ; then
	PROJ_KEYS="&keywords=$PROJ_KEYS"
fi

#run
if ! curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID?u=u$PROJ_NAME$PROJ_DESC$PROJ_PI$PROJ_KEYS" ; then
	echo "Error: server reported an error" >&2
	exit 1
fi
if ! [ -z "$PROJ_ACCESS" ] ; then
	if ! curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/accessibility/$PROJ_ACCESS" ; then
		echo "Error: server reported an error while changing accessibility" >&2
		exit 1
	fi
fi
