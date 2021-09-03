#!/bin/bash

ARGS=( "$@" )
HELP="append_pipeline - append a pipeline to a project (UNDOCUMENTED)"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
PIPELINE=""

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
 --pipeline <pipeline name> [mandatory]

 WARNING: this command does not use Xnat API.
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
		;;
	--pipeline)
		let n=n+1
		PIPELINE="${ARGS[$n]}"
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
if [ -z "$PROJ_ID" ] || [ -z "$PIPELINE" ] ; then
	echo "Error: project and pipeline are required" >&2
	exit 1
fi

#run
TMP_RESULTS=$(mktemp)

if curl -X GET -u "$USER:$PASSWORD" "$HOST/data/projects/$PROJ_ID/pipelines?format=json&additional=true" -o $TMP_RESULTS 2>/dev/null ; then
	PTH=""
	PNM=""
	PDS=""
	PAT=""
	cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
	grep '^.\+:.\+$' | sed 's/ *: */=/' | sed 's/\\//g' |\
	while read l ; do
		K="$(echo "$l" | sed 's/=.*$//')"
		V="$(echo "$l" | sed 's/^.*=//')"
		case "$K" in
			Datatype)
				if [ "$PNM" == "$PIPELINE.xml" ] ; then
					#THIS IS NOT THE API: it's a hack based on the GUI
					curl -f -X POST -u "$USER:$PASSWORD" "$HOST/app/action/ManagePipeline" \
						-F "schemaType=arc:project_descendant_pipeline" \
						-F "eventSubmit_doAddprojectpipeline=Submit" \
						-F "project=$PROJ_ID" -F "auto_archive=true" \
						-F "arc:project_descendant_pipeline.name=$PIPELINE" \
						-F "pipeline_path=$PTH" \
						-F "arc:project_descendant_pipeline.location=$PTH" \
						-F "dataType=$V" >/dev/null 2>/dev/null
					#NO RETURN STATUS
					break
				fi
				PTH=""
				PNM=""
				PDS=""
				PAT=""
			;;
			Path) PTH="$V"
			;;
			Description) PDS="$V"
			;;
			Name) PNM="$V"
			;;
			"Applies To") PAT="$V"
			;;
		esac
	done
else
	echo "Error: server reported an error" >&2 
	exit 1
fi
