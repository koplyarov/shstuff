LINEFEED="
"

LOGGER_SCRIPTNAME="Your script"

COLORED_LOGS=1
if [ "`echo -e`" ]; then
	COLORED_LOGS=0
fi

DELIM='==============================================='
if [ $COLORED_LOGS -ne 0 ]; then
	ESC_SEQ="\x1b["
	COL_RESET=$ESC_SEQ"39;49;00m"
	COL_RED=$ESC_SEQ"31;01m"
	COL_GREEN=$ESC_SEQ"32;01m"
	COL_YELLOW=$ESC_SEQ"33;01m"
	COL_BLUE=$ESC_SEQ"34;01m"
	COL_MAGENTA=$ESC_SEQ"35;01m"
	COL_CYAN=$ESC_SEQ"36;01m"
fi

RemoveDots() {
	echo $* | sed 's@/\./@/@g' | sed 's@/\.$@@g'
}

Log() {
	case $1 in
	"Info")		local LOGLEVEL="[$1]";		local MSGCOLOR=$COL_GREEN;	shift ;;
	"Warning")	local LOGLEVEL="[$1]";		local MSGCOLOR=$COL_YELLOW;	shift ;;
	"Error")	local LOGLEVEL="[$1]";		local MSGCOLOR=$COL_RED;	shift ;;
	*)			local LOGLEVEL="[Info]";	local MSGCOLOR=$COL_GREEN;	;;
	esac

	local COLORED_MSG=0
	local NO_LINEFEED=0
	local NO_PREAMBLE=0
	if [ $COLORED_LOGS -ne 0 ]; then
		for ARG in "$@"; do
			case "$ARG" in
			"Log_ColoredMsg") local COLORED_MSG=1 ;;
			"Log_NoLineFeed") local NO_LINEFEED=1 ;;
			"Log_NoPreamble") local NO_PREAMBLE=1 ;;
			*)
				if [ $NO_PREAMBLE -eq 0 ]; then
					echo -e -n $COL_MAGENTA"{$LOGGER_SCRIPTNAME} "$MSGCOLOR"$LOGLEVEL">&2
					[ $COLORED_MSG -eq 0 ] && echo -e -n $COL_RESET>&2
					local NO_PREAMBLE=1
				else
					[ $COLORED_MSG -eq 1 ] && echo -e -n $MSGCOLOR>&2
				fi
				echo -n " $ARG">&2
				;;
			esac
		done
		if [ $NO_LINEFEED -eq 0 ]; then
			echo -e $COL_RESET>&2
		else
			echo -e -n $COL_RESET>&2
		fi
	else
		for ARG in "$@"; do
			case "$ARG" in
			"Log_ColoredMsg") ;;
			"Log_NoLineFeed") local NO_LINEFEED=1 ;;
			"Log_NoPreamble") local NO_PREAMBLE=1 ;;
			*)
				if [ $NO_PREAMBLE -eq 0 ]; then
					echo -n "{$LOGGER_SCRIPTNAME} $LOGLEVEL">&2
					local NO_PREAMBLE=1
				fi
				echo -n " $ARG">&2
				;;
			esac
		done
		if [ $NO_LINEFEED -eq 0 ]; then
			echo>&2
		fi
	fi
	return 0
}

Fail() {
	Log "$DELIM"
	Log Error $@
	exit 1
}

# Deprecated!
Try() {
	"$@" || Fail "$* failed!"
}

ParseArguments() {
	[ $# -ge 1 ] || { Log Error "No argument parsing function passed to ParseArguments!"; return 2; }
	local PARSE_FUNC="$1"
	local ARGNUM=0
	shift
	while [ $# -gt 0 ]; do
		$PARSE_FUNC "$@"
		local RESULT="$?"
		[ $RESULT -eq 255 ] && { Log Error "Error handling argument #$ARGNUM ($1)!"; return 1; }
		shift
		shift $RESULT
		ARGNUM=`echo "$ARGNUM+$RESULT+1" | bc`
	done
}

CheckSuperuser() {
	[ $UID -eq 0 ];
}

SetCacheParam() {
	[ $# -eq 3 ] || { Log Error "Invalid number of arguments for SetCacheParam!"; return 1; }
	local NAME=CACHE_$1
	case $2 in
	"Autosave"|"Savefile")	local CACHE_PARAM=${NAME}_PARAM_$2 ;;
	*)						Log Error "Invalid cache parameter: $2"; return 2 ;;
	esac
	eval $CACHE_PARAM=\""$3"\"
}

GetCacheParam() {
	[ $# -eq 2 ] || { Log Error "Invalid number of arguments for GetCacheParam!"; return 1; }
	local NAME=CACHE_$1
	case $2 in
	"Autosave"|"Savefile")	local CACHE_PARAM=${NAME}_PARAM_$2 ;;
	*)						Log Error "Invalid cache parameter: $2"; return 2 ;;
	esac
	eval echo \"\$$CACHE_PARAM\"
}


CreateCache() {
	SetCacheParam $1 Autosave 0
	SetCacheParam $1 Savefile "`pwd`/.cache_$1"
}

CacheLoad() {
	[ $# -eq 1 -o $# -eq 2 ] || { Log Error "Invalid parameters count for CacheLoad!"; return 0; }
	local FILE=$2
	[ $# -eq 1 ] && FILE=`GetCacheParam $1 Savefile`
	local NAME=CACHE_$1
	eval "$NAME=\"`cat $FILE 2>/dev/null`\""
	return 0
}

CacheGetContent() {
	local NAME=CACHE_$1
	eval echo \"\$$NAME\"
}

CacheHit() {
	[ $# -eq 2 ] || { Log Warning "Invalid parameters count for CacheHit!"; return 0; }
	CacheCheck $1 $2 && return 0
	local NAME=CACHE_$1
	eval "$NAME=\"`CacheGetContent $1`$LINEFEED$2\""
	if [ `GetCacheParam $1 Autosave` -ne 0 ]; then
		CacheGetContent $1 > `GetCacheParam $1 Savefile`
	fi
	return 0
}

CacheErase() {
	[ $# -eq 2 ] || { Log Error "Invalid parameters count for CacheErase!"; return 1; }
	CacheCheck $1 $2 || return 0
	local NAME=CACHE_$1
	eval "$NAME=\"`CacheGetContent $1 | grep -Fxv $2`\""
	if [ `GetCacheParam $1 Autosave` -ne 0 ]; then
		CacheGetContent $1 > `GetCacheParam $1 Savefile`
	fi
}

CacheCheck() {
	[ $# -eq 2 ] || { Log Warning "Invalid parameters count for CacheCheck!"; return 1; }
	CacheGetContent $1 | grep -Fx "$2" >/dev/null 2>/dev/null
}

SHSTUFF_LINUX_DISTRIB_ID=""
GetLinuxDistributorId() {
	if [ -z "$SHSTUFF_LINUX_DISTRIB_ID" ]; then
		which lsb_release >/dev/null 2>/dev/null || { Log Error "lsb_release utility not found!"; return 1; }
		SHSTUFF_LINUX_DISTRIB_ID=`lsb_release -is`
	fi
	echo "$SHSTUFF_LINUX_DISTRIB_ID"
}

CheckLinuxPackage() {
	case `GetLinuxDistributorId` in
	"Ubuntu")
		dpkg -s $1 >/dev/null 2>/dev/null
		;;
	*)
		Log Error "Unknown linux distribution!"
		return 2
		;;
	esac
}

EscapeForSed() {
	echo "$@" | sed 's/\([].\/\\$^*&[]\)/\\\1/g'
}
