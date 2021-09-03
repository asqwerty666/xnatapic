#!/bin/bash

ARGS=( "$@" )
HELP="upload_nifti - upload nifti files as Xnat experiment resources"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"


#local variables
PROJ_ID=""
SUBJECT_ID=""
EXPERIMENT_ID=""
SCAN_ID=""
DO_PIPELINES=""
APPEND=""
PROGRESS=""
TYPE=""
NIFTI_DIR=""
NIFTI_ZIP=""
nNIFTI_FILES=0
NIFTI_FILES=()
NDS=0
NZS=0

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
 --version: script version
 --project_id <project id>: the project [optional if experiment_id unique name is given]
 --subject_id <subject ID>: the subject [optional]
 --session <session ID>: the session the images were acquired [IGNORED]
 --experiment_id <experiment ID>: the ID of the experiment [mandatory]
 --scan_id <scan_id>: the ID or name of the scan [optional: can be guessed from filename]
 --type <MR,PET> [mandatory for new sessions]
 --mixed-series: the folder contains different series [IGNORED]
 --pipelines: run pipelines after upload
 --append: append uploaded data to already existing in the experiment [IGNORED]
 --progress: show upload progress
 --zip: use one ZIP file containing the NIFTI images
 <nifti_dir folder>: use one folder containing NIFTI images [mandatory if no zip file is provided]
 <nifti and JSON files>: list of NIFTI and JSON files to be uploaded [mandatory if no zip or folder is provided]
 
  Note: file list takes priority over NII folder and over zip file; these three options should not be used simultaneously
.EOF
		exit 0
		;;
	--version)
		echo "xnatapic upload_nifti"
		echo "v20201231"
		exit 0;
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
	--scan_id)
		let n=n+1
		SCAN_ID="${ARGS[$n]}"
		;;
	--type)
		let n=n+1
		case "${ARGS[$n]}" in
			mr|MR)	TYPE="xnat:mrScanData"
			;;
			pet|PET) TYPE="xnat:petScanData"
			;;
			*) echo "Error: unknown experiment type ${ARGS[$n]}" >&2 && exit 1
			;;
		esac
		;;
	--mixed-series)
		let n=n+1
		SERIES="${ARGS[$n]}"
		;;
	--pipelines)
		let n=n+1
		DO_PIPELINES="${ARGS[$n]}"
		;;
	--append)
		let n=n+1
		APPEND="${ARGS[$n]}"
		;;
	--progress)
		let n=n+1
		PROGRESS="-#"
		;;
	--zip)
		let n=n+1
		NIFTI_ZIP="${ARGS[$n]}"
		;;
	-*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	*.nii|*.nii.gz|*.NII|*.NII.gz|*.nii.GZ|*.NII.GZ|*.json|*.JSON)
		if [ -d "${ARGS[$n]}" ] ; then
			NIFTI_DIR="${ARGS[$n]}"
		else
			let nNIFTI_FILES=nNIFTI_FILES+1
			NIFTI_FILES[$nNIFTI_FILES]="${ARGS[$n]}"
		fi
		;;	
	*)
		if [ -d "${ARGS[$n]}" ] ; then
			NIFTI_DIR="${ARGS[$n]}"
		else
			echo "Warning: ignoring option or command '${ARGS[$n]}'" >&2
		fi
		;;
	esac
done

#checks
if grep -q '^XNAT[0-9]_' <<< "$EXPERIMENT_ID" ; then
	DEST="experiments/$EXPERIMENT_ID"
else
	if [ -z "$PROJ_ID" ] ; then
		echo "Error: project is required" >&2
		exit 1
	else
		if [ -z "$SUBJECT_ID" ] ; then
			if [ -z "$EXPERIMENT_ID" ] ; then
				DEST="projects/$PROJ_ID"
			else
				DEST="projects/$PROJ_ID/experiments/$EXPERIMENT_ID"
			fi
		else
			if [ -z "$EXPERIMENT_ID" ] ; then
				DEST="projects/$PROJ_ID/subjects/$SUBJECT_ID"
			else
				DEST="projects/$PROJ_ID/subjects/$SUBJECT_ID/experiments/$EXPERIMENT_ID"
			fi
		fi
	fi
fi

if [ "$nNIFTI_FILES" == 0 ] && [ -z "$NIFTI_DIR" ] && [ -z "$NIFTI_ZIP" ] ; then
	echo "Error: a list of files, a zip file, or a directory holding NIFTI images is required" >&2
	exit 1
fi


#decompress zip if there is one
if [ "$nNIFTI_FILES" == 0 ] && [ -z "$NIFTI_DIR" ] ; then
	NIFTI_DIR=$( mktemp -d )
	NIFTI_ZIP="$( realpath "$NIFTI_ZIP" )"
	(
		cd "$NIFTI_DIR"
	 	unzip "$NIFTI_ZIP"
	)
fi

#upload files from NIFTI_DIR
(
	if ! [ -z "$NIFTI_DIR" ] ; then
		cd "$NIFTI_DIR"
	else
		NIFTI_DIR="."
	fi
	echo "NIFTI_DIR=$NIFTI_DIR"

	if [ -z "$SCAN_ID" ] ; then
		if [ "$nNIFTI_FILES" -gt 0 ] ; then
			#pwd
			#echo "curl -f -X GET -u $USER:$PASSWORD $HOST/data/$DEST/scans/?format=csv -o .scans.txt"
			curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/$DEST/scans/?format=csv" -o .scans.txt >/dev/null 2>/dev/null
		else
			curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data/$DEST/scans/?format=csv" -o .scans.txt /dev/null 2>/dev/null
		fi
	fi

	(
	if [ $nNIFTI_FILES -gt 0 ] ; then
		for f in "${NIFTI_FILES[@]}" ; do
			echo "$f"
		done
	else
		find . -type f
	fi
	) | while read f ; do
		fb="$(basename "$f")"
		#echo "$fb"
		if [ -f "$f" ] ; then
			S=""
			if [ -z "$SCAN_ID" ] ; then
				while read l ; do
					ID="$(cut -d, -f 2 <<< "$l")"
					TY="$(cut -d, -f 3 <<< "$l")"
					if grep -q "$TY.[nNjJ]" <<< "$fb" ; then
						S="$ID"
					fi
				done < ".scans.txt"
				echo "ID = $S"
			#else
			#	S="$SCAN_ID"
			#	echo "ID*=$S"
			fi
			
			if [ -z "$S" ] && ! [ -z "$SCAN_ID" ] && ! [ -z "$TYPE" ] ; then
				echo "curl -f -X PUT -u $USER:$PASSWORD $HOST/data/$DEST/scans/$S?xsiType=$TYPE"
				S="$SCAN_ID"
				if ! curl -f -X PUT -u "$USER:$PASSWORD" "$HOST/data/$DEST/scans/$S?xsiType=$TYPE" >/dev/null 2>/dev/null ; then
					echo "Warning: cannot initialize new session without a session type" >&2
					continue
				fi
			fi

			case "$fb" in
			*.nii|*.NII|*.nii.gz|*.NII.gz|*.NII.GZ)
				echo "$fb"
				echo "curl -f -X PUT -u $USER:$PASSWORD -F file=@$f $HOST/data/$DEST/scans/$S/resources/NIFTI/files/$fb?overwrite=true&inbody=false&format=NIFTI&content=NIFTI_RAW"
				curl -f -X PUT -u "$USER:$PASSWORD" -F "file=@$f" "$HOST/data/$DEST/scans/$S/resources/NIFTI/files/$fb?overwrite=true&inbody=false&format=NIFTI&content=NIFTI_RAW" >/dev/null 2>/dev/null || (
					echo "Error: could not upload $f" >&2
					[ "$nNIFTI_FILES" == 0 ] && touch ".error"
				)
			;;
			*.json|*.JSON)
				#echo "curl -f -X PUT -u $USER:$PASSWORD -F file=@$f $HOST/data/$DEST/scans/$S/resources/NIFTI/files/$fb?overwrite=true&inbody=false&format=NIFTI&content=NIFTI_RAW"
				curl -f -X PUT -u "$USER:$PASSWORD" -F "file=@$f" "$HOST/data/$DEST/scans/$S/resources/NIFTI/files/$fb?overwrite=true&inbody=false&format=JSON&content=NIFTI_JSON" >/dev/null 2>/dev/null || (
					echo "Error: could not upload $f" >&2
					[ "$nNIFTI_FILES" == 0 ] && touch ".error"
				)
			;;
			*) echo "Skipping invalid file '$f'" >&2
			;;
			esac
		else
			echo "Skipping invalid file '$f'" >&2
		fi
	done
)

#remove .scans.txt
if [ -z "$SCAN_ID" ] ; then
	if [ "$nNIFTI_FILES" -gt 0 ] ; then
		rm -f .scans.txt
	else
		rm -f "$NIFTI_DIR/.scans.txt"
	fi
fi

#check and remove .error
if [ "$nNIFTI_FILES" == 0 ] && [ -f "$NIFTI_DIR/.error" ] ; then
	rm -f "$NIFTI_DIR/.error"
	echo "Warning: there were errors" >&2
fi

#remove temporary NIFTI_DIR
if ! [ -z "$NIFTI_ZIP" ] ; then
	rm -rf "$NIFTI_DIR"
fi


