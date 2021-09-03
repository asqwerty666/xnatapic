#!/bin/bash

ARGS=( "$@" )
HELP="create_subject - create a subject in a project"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
SUBJECT_ID=""
LABEL=""
GENDER=""
HANDEDNESS=""
DATEOFBIRTH=""

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
 --subject_id <subject ID> [mandatory either this or a label]
 --label <label>
 --gender <male,female>
 --handedness <right,left,ambidextrous,unknown>
 --age <YY>
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
	--gender)
		let n=n+1
		GENDER=$(echo "${ARGS[$n]}" | sed 's/^[fF].*$/female/' | sed 's/^[mM].*$/male/' | sed 's/^[uU].*$/unknown/')
		;;
	--handedness)
		let n=n+1
		HANDEDNESS=$(echo "${ARGS[$n]}" | sed 's/^[rR].*$/right/' | sed 's/^[lL].*$/left/' | sed 's/^[aA].*$/ambidextrous/' | sed 's/^[uU].*$/unknown/')
		;;
	--age)
		let n=n+1
		AGE="${ARGS[$n]}"
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

U="u=u"
[ -z "$LABEL" ] || LABEL="&label=$LABEL"
[ -z "$GENDER" ] || GENDER="&gender=$GENDER"
[ -z "$HANDEDNESS" ] || HANDEDNESS="&handedness=$HANDEDNESS"
if ! [ -z "$AGE" ] ; then
	let YOB=$(date +%Y)-$AGE
	YOB="&yob=$YOB"
fi

#run
#echo curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SBJ?$U$LABEL$GENDER$HANDEDNESS$YOB"
if [ -z "$PROJ_ID" ] ; then
	if ! curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/subjects/$SBJ?$U$LABEL$GENDER$HANDEDNESS$YOB" >/dev/null 2>/dev/null ; then
		echo "Error: server error" >&2
		exit 1
	fi
else
	if ! curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SBJ?$U$LABEL$GENDER$HANDEDNESS$YOB" >/dev/null 2>/dev/null ; then
		echo curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SBJ?$U$LABEL$GENDER$HANDEDNESS$YOB"
		echo "Error: server error" >&2
		exit 1
	fi
fi

