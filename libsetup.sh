#!/bin/bash


Exec() {
	local IFS=$' '
	local MSG=`eval msg_$ACTION`
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
}

Unwind() {
	local IFS=$' '
	local ACTION="$@"
	local MSG=`eval msg_$ACTION`
	Log Log_NoLineFeed "Unwinding '$MSG'..."
	__LOCAL_OUT=`eval undo_$ACTION 2>&1`
	if [ $? -eq 0 ]; then
		Log Log_NoPreamble Log_ColoredMsg " OK"
	else
		Log Log_NoPreamble Log_ColoredMsg Warning " Fail!"
		Log Warning "$__LOCAL_OUT"
	fi
}

CreateSetup()
{
	V=$1
	shift
	eval $V=\"\"
}

Install() {
	eval __LOCAL_ACTIONS="\$$1"
	local ACTIONS="$__LOCAL_ACTIONS"
	local IFS=$'\n'
	for ACTION in $ACTIONS; do
		Exec "$ACTION"
		if [ $? -ne 0 ]; then
			local IFS=$'\n'
			for UNWIND_ACTION in $UNWIND_ACTIONS; do
				Unwind "$UNWIND_ACTION"
			done
			return 1
		fi
		local UNWIND_ACTIONS="$ACTION
$UNWIND_ACTIONS"
	done
}

Uninstall() {
	eval __LOCAL_ACTIONS="\$$1"
	local ACTIONS="$__LOCAL_ACTIONS"
	local IFS=$'\n'
	for ACTION in $ACTIONS; do
		local UNWIND_ACTIONS="$ACTION
$UNWIND_ACTIONS"
	done

	local IFS=$'\n'
	for UNWIND_ACTION in $UNWIND_ACTIONS; do
		Unwind "$UNWIND_ACTION"
	done
}

AddAction() {
	V=$1
	shift
	eval __LOCAL_OLDVAL="\$$V"
	[ -z "$__LOCAL_OLDVAL" ] || eval $V="\$${V}\"$LINEFEED\""
	eval $V="\$${V}\$1"
	shift
	for ARG in "$@"; do
		eval $V="\$${V}\ \\\"\$ARG\\\""
	done;
}
