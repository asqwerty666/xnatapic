#!/bin/bash

ARGS=( "$@" )
HELP="prepare_fsqc - create the structure for Fresurfer QC with visualQC"
 
#local variables
PROJ_ID=""
OUTPUT_DIR=""
SBJ_ID=""
 
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
 --subject_id <subject id> [optional] define if just one subject wanted
 --outdir <output directory> [defaults to <project id>_fsresults]
 --list <list of downloaded experiments> [defaults to <project id>_experiments.list]
.EOF
			exit 0
			;;
		--project_id)
			let n=n+1
			PROJ_ID="${ARGS[$n]}"
			;;
		--subject_id)
			let n=n+1
			SBJ_ID="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
			;;
		--outdir)
			let n=n+1
			OUTPUT_DIR="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
			;;
		--list)
			let n=n+1
			OUTPUT_LIST="$(echo "${ARGS[$n]}" | sed 's/[ \n\r\t]\+/+/g')"
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
[ -z "$OUTPUT_DIR" ] && OUTPUT_DIR="${PROJ_ID}_fsresults"
[ -z "$OUTPUT_LIST" ] && OUTPUT_LIST="${PROJ_ID}_experiments.list"
#prepare
[ ! -d $OUTPUT_DIR ] && mkdir $OUTPUT_DIR
if [ -f $OUTPUT_LIST ] && [ -z $SBJ_ID ]; then rm -rf $OUTPUT_LIST; fi
TEMP_ELIST=$(mktemp -t fsqc.XXXXXXXX)
#run
if [ -z "$SBJ_ID" ]; then 
	if ! curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/experiments?xsiType=xnat:mrSessionData" 2>/dev/null | jq '.' > $TEMP_ELIST ; then
		echo "Error: server reported an error" >&2
		exit 1;
	else
		TOTAL=$(cat $TEMP_ELIST | jq '.ResultSet.totalRecords' | sed 's/"//g')
		let TOTAL=TOTAL-1
		for SBJ in $(seq 0 $TOTAL); do 
			XEXP=$(cat $TEMP_ELIST | jq ".ResultSet.Result[$SBJ].ID" | sed 's/"//g')
			echo "Processing $XEXP ... ($(($SBJ+1))/$(($TOTAL+1)))"
			FSR=`curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/experiments/$XEXP/files" 2>/dev/null | jq '.ResultSet.Result[].URI' | grep "\.tar\.gz" | sed 's/"//g'`
			if [ $FSR ]; then
				echo "$XEXP" >> $OUTPUT_LIST
				[ ! -d $OUTPUT_DIR/$XEXP ] && mkdir $OUTPUT_DIR/$XEXP
				TEMP_TAR=$(mktemp -t fsdir.XXXXXXXX.tar.gz)
				curl -f -X GET -u "$USER:$PASSWORD" "$HOST$FSR" -o $TEMP_TAR 2>/dev/null
				#tar xzf $TEMP_TAR --strip-components=1 -C $OUTPUT_DIR/$XEXP
				tar xzf $TEMP_TAR --strip-components=1 -C $OUTPUT_DIR/$XEXP */mri/{orig,aparc+aseg}.mgz */label/*.aparc.annot */surf/*.pial* */stats/*.aparc.stats
				rm $TEMP_TAR
			fi
		done	
	fi
else
	XEXP=`curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/subjects/$SBJ_ID/experiments?xsiType=xnat:mrSessionData" 2>/dev/null | jq '.ResultSet.Result[].ID' | sed 's/"//g'` 
	if [ ! "$XEXP" ]; then
		echo "Error: server reported an error" >&2
		exit 1;
	else
		FSR=`curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/experiments/$XEXP/files" 2>/dev/null | jq '.ResultSet.Result[].URI' | grep "\.tar\.gz" | sed 's/"//g'`
		if [ $FSR ]; then
			echo "$XEXP" >> $OUTPUT_LIST
			[ ! -d $OUTPUT_DIR/$XEXP ] && mkdir $OUTPUT_DIR/$XEXP
			TEMP_TAR=$(mktemp -t fsdir.XXXXXXXX.tar.gz)
			curl -f -X GET -u "$USER:$PASSWORD" "$HOST$FSR" -o $TEMP_TAR 2>/dev/null
			tar xzf $TEMP_TAR --strip-components=1 -C $OUTPUT_DIR/$XEXP */mri/{orig,aparc+aseg}.mgz */label/*.aparc.annot */surf/*.pial* */stats/*.aparc.stats
			rm $TEMP_TAR
		fi
	fi

fi
rm $TEMP_ELIST
#echo "So long, and thanks for all the fish!"
