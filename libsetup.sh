#!/bin/bash


Exec() {
	local IFS=" "
	local SETUP_OBJ=$1
	shift
	local ACTION="$@"
	local MSG=`eval msg_$ACTION`
	if [ "`GetSetupParam $SETUP_OBJ Verbose`" -eq "0" ]; then
		Log Log_NoLineFeed "$MSG..."
		__LOCAL_OUT=`eval do_$ACTION 2>&1`
		if [ $? -eq 0 ]; then
			Log Log_NoPreamble Log_ColoredMsg "OK"
			return 0
		else
			Log Error Log_NoPreamble Log_ColoredMsg "Fail!"
			Log Error "$__LOCAL_OUT"
			return 1
		fi
	else
		Log "$MSG..."
		eval do_$ACTION 2>&1
		if [ $? -eq 0 ]; then
			Log Log_ColoredMsg "OK"
			return 0
		else
			Log Error Log_ColoredMsg "Fail!"
			return 1
		fi
	fi
}

Revert() {
	local IFS=" "
	local SETUP_OBJ=$1
	shift
	local ACTION="$@"
	local MSG=`eval msg_$ACTION`
	if [ "`GetSetupParam $SETUP_OBJ Verbose`" -eq "0" ]; then
		Log Log_NoLineFeed "Reverting '$MSG'..."
		__LOCAL_OUT=`eval undo_$ACTION 2>&1`
		if [ $? -eq 0 ]; then
			Log Log_NoPreamble Log_ColoredMsg "OK"
		else
			Log Warning Log_NoPreamble Log_ColoredMsg "Fail!"
			Log Warning "$__LOCAL_OUT"
		fi
	else
		Log "Reverting '$MSG'..."
		eval undo_$ACTION 2>&1
		if [ $? -eq 0 ]; then
			Log Log_ColoredMsg "OK"
		else
			Log Warning Log_ColoredMsg "Fail!"
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
	if [ $# -le 2 ]; then
		Log Error "Too few arguments for SetSetupParam!"
		return 1
	fi
	case $2 in
	"Verbose"|"User_"*)	local SETUP_PARAM=$1_PARAM_$2 ;;
	*)					Log Error "Invalid setup parameter: $2"; return 2 ;;
	esac
	shift 2
	eval $SETUP_PARAM=\""$@"\"
}

GetSetupParam() {
	if [ $# -ne 2 ]; then
		Log Error "Invalid number of arguments for GetSetupParam!"
		return 1
	fi
	case $2 in
	"Verbose"|"User_"*)	local SETUP_PARAM=$1_PARAM_$2 ;;
	*)					Log Error "Invalid setup parameter: $2"; return 2 ;;
	esac
	shift 2
	eval echo \"\$$SETUP_PARAM\"
}

Install() {
	local SETUP_OBJ=$1
	eval __LOCAL_ACTIONS="\$$SETUP_OBJ"
	local ACTIONS="$__LOCAL_ACTIONS"
	local IFS="$LINEFEED"
	for ACTION in $ACTIONS; do
		Exec $SETUP_OBJ "$ACTION"
		if [ $? -ne 0 ]; then
			local IFS="$LINEFEED"
			for UNWIND_ACTION in $UNWIND_ACTIONS; do
				Revert $SETUP_OBJ "$UNWIND_ACTION"
			done
			return 1
		fi
		local UNWIND_ACTIONS="${ACTION}${LINEFEED}${UNWIND_ACTIONS}"
	done
}

Uninstall() {
	local SETUP_OBJ=$1
	eval __LOCAL_ACTIONS="\$$SETUP_OBJ"
	local ACTIONS="$__LOCAL_ACTIONS"
	local IFS="$LINEFEED"
	for ACTION in $ACTIONS; do
		local UNWIND_ACTIONS="${ACTION}${LINEFEED}${UNWIND_ACTIONS}"
	done
	for UNWIND_ACTION in $UNWIND_ACTIONS; do
		Revert $SETUP_OBJ "$UNWIND_ACTION"
	done
}

AddAction() {
	local V=$1
	shift
	eval __LOCAL_OLDVAL="\$$V"
	[ -z "$__LOCAL_OLDVAL" ] || eval $V="\$${V}\"$LINEFEED\""
	eval $V="\$${V}\$1"
	shift
	for ARG in "$@"; do
		eval $V="\$${V}\ \\\"\$ARG\\\""
	done;
}
