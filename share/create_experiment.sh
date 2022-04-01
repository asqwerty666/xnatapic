#!/bin/bash

ARGS=( "$@" )
HELP="create_experiment - create an experiment and set its attributes"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
SUBJECT_ID=""
EXPERIMENT_ID=""
TYPE=""
DATE=""
LABEL=""

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
 --type <MR,PET> [mandatory]
 --date <dd/mm/yyyy or yyyymmdd>
 --label <label>
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
	--type)
		let n=n+1
		case "${ARGS[$n]}" in
			mr|MR)	TYPE="xnat:mrSessionData"
			;;
			pet|PET) TYPE="xnat:petSessionData"
			;;
			*) echo "Error: unknown experiment type ${ARGS[$n]}" >&2 && exit 1
			;;
		esac
		;;
	--date)
		let n=n+1
		DATE="$( echo "${ARGS[$n]}" | sed 's/ \+//g' | sed 's/-/\//g' )"
		;;
	--label)
		let n=n+1
		LABEL="$( echo "${ARGS[$n]}" | sed 's/ \+/+/g' )"
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
if [ -z "$TYPE" ] ; then
	echo "Error: experiment type is required" >&2
	exit 1
else
	TYPE="xsiType=$TYPE"
fi
[ -z "$DATE" ] || DATE="&date=$DATE"
[ -z "$LABEL" ] || LABEL="&label=$LABEL"
[ -z "$MODALITY" ] || MODALITY="&modality=$MODALITY"

if ! curl -f -X PUT -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/subjects/$SUBJECT_ID/experiments/$EXPERIMENT_ID/?$TYPE$DATE$LABEL$MODALITY" 2>/dev/null >/dev/null ; then
	echo "Error: server reported an error" >&2 
	exit 1
fi
