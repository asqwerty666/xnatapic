#!/bin/bash

ARGS=( "$@" )
HELP="define_pipeline - define a pipeline in Xnat from its path (UNDOCUMENTED)"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
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
 --path <pipeline path> [mandatory]

 WARNING: this command does not use Xnat API.
.EOF
		exit 0
		;;
	--path)
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
if [ -z "$PIPELINE" ] ; then
	echo "Error: pipeline path is required" >&2
	exit 1
fi
if echo "$PIPELINE" | grep -v "^\(\/[a-zA-Z0-9_]\+\)\+\.xml" ; then
	echo "Error: malformed path to pipeline XML"
	exit 1
fi


#run
if ! curl -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/app/action/ManagePipeline" \
	-F "eventSubmit_doAdd=Add" \
	-F "pipe:pipelineDetails.path=$PIPELINE" >/dev/null 2>/dev/null ; then
	
	echo "Error: server reported an error"
	exit 1
fi


