#!/bin/bash

ARGS=( "$@" )
HELP="get_fsresults - gets freesurfer results archived in Xnat"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
SUBJECT_ID=""
EXPERIMENT_ID=""
WHAT=""
DESTINATION="."

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
 --experiment_id: experiment (mandatory: either label or Xnat internal experiment code)
 --project_id: project (only required if experiment_id is a label)
 --subject_id: subject (only required if experiment_id is a label)
 --all-tgz: download all Freesurfer results as a tar.gz file
 --all-stats: download all Freesurfer statistics
 --stats: download stats by (comma separated) names
 <destination>: directory where the results are stored
.EOF
		exit 0
		;;
	--version)
		echo "xnatapic get_fsresults"
		echo "v20210115"
		exit 0;
		;;
	--project_id)
		let n=n+1
		PROJECT_ID="${ARGS[$n]}"
		;;
	--subject_id)
		let n=n+1
		SUBJECT_ID="${ARGS[$n]}"
		;;
	--experiment_id)
		let n=n+1
		EXPERIMENT_ID="${ARGS[$n]}"
		;;
	--all-tgz)
		WHAT=TGZ
		;;
	--all-stats)
		WHAT=ALL_STATS
		;;
	--stats)
		let n=n+1
		WHAT="${ARGS[$n]}"
		;;
	-*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	*)
		DESTINATION="${ARGS[$n]}"
		;;
	esac
done

#experiment route
[ -z "$EXPERIMENT_ID" ] && echo "Error: experiment_id is required" >&2
URIpath="experiments/$EXPERIMENT_ID"

if ! grep -q '^XNAT[0-9]_' <<< "$EXPERIMENT_ID" && ! [ -z "$SUBJECT_ID" ] ; then
	URIpath="subjects/$SUBJECT_ID/$URIpath"
fi

if ! grep -q '^XNAT[0-9]_' <<< "$EXPERIMENT_ID" && ! [ -z "$PROJECT_ID" ] ; then
	URIpath="projects/$PROJECT_ID/$URIpath"
fi

URIpath="/data/$URIpath"


#list of files to download
if [ -z "$WHAT" ] ; then
	echo "Error: some action (--all-tgz, --all-stats, --stats) was expected" >&2
	exit 1
else
	case "$WHAT" in
	TGZ)
		WHATlist=( '.tar.gz' )
		;;
	ALL_STATS)
		WHATlist=( '.stats' )
		;;
	*)
		WHATlist=( $( echo "$WHAT" | sed 's/,/\n/g' ) )
		;;
	esac
fi

#list resources
TMP_FILE_LIST=$(mktemp)

curl -X GET -b JSESSIONID=$XNAT_JSESSIONID "$HOST$URIpath/files?format=json" 2>/dev/null | sed 's/\[{\|,{\|}/\n/g' | grep '^"file_content"' |\
while read r ; do
	v=()
	echo "$r" | sed 's/","/"\n"/g' | (
		while read kv ; do
			k=$(echo "$kv" | sed 's/:.*$//' | sed 's/"//g')
			if [ "$k" == "URI" ] ; then
				v=$(echo "$kv" | sed 's/^.*://' | sed 's/"//g')
				echo "$v" >> $TMP_FILE_LIST
				break;
			fi
		done
	)	
done

echo "${WHATlist[@]}"
cat "$TMP_FILE_LIST"

if [ ${WHATlist[0]} != '.stats' ] && [ ${WHATlist[0]} != '.tar.gz' ] ; then
	WHATlist=( $( for s in "${WHATlist[@]}" ; do echo "$s" | sed 's/\(\.stats\)*$/.stats/'; done ) )
fi

if [ ${#WHATlist[@]} == 1 ] && [ ${WHATlist[0]} == '.stats' ] ; then
	WHATlist=( $( cat $TMP_FILE_LIST | grep '\.stats$' | while read uri ; do basename "$uri" ; done ) )
fi

if [ ${#WHATlist[@]} == 1 ] && [ ${WHATlist[0]} == '.tar.gz' ] ; then
	WHATlist=( $( cat $TMP_FILE_LIST | grep '\.tar\.gz$' | while read uri ; do basename "$uri" ; done ) )
fi

echo "${WHATlist[@]}"

#download resources in WHATlist
for ((n=0; n<${#WHATlist[@]}; n++)) ; do
	if URI="$(grep -F "/${WHATlist[$n]}" $TMP_FILE_LIST | head -n 1)" ; then
	(
		cd "$DESTINATION"
		curl -X GET -b JSESSIONID=$XNAT_JSESSIONID "$HOST$URI" -o "$(basename "$URI")" 2>/dev/null
	)
	else
		echo "Warning: resource ${WHATlist[$n]} not found in experiment $EXPERIMENT_ID"
	fi
done

rm -f $TMP_FILE_LIST

