#!/bin/bash

ARGS=( "$@" )
HELP="get_fsqc - get the results of Fresurfer QC"
 
#local variables
PROJ_ID=""
OUTPUT=""
 
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
 --output <output directory> [defaults to <project id>_fsqc.csv]
.EOF
			exit 0
			;;
		--project_id)
			let n=n+1
			PROJ_ID="${ARGS[$n]}"
			;;
		--output)
			let n=n+1
			OUTPUT="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
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
#defaults
[ -z "$OUTPUT" ] && OUTPUT="${PROJ_ID}_fsqc.csv"
#prepare
if [ -f $OUTPUT ]; then rm -rf $OUTPUT; fi
TEMP_SLIST=$(mktemp -t xsbjs.XXXXXXXX)
#run
if ! curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects" 2>/dev/null | jq '.' > $TEMP_SLIST ; then
	echo "Error: server reported an error" >&2
	exit 1;
else
	TOTAL=$(cat $TEMP_SLIST | jq '.ResultSet.totalRecords' | sed 's/"//g')
	let TOTAL=TOTAL-1
	for SBJ in $(seq 0 $TOTAL); do 
		XSBJ=$(cat $TEMP_SLIST | jq ".ResultSet.Result[$SBJ].ID" | sed 's/"//g')
		XSBJ_LABEL=$(cat $TEMP_SLIST | jq ".ResultSet.Result[$SBJ].label" | sed 's/"//g')
		echo "Processing $XSBJ ... ($(($SBJ+1))/$(($TOTAL+1)))" 
		MRI=`curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$XSBJ/experiments?xsiType=xnat:mrSessionData" 2>/dev/null | jq '.ResultSet.Result[].ID' | sed 's/"//g'`
		if [ $MRI ]; then
			TEMP_FSQC=$(mktemp -t xfsqc.XXXXXXXX)
			if curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/experiments/$MRI/resources/fsqc/files/rating.json" 2>/dev/null | jq '.' > $TEMP_FSQC ; then
				XRAT=$(cat $TEMP_FSQC | jq '.ResultSet.Result[].rating')
				XNOTES=$(cat $TEMP_FSQC | jq '.ResultSet.Result[].notes')
				if [ ! -z "$XRAT" ]; then echo "$XSBJ_LABEL, $XRAT, $XNOTES" >> $OUTPUT; fi
			fi
			rm $TEMP_FSQC
		fi
	done
fi
rm $TEMP_SLIST
echo "Bye, check results at $OUTPUT"
