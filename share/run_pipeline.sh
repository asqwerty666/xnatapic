#!/bin/bash

ARGS=( "$@" )
HELP="run_pipeline - run a project pipeline on an experiment (or on all the experiments) (UNDOCUMENTED)"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
PIPELINE=""
EXPERIMENT="ALL"
PIPE_ARGS="?xnatapic=true"

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
 --experiment_id <experiment ID or ALL (default)>
 --[pipeline argument] <argument value>

 WARNING: this command uses undocumented Xnat API.
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
	--experiment_id)
		let n=n+1
		EXPERIMENT="${ARGS[$n]}"
		;;
	--*)
		PIPE_ARGS="$PIPE_ARGS&$(echo ${ARGS[$n]} | sed 's/^--//')"
		let n=n+1
		PIPE_ARGS="$PIPE_ARGS=${ARGS[$n]}"
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
if [ -z "$PROJ_ID" ] || [ -z "$EXPERIMENT" ] ; then
	echo "Error: project and pipeline are required" >&2
	exit 1
fi

#run
if [ "$EXPERIMENT" == "" ] || [ "$EXPERIMENT" == "ALL" ] ; then
	TMP_RESULTS=$(mktemp)
	ERRC=0
	if curl -X GET -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/experiments?format=json&owner=true" -o $TMP_RESULTS 2>/dev/null ; then
		#cat $TMP_RESULTS
		cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
		grep '^.\+:.\+$' | sed 's/ *: */=/' |\
		grep '^ID=' | sed 's/^ID=//' |\
		while read EXP ; do
			#echo curl -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/pipelines/$PIPELINE/experiments/$EXP$PIPE_ARGS" 
			if ! curl -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/pipelines/$PIPELINE/experiments/$EXP$PIPE_ARGS" >/dev/null 2>/dev/null ; then
				let ERRC=ERRC+1
			fi
		done
		if [ $ERRC -gt 0 ] ; then
			echo "Error: pipeline could not be run on $ERRC experiments"
			exit 1
		fi
	else
		echo "Error: server reported an error" >&2
		exit 1
	fi
	rm -f $TMP_RESULTS
else
	#echo curl -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/pipelines/$PIPELINE/experiments/$EXPERIMENT$PIPE_ARGS"
	if ! curl -f -X POST -b "JSESSIONID=$XNAT_JSESSIONID" "$HOST/data/projects/$PROJ_ID/pipelines/$PIPELINE/experiments/$EXPERIMENT$PIPE_ARGS" >/dev/null 2>/dev/null ; then
		echo "Error: server reported an error" >&2
		exit 1
	fi
fi
