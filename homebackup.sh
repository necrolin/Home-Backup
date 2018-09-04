#!/bin/bash

# - The script performs incremental backups of the current user's home dir
#
# - Tar is used for multiple small files
# - CP is used for larger, multi-gig, directories. This is because
# large tar files take a very long time to unpack.

# Global variables are evil, but...

# EDIT to set the backup location!!!
DESTINATION=""

# Dynamic for any user on any Linux system. Provide a location for snapshots.
SNAPSHOTS="$HOME/.homebackup/snapshots"
CONFIG="$HOME/.homebackup"

# Global Convenience variables
BIN="$HOME/bin"
MUSIC="$HOME/Music"
VIDEO="$HOME/Videos"
DESKTOP="$HOME/Desktop"
DOWNLOADS="$HOME/Downloads"
PICTURES="$HOME/Pictures"
EBOOKS="$HOME/Documents/EBooks"

# Do incremental backup of files using cp
# Options:
# -u -> copy updated files only to save on time
# -a -> archive, meaning recursive
# -v -> verbose output for debugging
copy_big_dirs()
{
    echo "[START] Copying large directories. This may take a LONG time..."
    
    cp -auv "$BIN" "$DESTINATION"
    cp -auv "$MUSIC" "$DESTINATION"
    cp -auv "$VIDEO" "$DESTINATION"
    cp -auv "$EBOOKS" "$DESTINATION"
    cp -auv "$PICTURES" "$DESTINATION"
    
    echo "[OK] Copy Complete"
}

# Prepare snapshot files for tar.
# See run_backup() for more details
prepare_snapshot_files()
{
    case "$1" in
    'full')
        if test -f "$SNAPSHOTS/$1.dat"
        then
            rm -f "$SNAPSHOTS/$1.dat"
            echo "[OK] Removed old snapshot: $CONFIG/$1.dat"
        fi
        ;;
        
    'monthly')
        cp "$SNAPSHOTS/full.dat" "$CONFIG/$1.dat"
        ;;
        
    'weekly')
        cp "$SNAPSHOTS/monthly.dat" "$CONFIG/$1.dat"
        ;;
        
    'daily')
        cp "$SNAPSHOTS/weekly.dat" "$CONFIG/$1.dat"
        ;;
        
    *)
        echo "[ERROR] Invalid argument passed to run_backup"
        exit 1
    esac
    
    echo "[OK] Snapshot files ready for tar operation"
}

# Run tar while skipping over directories with large files
run_tar()
{
    tar -cf "$DESTINATION/$1_backup.tar" \
    --listed-incremental "$CONFIG/$1.dat" \
    --exclude=".*" \
    --exclude="$VIDEO" \
    --exclude="$MUSIC" \
    --exclude="$PICTURES" \
    --exclude="$EBOOKS" \
    --exclude="$DOWNLOADS" \
    --exclude="$DESKTOP" \
    --exclude="$BIN" \
    --label="$1 backup executed on: $(date)" \
     "$HOME"
    
    echo "[OK] tarball created"
}

# Prepare snapshot files for next run. 
# See run_backup() for more details
run_post_tar_operations()
{
    if [ "$1" = "full" ]
    then
        mv -f "$CONFIG/$1.dat" "$SNAPSHOTS/$1.dat"
    fi

    # Copy config files to prepare for next run
    if [ "$1" != "full" ] && [ "$1" != "daily" ]
    then
        cp "$CONFIG/$1.dat" "$SNAPSHOTS/$1.dat"
    fi
    
    echo "[OK] Post tar operations completed."
}

# Run a backup. Options are: full, monthly, weekly, daily
# NOTE: Two sets of snapshot files need to be kept otherwise running the same
# backup twice in a row will result in an overwrite of the original
# snapshot file. This will then cause data loss because snapshots will
# be done based on incomplete data. Hence, the moving around of snapshot files.
run_backup()
{
    echo "Starting $1 backup..."
    
    # Prepare snapshot files as necessary
    prepare_snapshot_files "$1"
    run_tar "$1"
    run_post_tar_operations "$1"
    
    # Run a cp on multi-gig directories to avoid huge tar files
    # Run weekly because these files see few changes
    if [ "$1" = "weekly" ] || [ "$1" = "full" ]
    then
        copy_big_dirs
    fi
    
    echo "[OK] Backup complete. Goodbye!"
    exit 0
}

main()
{    
	# If running the first time to some maintenance and a full backup
	if test ! -d "$CONFIG"
	then
		mkdir -p "$SNAPSHOTS"
        chmod -R 700 "$CONFIG"
        echo "[OK] Setup Complete. '$SNAPSHOTS' directory created"
        run_backup "full"
	fi
    
    # Run correct backup based on non-existence of that type of backup
    if test ! -e "$SNAPSHOTS/full.dat" || test $(find "$SNAPSHOTS/full.dat" -mtime +365)
    then
        run_backup "full"
    elif test ! -e "$SNAPSHOTS/monthly.dat" || test $(find "$SNAPSHOTS/monthly.dat" -mtime +31)
    then
        run_backup "monthly"
    elif test ! -e "$SNAPSHOTS/weekly.dat" || test $(find "$SNAPSHOTS/weekly.dat" -mtime +7)
    then
        run_backup "weekly"
    else
        run_backup "daily"
    fi
}

# Verify backup destination is mounted || exists
if test ! -d "$DESTINATION"
then
    echo "Error: Cannot find external HDD"
    exit 1
else
    echo "[OK] External HDD found"
fi

main
