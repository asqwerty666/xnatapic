#!/bin/bash

ARGS=( "$@" )
HELP="list_experiments - list experiments associated with a project"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
SUBJECT_ID=""
EXPERIMENT_ID=""
SESSION_ID=""

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
 --project_id <project id>
 --subject_id <subject ID>
 --experiment_id <experiment ID>
 --date-range <dd/mm/yyyy[-dd/mm/yyyy]>
 --modality <PET|MRI>
 --date
 --date-insertion
 --label
 --project-name
 --type
.EOF
		exit 0
		;;
	--version)
		echo "xnatapic list_experiments"
		echo "v20201216"
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
	--date-range)
		let n=n+1
		DATE_RANGE="${ARGS[$n]}"
		;;
	--modality)
		let n=n+1
		MODALITY="${ARGS[$n]}"
		;;
	--date)
		SHOW_DATE="${ARGS[$n]}"
		;;
	--date-insertion)
		SHOW_DATE_INS="${ARGS[$n]}"
		;;
	--label)
		SHOW_LABEL="${ARGS[$n]}"
		;;
	--project-name)
		SHOW_PROJ_NAME="${ARGS[$n]}"
		;;	
	--type)
		SHOW_TYPE="${ARGS[$n]}"
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
[ -z "$PROJ_ID" ] || PROJ_ID="/projects/$PROJ_ID"
[ -z "$SUBJECT_ID" ] || SUBJECT_ID="/subjects/$SUBJECT_ID"
[ -z "$EXPERIMENT_ID" ] || EXPERIMENT="/$EXPERIMENT_ID"
[ -z "$DATE_RANGE" ] || DATE_RANGE="&date=$DATE_RANGE"
[ -z "$MODALITY" ] || case "$MODALITY" in
	mr|mri|MR|MRI) MODALITY="&xsiType=xnat:mrSessionData" ;;
	pt|pet|PT|PET) MODALITY="&xsiType=xnat:petSessionData" ;;
	*)      MODALITY="";;
esac

#run
TMP_RESULTS=$(mktemp)

if curl -f -X GET -u "$USER:$PASSWORD" "$HOST/data$PROJ_ID$SUBJECT_ID/experiments$EXPERIMENT_ID?format=json$DATE_RANGE$MODALITY" 2>/dev/null >$TMP_RESULTS ; then
	EID=""
	EDT=""
	EDTI=""
	ELB=""
	PID=""
	ETY=""
	cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
	grep '^.\+:.\+$' | sed 's/ *: */=/' |\
	while read l ; do
		K="$(echo "$l" | sed 's/=.*$//')"
		V="$(echo "$l" | sed 's/^.*=//')"
		case "$K" in
			URI)
				printf "$EID"
				[ -z "$SHOW_DATE" ] || printf ",$EDT"
				[ -z "$SHOW_DATE_INS" ] || printf ",$EDTI"
				[ -z "$SHOW_LABEL"  ] || printf ",$ELB"
				[ -z "$SHOW_PROJ_NAME" ] || printf ",$PID"
				[ -z "$SHOW_TYPE" ] || printf ",$ETY"
				printf "\n"

				EID=""
				EDT=""
				EDTI=""
				ELB=""
				PID=""
				ETY=""
			;;
			ID) EID="$V"
			;;
			date) EDT="$V"
			;;
			insert_date) EDTI="$V"
			;;
			label) ELB="$V"
			;;
			project) PID="$V"
			;;
			xsiType) ETY="$V"
			;;
		esac
	done

else
#error
	echo "Error: retrieving info from server" >&2
	exit 1
fi

#clean up
rm $TMP_RESULTS
