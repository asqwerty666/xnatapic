#!/bin/bash

ARGS=( "$@" )
HELP="get_registration_report - gets PET registration results archived in Xnat"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
HOST_NAME="$HOST"
OUTPUT=""

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
 --xnat_host: Xnat host address (if different from $HOST)
 --project_id: project (only required if experiment_id is a label)
 --output: name of the CSV file (defaults to stdout)
.EOF
		exit 0
		;;
	--version)
		echo "xnatapic get_registration_report"
		echo "v20201231"
		exit 0;
		;;
	--xnat_host)
		let n=n+1
		HOST_NAME="${ARGS[$n]}"
		;;
	--project_id)
		let n=n+1
		PROJECT_ID="${ARGS[$n]}"
		;;
	--output)
		let n=n+1
		OUTPUT="${ARGS[$n]}"
		;;
	-*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	esac
done

#experiment route
[ -z "$PROJECT_ID" ] && echo "Error: project_id is required" >&2
URIpath="/data/projects/$PROJECT_ID/experiments"

if [ -z "$OUTPUT" ]; then
	echo "DCM_SUBJECT,SUBJECT_ID,PET_EXPERIMENT_ID,MRI_EXPERIMENT_ID,REGISTRATION_QA,STATISTICS_SURV,STATISTICS_CL,QA_URI"
else
	echo "DCM_SUBJECT,SUBJECT_ID,PET_EXPERIMENT_ID,MRI_EXPERIMENT_ID,REGISTRATION_QA,STATISTICS_SURV,STATISTICS_CL,QA_URI" > "$OUTPUT"
fi

echo "curl -f -X GET -b JSESSIONID=$XNAT_JSESSIONID $HOST$URIpath/?format=csv&modality=petSessionData"
curl -f -X GET -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST$URIpath/?format=csv&modality=petSessionData" 2>/dev/null |\
grep 'xnat:petSessionData' |\
cut -d, -f 2 |\
while read PET_EXPERIMENT_ID ; do
	URIpath="/data/experiments/$PET_EXPERIMENT_ID"
	DCM_SUBJECT_ID=""
	SUBJECT_ID=""
	ALT_SUBJECT_ID=""
	MRI_EXPERIMENT_ID=""
	REGISTRATION_QA=""
	STATISTICS_SURV=""
	STATISTICS_CL=""

	curl -f -X GET -b JSESSIONID=$XNAT_JSESSIONID "$HOST$URIpath/?format=json" 2>/dev/null |\
	sed 's/\[{\|,{\|}\|,/\n/g' | grep '^"[a-zA-Z_]\+":' | (
		while read kv ; do
			k="$(echo "$kv" | sed 's/\s*:.*$//' | sed 's/"//g')"
			v="$(echo "$kv" | sed 's/^.*:\s*//' | sed 's/"//g')"
			#echo "K=$k, V=$v"
			case $k in
				dcmPatientId) DCM_SUBJECT_ID="$v" ;;
				subject_ID)   SUBJECT_ID="$v" ;;
				data_fields) #hack for errors in DICOM fields
					if grep -q '_S' <<<"$v" ; then
						ALT_SUBJECT_ID="$v"
					fi
				;;
			esac
		done
		if [ -z "$SUBJECT_ID" ] ; then
			SUBJECT_ID="$ALT_SUBJECT_ID"
		fi
		printf '"%s","%s","%s",' "$DCM_SUBJECT_ID" "$SUBJECT_ID" "$PET_EXPERIMENT_ID"
	)
	
	curl -f -X GET -b JSESSIONID=$XNAT_JSESSIONID "$HOST$URIpath/resources/MRI/files/mriSessionMatch.json" 2>/dev/null |\
	sed 's/\[{\|,{\|}\|,/\n/g' | grep '^"[a-zA-Z_]\+":' | (
		while read kv ; do
			k="$(echo "$kv" | sed 's/\s*:.*$//' | sed 's/"//g')"
			v="$(echo "$kv" | sed 's/^.*:\s*//' | sed 's/"//g')"
			#echo "K=$k, V=$v"
			case $k in
				MRIsession) MRI_EXPERIMENT_ID="$v" ;;
				qa)         REGISTRATION_QA="$v" ;;
				surv)       STATISTICS_SURV="$v" ;;
				cl)         STATISTICS_CL="$v" ;;
			esac
		done
		printf '"%s",%s,%s,%s,"%s"\n' "$MRI_EXPERIMENT_ID" "$REGISTRATION_QA" "$STATISTICS_SURV" "$STATISTICS_CL" "$HOST_NAME$URIpath/resources/MRI/files/qa.html"
	)
done | if [ -z "$OUTPUT" ] ; then
	cat
else
	cat >> "$OUTPUT"
fi

