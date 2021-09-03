#!/bin/bash

ARGS=( "$@" )
HELP="upload_fsqc - upload visualQC Freesurfer results"
 
#local variables
INPUT_DIR=""
 
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
 --qcdir <directory with visualQC results> [mandatory]
.EOF
			exit 0
			;;
		--qcdir)
			let n=n+1
			INPUT_DIR="${ARGS[$n]}"
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
if [ -z "$INPUT_DIR" ]; then
	echo "Error: input directory is required" >&2
	exit 1
fi
#input files and directories
IMG_DIR="$INPUT_DIR/annot_visualizations"
RATINGS0="$INPUT_DIR/ratings/cortical_contour_rate_freesurfer_orig.mgz_ratings.all.csv"
END=$(tail -c 1 $RATINGS0)
RATINGS=$(mktemp -t fsqc_ratings.XXXXXXXX)
cp $RATINGS0 $RATINGS
if [ "$END" != "" ]; then echo "" >> $RATINGS; fi
#run
while read LINE; do
	XEXP=$(echo $LINE | awk -F"," '{print $1}')
	QCR=$(echo $LINE | awk -F"," '{print $2}')
	NOTE=$(echo $LINE | awk -F"," '{print $3}' | sed 's/Notes://')
	RESULT="{\"ResultSet\":{\"Result\":[{\"rating\":\"$QCR\",\"notes\":\"$NOTE\"}]}}"
	TEMP_RESULT_FILE=$(mktemp -t fsqc_results.XXXXXXXX)
	echo $RESULT > $TEMP_RESULT_FILE
	curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/experiments/$XEXP/resources/fsqc" 2>/dev/null
	curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/experiments/$XEXP/resources/fsqc/files/rating.json?overwrite=true" -F file="@$TEMP_RESULT_FILE"
	for IMG in $IMG_DIR/$XEXP*.tif; do
		NAME=$(basename $IMG)
		curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/experiments/$XEXP/resources/fsqc/files/$NAME?overwrite=true" -F file="@$IMG"
	done
	rm $TEMP_RESULT_FILE
done < $RATINGS
#echo "So long, and thanks for all the fish!"
