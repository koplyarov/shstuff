msg_MkDir() { echo "Creating directory '$1'"; }
do_MkDir() { [ -d $1 ] || mkdir $1; }
undo_MkDir() { [ ! -d $1 ] || [ ! -z "`ls -1A $1`" ] || rm -r $1; }

msg_Symlink() { echo "Creating $2 -> $1"; }
do_Symlink() { ln -s $1 $2; }
undo_Symlink() { [ "`readlink $2`" != "$1" ] || rm $2; }

msg_Patch() { echo "Applying patch $2"; }
do_Patch() { patch --dry-run $1 < $2 && patch $1 < $2; }
undo_Patch() { patch --dry-run --no-backup --reject-file=- -f -R $1 < $2 && patch --no-backup --reject-file=- -f -R $1 < $2; }

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
