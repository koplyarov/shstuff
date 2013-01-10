#!/bin/bash


Exec() {
	local IFS=" "
	local SETUP_OBJ=$1
	shift
	local ACTION="$@"
	local MSG=`eval msg_$ACTION`
	if [ "`GetSetupParam $SETUP_OBJ Verbose`" -eq "0" ]; then
		Log Log_NoLineFeed "$MSG..."
		local OUT;
		if OUT=`eval do_$ACTION 2>&1`; then
			Log Log_NoPreamble Log_ColoredMsg "OK"
			return 0
		else
			Log Error Log_NoPreamble Log_ColoredMsg "Fail!"
			Log Error "$OUT"
			return 1
		fi
	else
		Log "$MSG..."
		if eval do_$ACTION 2>&1; then
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
		local OUT;
		if OUT=`eval undo_$ACTION 2>&1`; then
			Log Log_NoPreamble Log_ColoredMsg "OK"
		else
			Log Warning Log_NoPreamble Log_ColoredMsg "Fail!"
			Log Warning "$OUT"
		fi
	else
		Log "Reverting '$MSG'..."
		if eval undo_$ACTION 2>&1; then
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
	local IFS="$LINEFEED"
	for ACTION in $ACTIONS; do
		if ! Exec $SETUP_OBJ "$ACTION"; then
			IFS="$LINEFEED"
			for UNWIND_ACTION in $UNWIND_ACTIONS; do
				Revert $SETUP_OBJ "$UNWIND_ACTION"
			done
			return 1
		fi
		UNWIND_ACTIONS="${ACTION}${LINEFEED}${UNWIND_ACTIONS}"
	done
}

Uninstall() {
	local SETUP_OBJ=$1
	local ACTIONS
	local UNWIND_ACTIONS
	eval ACTIONS="\$$SETUP_OBJ"
	local IFS="$LINEFEED"
	for ACTION in $ACTIONS; do
		UNWIND_ACTIONS="${ACTION}${LINEFEED}${UNWIND_ACTIONS}"
	done
	for UNWIND_ACTION in $UNWIND_ACTIONS; do
		Revert $SETUP_OBJ "$UNWIND_ACTION"
	done
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
