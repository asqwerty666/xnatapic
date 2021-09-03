#!/bin/bash

ARGS=( "$@" )
HELP="list_projects - list projects owned by the user"

#global variables
[ -s "$XNATAPIC_APPS/xnat.conf" ] && . "$XNATAPIC_APPS/xnat.conf"
[ -s "$XNATAPIC_HOME_APPS/xnat.conf" ] && . "$XNATAPIC_HOME_APPS/xnat.conf"

#local variables
PROJ_ID=""
NAME=""
DESCR=""

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
 --project_id: show only this project
 --name: show project names
 --desc: shot project descriptions
.EOF
		exit 0
		;;
	--project_id)
		let n=n+1
		PROJ_ID="${ARGS[$n]}"
		;;
	--name)
		NAME="${ARGS[$n]}"
		;;
	--desc)
		DESCR="${ARGS[$n]}"
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

#run
TMP_RESULTS=$(mktemp)

if curl -X GET -u "$USER:$PASSWORD" "$HOST/data/projects?format=json&owner=true" -o $TMP_RESULTS 2>/dev/null ; then
	cat $TMP_RESULTS | sed 's/\[\|\]\|{\|}\|,/\n/g' | sed 's/^ *\|\ *$\|"//g' |\
	sed 's/^Result:$/Result: /' |\
	grep '^.\+:.\+$' | sed 's/ *: */=/' |\
	while read l ; do
		K="$(echo "$l" | sed 's/=.*$//')"
		V="$(echo "$l" | sed 's/^.*=//')"
		case $K in
			id)	#assuming "id" will always be the last field
				PID="$V"
				if ! ( [ -z "$PID" ] && [ -z "$NME" ] && [ -z "$DES" ] ) ; then
					if [ -z "$PROJ_ID" ] || [ "$PROJ_ID" == "$PID" ] ; then
						printf "$PID"
						[ -z "$NAME" ] || printf ",$NME"
						[ -z "$DESCR"  ] || printf ",$DES"
						printf "\n"
					fi
				fi
				PID=""
				NME=""
				DES=""
			;;
			name) NME="$V"
			;;
			description) DES="$V"
			;;
		esac
	done
else
	echo "Error: no valid response from server" >&2
fi

#clean up
rm -f $TMP_RESULTS

