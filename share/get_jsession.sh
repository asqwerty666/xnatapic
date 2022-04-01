#!/bin/bash

ARGS=( "$@" )
HELP="get_jsession - get Xnat session to reuse in other calls to xnatapic"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

RAW=false

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
 --raw: show only the ID; otherwise responds with XNAT_JSESSION=...
.EOF
		exit 0
		;;
	--raw)
		RAW=true
		;;
	-*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	*)
		echo "Warning: ignoring option or command ${ARGS[$n]}" >&2
		;;
	esac
done

if $RAW ; then
  echo XNAT_JSESSIONID=$XNAT_JSESSIONID
else
  echo $XNAT_JSESSIONID
fi
