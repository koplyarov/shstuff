#!/bin/bash

LIBSETUP_NOTIFY=0

Exec() {
	local SETUP_OBJ=$1
	shift
	local ACTION="$@"
	local MSG=`eval msg_$ACTION`
	if [ "`GetSetupParam $SETUP_OBJ Verbose`" -eq "0" ]; then
		Log Log_NoLineFeed "$MSG..."
		local TMP_FILE;
		TMP_FILE=`MkTemp` || { Log Error "Could not create temp file for setup action output!"; return 1; }
		eval do_$ACTION >$TMP_FILE 2>&1
		local RES=$?
		if [ $RES -eq 0 ]; then
			Log Log_NoPreamble Log_ColoredMsg "OK"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "$MSG succeeded"
		else
			Log Error Log_NoPreamble Log_ColoredMsg "Fail!"
			Log Error "`cat $TMP_FILE`"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "$MSG failed!"
		fi
		rm $TMP_FILE
		return $RES
	else
		Log "$MSG..."
		if eval do_$ACTION 2>&1; then
			Log Log_ColoredMsg "OK"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "$MSG succeeded"
			return 0
		else
			Log Error Log_ColoredMsg "Fail!"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "$MSG failed!"
			return 1
		fi
	fi
}

Revert() {
	local SETUP_OBJ=$1
	shift
	local ACTION="$@"
	local MSG=`eval msg_$ACTION`
	if [ "`GetSetupParam $SETUP_OBJ Verbose`" -eq "0" ]; then
		Log Log_NoLineFeed "Reverting '$MSG'..."
		local TMP_FILE;
		TMP_FILE=`MkTemp` || { Log Error "Could not create temp file for setup action output!"; return 1; }
		eval undo_$ACTION >$TMP_FILE 2>&1
		if [ $? -eq 0 ]; then
			Log Log_NoPreamble Log_ColoredMsg "OK"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "Reverting '$MSG' succeeded"
		else
			Log Warning Log_NoPreamble Log_ColoredMsg "Fail!"
			Log Warning "`cat $TMP_FILE`"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "Reverting '$MSG' failed!"
		fi
		rm $TMP_FILE
	else
		Log "Reverting '$MSG'..."
		if eval undo_$ACTION 2>&1; then
			Log Log_ColoredMsg "OK"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "Reverting '$MSG' succeeded"
		else
			Log Warning Log_ColoredMsg "Fail!"
			[ $LIBSETUP_NOTIFY -ne 0 ] && Notify "Reverting '$MSG' failed!"
		fi
	fi
}

CreateSetup()
{
	local SETUP_OBJ=$1
	eval $SETUP_OBJ=\"\"
	SetSetupParam $SETUP_OBJ Verbose 0
}

SetSetupParam() {
	[ $# -eq 3 ] || { Log Error "Too few arguments for SetSetupParam!"; return 1; }
	case $2 in
	"Verbose"|"User_"*)	local SETUP_PARAM=$1_PARAM_$2 ;;
	*)					Log Error "Invalid setup parameter: $2"; return 2 ;;
	esac
	eval $SETUP_PARAM=\""$3"\"
}

GetSetupParam() {
	[ $# -eq 2 ] || { Log Error "Too few arguments for GetSetupParam!"; return 1; }
	case $2 in
	"Verbose"|"User_"*)	local SETUP_PARAM=$1_PARAM_$2 ;;
	*)					Log Error "Invalid setup parameter: $2"; return 2 ;;
	esac
	eval echo \"\$$SETUP_PARAM\"
}

Install() {
	local SETUP_OBJ=$1
	local ACTIONS
	local UNWIND_ACTIONS
	eval ACTIONS="\$$SETUP_OBJ"
	local OLD_IFS="$IFS"
	IFS="$LINEFEED"
	for ACTION in $ACTIONS; do
		IFS="$OLD_IFS"
		if ! Exec $SETUP_OBJ "$ACTION"; then
			IFS="$LINEFEED"
			for UNWIND_ACTION in $UNWIND_ACTIONS; do
				IFS="$OLD_IFS"
				Revert $SETUP_OBJ "$UNWIND_ACTION"
			done
			IFS="$OLD_IFS"
			return 1
		fi
		UNWIND_ACTIONS="${ACTION}${LINEFEED}${UNWIND_ACTIONS}"
	done
	IFS="$OLD_IFS"
}

Uninstall() {
	local SETUP_OBJ=$1
	local ACTIONS
	local UNWIND_ACTIONS
	eval ACTIONS="\$$SETUP_OBJ"
	local OLD_IFS="$IFS"
	IFS="$LINEFEED"
	for ACTION in $ACTIONS; do
		UNWIND_ACTIONS="${ACTION}${LINEFEED}${UNWIND_ACTIONS}"
	done
	for UNWIND_ACTION in $UNWIND_ACTIONS; do
		IFS="$OLD_IFS"
		Revert $SETUP_OBJ "$UNWIND_ACTION"
	done
	IFS="$OLD_IFS"
}

AddAction() {
	local V=$1
	shift
	local OLDVAL
	eval OLDVAL="\$$V"
	[ -z "$OLDVAL" ] || eval $V="\$${V}\"$LINEFEED\""
	eval $V="\$${V}\$1"
	shift
	for ARG in "$@"; do
		eval $V="\$${V}\ \\\"\$ARG\\\""
	done;
}
