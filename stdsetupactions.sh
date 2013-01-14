msg_MkDir() { echo "Creating directory '$1'"; }
do_MkDir() { [ -d $1 ] || mkdir $1; }
undo_MkDir() { [ ! -d $1 ] || [ ! -z "`ls -1A $1`" ] || rm -r $1; }

msg_Symlink() { echo "Creating $2 -> $1"; }
do_Symlink() { ln -s $1 $2; }
undo_Symlink() { [ "`readlink $2`" != "$1" ] || rm $2; }

msg_Patch() { echo "Applying patch $3"; }
do_Patch() {
	local PATCH_FILE=`pwd`/$3
	cd $1
	patch --dry-run $2 < $PATCH_FILE && patch $2 < $PATCH_FILE;
	RET=$?
	cd -
	return $RET
}
undo_Patch() {
	local PATCH_FILE=`pwd`/$3
	cd $1
	patch --dry-run --no-backup --reject-file=- -f -R $2 < $PATCH_FILE && patch --no-backup --reject-file=- -f -R $2 < $PATCH_FILE;
	RET=$?
	cd -
	return $RET
}

msg_Cp() { echo "Copying $1 to $2"; }
do_Cp() { cp $1 $2; }
undo_Cp() { rm $2; }

msg_CpDir() { echo "Copying $1 to $2"; }
do_CpDir() { cp -r $1 $2; }
undo_CpDir() { rm -rf $2; }

msg_Mv() { echo "Moving $1 to $2"; }
do_Mv() { mv $1 $2; }
undo_Mv() { mv $2 $1; }

msg_Rm() { echo "Removing $1"; }
do_Rm() { rm $1; }
undo_Rm() { echo "There is no way to undo rm. =)"; return 1; }

msg_DownloadFile() { echo "Downloading '$1' to '$2'"; }
do_DownloadFile() { wget -O "$2" "$1"; }
undo_DownloadFile() { rm "$2/`basename "$1"`"; }

msg_CheckPackages() { echo "Checking linux packages"; }
do_CheckPackages() {
	local PACKAGES_TO_INSTALL
	local P
	for P in "$@"; do
		printf "%-32s" $P
		if CheckLinuxPackage $P; then
			printf 'OK\n'
		else
			printf 'Fail\n'
			PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $P"
		fi
	done
	if [ "$PACKAGES_TO_INSTALL" ]; then
		echo "You should install the following packages:$PACKAGES_TO_INSTALL"
		return 1
	fi
}
undo_CheckPackages() { echo "Nothing to do"; }

msg_SvnCheckout() { echo "Checking out '$1' to $2"; }
do_SvnCheckout() { svn checkout $1 $2; }
undo_SvnCheckout() { echo "Nothing to do"; }
