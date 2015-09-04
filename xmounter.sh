#!/bin/bash
# X Mounter, GPL

export TEXTDOMAIN="xmounter"
source gettext.sh
_VERSION="@VERSION@"
_DATADIR="$HOME/.config/$TEXTDOMAIN"
_ICON="/usr/share/pixmaps/$TEXTDOMAIN.xpm"
mkdir -p $_DATADIR

for i in gdialog Xdialog ; do
  which $i && _DIALOG=$i
done
if test "$_DIALOG" == gdialog && `id -u` == "0" ; then
  sed -i 's/"--column", $element;/"--column", "", "--text=$element";/g' `which gdialog`
fi

_ABOUT=`eval_gettext "X Mounter "`$_VERSION`eval_gettext "\nGPL\n\nPlease select an action..."`
_ACT1=`eval_gettext "Add a new connection"`
_ACT2=`eval_gettext "Mount a connection"`
_ACT3=`eval_gettext "Edit a connection"`
_ACT4=`eval_gettext "Unmount a connection"`
_ACT5=`eval_gettext "Delete a connection"`
_ACT6=`eval_gettext "Local devices"`
_ACT7=`eval_gettext "Remote sites"`
_INPUT=`eval_gettext "Input"`
_INFORMATION=`eval_gettext "Information"`
_ENTER=`eval_gettext "Please enter data for the connection..."`
_DATA1=`eval_gettext "Name:"`
_DATA2=`eval_gettext "Comment:"`
_DATA3=`eval_gettext "Type(smbfs,cifs,nfs,sshfs,ftpfs):"`
_DATA4=`eval_gettext "Location(hostname/path):"`
_DATA5=`eval_gettext "Username:"`
_DATA6=`eval_gettext "Password:"`
_DATA7=`eval_gettext "Connection mode:"`
_DATA8=`eval_gettext "Type(auto,ext3,vfat,ntfs,...):"`
_DATA9=`eval_gettext "Device(hda1,sda1,sdb1,...):"`

  if ls $_DATADIR/* ; then
    if ls $_DATADIR/.[a-zA-Z]* ; then
      _ACTIONS="\"add\" \"$_ACT1\" \"off\" \"mount\" \"$_ACT2\" \"off\" \"edit\" \"$_ACT3\" \"off\" \"unmount\" \"$_ACT4\" \"on\" \"delete\" \"$_ACT5\" \"off\""
    else
      _ACTIONS="\"add\" \"$_ACT1\" \"off\" \"mount\" \"$_ACT2\" \"on\" \"edit\" \"$_ACT3\" \"off\" \"unmount\" \"$_ACT4\" \"off\" \"delete\" \"$_ACT5\" \"off\""
    fi
  else
    _ACTIONS="\"add\" \"$_ACT1\" \"on\" \"mount\" \"$_ACT2\" \"unavailable\" \"edit\" \"$_ACT3\" \"unavailable\" \"unmount\" \"$_ACT4\" \"unavailable\" \"delete\" \"$_ACT5\" \"unavailable\""
  fi
  _ACTION=`eval $_DIALOG --title \"$TEXTDOMAIN\" --icon \"$_ICON\" --radiolist \"$_ABOUT\" 23 50 0 $_ACTIONS 2>&1`
  test -z "$_ACTION" && exit
  if test "$_ACTION" == add ; then
    _MODES="\"local\" \"$_ACT6\" \"off\" \"remote\" \"$_ACT7\" \"on\""
    _MODE=`eval $_DIALOG --title \"$_INPUT\" --radiolist \"$_DATA7\" 12 30 0 $_MODES 2>&1`
    if test -n "$_MODE" ; then
      if test "$_MODE" == local ; then
        /sbin/fdisk -l | grep /dev/ | $_DIALOG --title `eval_gettext "Available Devices"` --no-cancel --logbox - 20 85
      fi
      _CONNECTION=`$_DIALOG --title "$_INPUT" --inputbox "$_DATA1" 8 40 "NewConnection" 2>&1`
      if test -n "$_CONNECTION" && ( test ! -f "$_DATADIR/$_CONNECTION.$_MODE" || $_DIALOG --title "$_INPUT" --yesno "`eval_gettext "Do you want to overwrite"`\n$_CONNECTION ?" 7 38 ) ; then
        if test "$_MODE" == local ; then
          _ANSWER=`$_DIALOG --title "$_INPUT" --separator "," --3inputsbox "$_ENTER" 19 40 "$_DATA2" "New Device" "$_DATA3" "auto" "$_DATA4" "hda1" 2>&1`
        else
          _ANSWER=`$_DIALOG --title "$_INPUT" --separator "," --3inputsbox "$_ENTER" 19 40 "$_DATA2" "New File System" "$_DATA3" "sshfs" "$_DATA4" "192.168.0.1/root" 2>&1`
        fi
        if test -n "$_ANSWER" ; then
          _COMMENT=`cut -d "," -f 1 <<< $_ANSWER`
          _TYPE=`cut -d "," -f 2 <<< $_ANSWER`
          _LOCATION=`cut -d "," -f 3 <<< $_ANSWER`
          echo -e "_COMMENT=\"$_COMMENT\"\n_TYPE=\"$_TYPE\"\n_LOCATION=\"$_LOCATION\"" > "$_DATADIR/$_CONNECTION.$_MODE"
        fi
      fi
    fi
  else
    _ITEMS=""
    for i in $_DATADIR/* ; do
      _COMMENT=""
      source "$i"
      _ITEMS="$_ITEMS \"`basename "$i"`\" \"($_COMMENT)\""
    done
    case "$_ACTION" in
      mount) _TEXT=`eval_gettext "mount."` ;;
      edit) _TEXT=`eval_gettext "edit."` ;;
      unmount) _TEXT=`eval_gettext "unmount."` ;;
      delete) _TEXT=`eval_gettext "delete."` ;;
    esac
    _HELP=`eval_gettext "Please select a connection to "`$_TEXT
    _ANSWER=`eval $_DIALOG --title \"$TEXTDOMAIN\" --menu \"$_HELP\" 16 52 0 $_ITEMS 2>&1`
    _CONNECTION=${_ANSWER%.*}
    _MODE=${_ANSWER##*.}
    test -z "$_CONNECTION" && exit
    source "$_DATADIR/$_CONNECTION.$_MODE"
    _MOUNTDIR="$_DATADIR/.$_CONNECTION"
    _LINKDIR="$HOME/Desktop/$_CONNECTION"
    case "$_ACTION" in
	mount)
		if test -f "$_MOUNTDIR" ; then
		  $_DIALOG --no-buttons --title $_INFORMATION --info "`eval_gettext "The mount point exists!"`" 5 38 3000
		else
		  mkdir -p "$_MOUNTDIR"
		  case "$_TYPE" in
		    smbfs|cifs)
			_ANSWER=`$_DIALOG --title "$_INPUT" --separator "," --password=2 --2inputsbox "$_ENTER" 16 40 "$_DATA5" "" "$_DATA6" "" 2>&1`
			if test $? -eq 0 ; then
			  if test -n "$_ANSWER" ; then
			    _USERNAME=`cut -d "," -f 1 <<< $_ANSWER`
			    _PASSWORD=`cut -d "," -f 2 <<< $_ANSWER`
			    if test "$_TYPE" == smbfs ; then
			      mount -t smbfs -o "username=$_USERNAME,password=$_PASSWORD,codepage=cp950,iocharset=utf8" "//$_LOCATION" "$_MOUNTDIR"
			    else
			      mount -t cifs -o "username=$_USERNAME,password=$_PASSWORD" "//$_LOCATION" "$_MOUNTDIR"
			    fi
			  fi
			else
			  false
			fi
			;;
		    nfs)
			mount -t nfs "${_LOCATION/\//:/}" "$_MOUNTDIR"
			;;
		    sshfs)
			_USERNAME=`$_DIALOG --title "$_INPUT" --inputbox "$_DATA5" 8 40 "$USER" 2>&1`
			if test $? -eq 0 ; then
			  if test -n "$_USERNAME" ; then
			    sshfs "$_USERNAME@${_LOCATION/\//:/}" "$_MOUNTDIR"
			  else
			    sshfs "${_LOCATION/\//:/}" "$_MOUNTDIR"
			  fi
			else
			  false
			fi
			;;
		    ftpfs)
			_ANSWER=`$_DIALOG --title "$_INPUT" --separator "," --password=2 --2inputsbox "$_ENTER" 16 40 "$_DATA5" "" "$_DATA6" "" 2>&1`
			if test $? -eq 0 ; then
			  if test -n "$_ANSWER" ; then
			    _USERNAME=`cut -d "," -f 1 <<< $_ANSWER`
			    _PASSWORD=`cut -d "," -f 2 <<< $_ANSWER`
			    curlftpfs "ftp://$_USERNAME:$_PASSWORD@$_LOCATION" "$_MOUNTDIR"
			  else
			    curlftpfs "ftp://$_LOCATION" "$_MOUNTDIR"
			  fi
			else
			  false
			fi
			;;
		    *)
			if test "$_MODE" == local ; then
			  mount -t "$_TYPE" "/dev/$_LOCATION" "$_MOUNTDIR"
			else
			  false
			fi
			;;			
		    esac
		  if test $? -eq 0 ; then
		    if test `gconftool-2 -g /apps/nautilus/desktop/volumes_visible` != "true" ; then
		      ln -s "$_MOUNTDIR" "$_LINKDIR"
		    fi
		    $_DIALOG --no-buttons --title $_INFORMATION --info "`eval_gettext "The connection is mounted."`" 5 38 3000
		  else
		    rmdir "$_MOUNTDIR"
		    $_DIALOG --no-buttons --title $_INFORMATION --info "`eval_gettext "Error mounting the connection!"`" 5 38 3000
		  fi
		fi
		;;
	edit)
		_ANSWER=`$_DIALOG --title "$_INPUT" --separator "," --3inputsbox "$_ENTER" 20 40 "$_DATA2" "$_COMMENT" "$_DATA3" "$_TYPE" "$_DATA4" "$_LOCATION" 2>&1`
		if test -n "$_ANSWER" ; then
		  _COMMENT=`cut -d "," -f 1 <<< $_ANSWER`
		  _TYPE=`cut -d "," -f 2 <<< $_ANSWER`
		  _LOCATION=`cut -d "," -f 3 <<< $_ANSWER`
		  echo -e "_COMMENT=\"$_COMMENT\"\n_TYPE=\"$_TYPE\"\n_LOCATION=\"$_LOCATION\"" > "$_DATADIR/$_CONNECTION.$_MODE"
		fi
		;;
	unmount)
		if test -h "$_LINKDIR" ; then
		  rm -f "$_LINKDIR"
		fi
		if test -d "$_MOUNTDIR" ; then
		  if test "$_TYPE" == sshfs -o "$_TYPE" == ftpfs ; then
		    fusermount -u "$_MOUNTDIR"
		  else
		    umount "$_MOUNTDIR"
		  fi
		  if rmdir "$_MOUNTDIR" ; then
		    $_DIALOG --no-buttons --title $_INFORMATION --info "`eval_gettext "The connection is unmounted."`" 5 38 3000
		  else
		    $_DIALOG --no-buttons --title $_INFORMATION --info "`eval_gettext "Error unmounting the connection!"`" 5 38 3000
		  fi
		else
		  $_DIALOG --no-buttons --title $_INFORMATION --info "`eval_gettext "No point to unmount!"`" 5 38 3000
		fi
		;;
	delete)
		if $_DIALOG --title "$_INPUT" --yesno "`eval_gettext "Do you want to delete"`\n$_CONNECTION ?" 7 38 ; then
		  rm -f "$_DATADIR/$_CONNECTION.$_MODE"
		fi
		;;
    esac
  fi
