#!/bin/bash

ARGS=( "$@" )
HELP="upload_dicom - upload a DICOM folder to Xnat repository"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"


#local variables
PROJ_ID=""
SUBJECT_ID=""
EXPERIMENT_ID=""
DO_PIPELINES=""
APPEND=""
PROGRESS=""
DICOM_DIR=()
DICOM_ZIP=()
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
 --project_id <project id>: the project the images belong to [mandatory]
 --subject_id <subject ID>: the subjects of the images [optional]
 --session <session ID>: the session the images were acquired [IGNORED]
 --experiment_id <experiment ID>: the ID of the experiment [optional]
 --mixed-series: the folder contains different series
 --pipelines: run pipelines (i.e. upload to prearchive, then archive and launch pipelines)
 --append: append uploaded data to already existing in the experiment
 --progress: show upload progress
 --zip: use a ZIP file containing the DICOM series [mandatory if no dicom_dir folder is provided]
 <dicom_dir folder>: list of folders containing DICOM images [mandatory if no zip file is provided]
.EOF
		exit 0
		;;
	--version)
		echo "xnatapic upload_dicom"
		echo "v20210104"
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
	--mixed-series)
		SERIES="${ARGS[$n]}"
		;;
	--pipelines)
		DO_PIPELINES="${ARGS[$n]}"
		;;
	--append)
		APPEND="${ARGS[$n]}"
		;;
	--progress)
		PROGRESS="-#"
		;;
	--zip)
		let n=n+1
		DICOM_ZIP[$NZS]="${ARGS[$n]}"
		let NZS=$NZS+1
		;;
	-*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	*)
		if [ -d "${ARGS[$n]}" ] ; then
			DICOM_DIR[$NDS]="${ARGS[$n]}"
			let NDS=$NDS+1
		else
			echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		fi
		;;
	esac
done

#checks
if [ -z "$PROJ_ID" ] ; then
	echo "Error: project is required" >&2
	exit 1
fi
if [ -z "$DICOM_DIR" ] && [ -z "$DICOM_ZIP" ] ; then
	echo "Error: a zip file or a directory holding DICOM images is required" >&2
	exit 1
fi

if [ -z "$SUBJECT_ID" ] ; then
	if [ -z "$EXPERIMENT_ID" ] ; then
		DEST="&dest=/archive/projects/$PROJ_ID"
	else
		DEST="&dest=/archive/projects/$PROJ_ID/experiments/$EXPERIMENT_ID"
	fi
else
	if [ -z "$EXPERIMENT_ID" ] ; then
		DEST="&dest=/archive/projects/$PROJ_ID/subjects/$SUBJECT_ID"
	else
		DEST="&dest=/archive/projects/$PROJ_ID/subjects/$SUBJECT_ID/experiments/$EXPERIMENT_ID"
	fi
fi
if [ -z "$APPEND" ] ; then
	OVWR="&overwrite=delete"
else
	OVWR="&overwrite=append"
fi
if [ -z "$PREARCHIVE" ] ; then
	if [ -z "$DO_PIPELINES" ] ; then
		PIP="&triggerPipelines=false"
	else
		PIP="&triggerPipelines=true"
	fi
else
	DEST="&dest=/prearchive/projects/$PROJ_ID"
	PIP=""
fi

ERR=0

#run over directories
if [ ${#DICOM_DIR[@]} -gt 0 ] ; then
	for f in "${DICOM_DIR[@]}" ; do

		if [ -z "$SERIES" ] ; then
			TMP_ZIP=$( mktemp )
				rm -f $TMP_ZIP
				TMP_ZIP="$TMP_ZIP.tar.gz"

			if ! tar zcf $TMP_ZIP -C "$(dirname "$f")" "$(basename "$f")" 2>/dev/null ; then
				echo "Error: could not read DICOM_DIR at $f" >&2
				exit 1
			fi

			echo curl $PROGRESS -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/services/import?import-handler=SI$DEST$OVWR$PIP" -F file.tar.gz="@$TMP_ZIP"
			[ -z "$PROGRESS" ] || echo "Uploading $(basename $f) ..." >&2
			curl -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/services/import?import-handler=SI$DEST$OVWR$PIP" -F file.tar.gz="@$TMP_ZIP" >/dev/null 2>/dev/null ||\
			if [ "${#DICOM_DIR[@]}" -gt 1 ] ; then
				echo "Warning: could not upload $f" >&2
				let ERR=$ERR+1
			else
				echo "Error: could not upload $f" >&2 

				#clean up
				rm -f $TMP_ZIP

				exit 1
			fi

			#clean up
			rm -f $TMP_ZIP
		else
			#subir serie a serie
			for s in $( ls "$f" | awk -F. '{print $4}' | uniq ) ; do
				TMP_ZIP=$( mktemp )
					rm -f $TMP_ZIP
					TMP_ZIP="$TMP_ZIP-$s.tar.gz"

				if ! tar zcf $TMP_ZIP --transform='s/^/'$s'\//' -C "$f" $(ls "$f" | grep '^[A-Z0-9_]\+\.[A-Z0-9_]\+\.[A-Z0-9_]\+\.'$s'\.') 2>/dev/null ; then
					echo "Error: could not read DICOM_DIR at $f" >&2
					exit 1
				fi

				echo curl $PROGRESS -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/services/import?import-handler=SI$DEST$OVWR$PIP" -F file.tar.gz="@$TMP_ZIP"
				[ -z "$PROGRESS" ] || echo "Uploading $s ..." >&2
				curl $PROGRESS -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/services/import?import-handler=SI$DEST$OVWR$PIP" -F file.tar.gz="@$TMP_ZIP" >/dev/null 2>/dev/null ||\
				if [ "${#DICOM_DIR[@]}" -gt 1 ] ; then
					echo "Warning: could not upload series $s in $f" >&2
					let ERR=$ERR+1
				else
					echo "Error: could not upload series $s in $f" >&2
	
					#clean up
					rm -f $TMP_ZIP

					exit 1
				fi

				#clean up
				rm -f $TMP_ZIP
			done	
		fi
	done
fi

#run over zips
if [ ${#DICOM_ZIP[@]} -gt 0 ] ; then

	for ZIP in ${DICOM_ZIP[@]} ; do
		echo curl $PROGRESS -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/services/import?import-handler=SI$DEST$OVWR$PIP" -F file.zip="@$ZIP"
		[ -z "$PROGRESS" ] || echo "Uploading $ZIP ..." >&2
		curl $PROGRESS -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/services/import?import-handler=SI$DEST$OVWR$PIP" -F file.zip="@$ZIP" >/dev/null 2>/dev/null ||	 if [ ${#DICOM_ZIP[@]} -gt 1 ] ; then
			echo "Warning: could not upload zip series $ZIP" >&2
			let ERR=$ERR+1
		else
			echo "Error: could not upload zip series $ZIP" >&2
			exit 1
		fi
	done
fi

