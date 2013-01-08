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
					if [ $COLORED_MSG -eq 0 ]; then
						echo -e -n $COL_RESET>&2
					fi
					local NO_PREAMBLE=1
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
}

Fail() {
	Log "$DELIM"
	Log Error $@
	exit 1
}

Try() {
	"$@"
	if [ $? -ne 0 ]; then
		Fail "$* failed!"
	fi
}

GetLinuxDistributorId() {
	if which lsb_release >/dev/null 2>/dev/null; then
		lsb_release -is
	else
		Log Error "lsb_release utility not found!"
		return 1
	fi
}

SHSTUFF_LINUX_DISTRIB_ID=""
CheckLinuxPackage() {
	if [ -z "$SHSTUFF_LINUX_DISTRIB_ID" ]; then
		SHSTUFF_LINUX_DISTRIB_ID=`GetLinuxDistributorId`
	fi
	case $SHSTUFF_LINUX_DISTRIB_ID in
	"Ubuntu")
		dpkg -s $1 >/dev/null 2>/dev/null
		;;
	*)
		Log Error "Unknown linux distribution!"
		return 2
		;;
	esac
}

MkDirIfAbsent() {
	if [ ! -e $1 ]; then
		Log "Creating directory $1"
		Try mkdir $1
	fi
}

CreateLink() {
	Log "Creating $2 -> $1"
	if [ -e "$2" ]; then
		Fail "$2 exists!"
	fi
	Try ln -s $@
}

ClearLink() {
	__LOCAL_SRC=`readlink $2`
	if [ $? -eq 0 ]; then
		if [ "$__LOCAL_SRC" = "$1" ]; then
			Log "Removing $2 -> $1"
			Try rm $2
		else
			Log "$2 is not a link to $1, ignoring it"
		fi
	fi
}

RemoveIfEmpty() {
	if [ \( -d $1 \) ]; then
		if [ -z "`ls -1A $1`" ]; then
			Log "$1 is empty, removing it"
			Try rm -r $1
		fi
	fi
}

ApplyPatch() {
	Log "Applying patch $1"
	Try patch -p1 < $1
}

RevertPatch() {
	Log "Reverting patch $1"
	patch --no-backup --reject-file=- -f -R -p1 < $1
	if [ $? -ne 0 ]; then
		Log Warning "Could not revert $1!"
	fi
}


EscapeForSed() {
	echo "$@" | sed 's/\([].\/\\$^*&[]\)/\\\1/g'
}


AddLine() {
	echo "$2" >> $1
	if [ $? -eq 0 ]; then
		Log "Successfully added '$2' to $1"
	else
		Log Warning "Could not add '$2' to $1. You should do it manually."
	fi
}

RemoveLine() {
	local TEMPFILE1=`tempfile`
	if grep -xvF "$2" "$1" > $TEMPFILE1; then
		local TEMPFILE2=`tempfile`
		Try mv "$1" $TEMPFILE2
		if mv $TEMPFILE1 "$1"; then
			rm $TEMPFILE2
			Log "Successfully removed '$2' from $1"
		else
			Try mv $TEMPFILE2 "$1"
			Log Warning "Could not remove '$2' from $1. You should do it manually."
		fi
	else
		rm $TEMPFILE1
	fi
}
