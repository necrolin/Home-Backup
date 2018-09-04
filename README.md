# Home Backup (CLI)

## Description:

This is a quick shell script that I typed up to do backups of my home
directory to an external hard drive. The script can be easily modified
to skip or backup any directory in $HOME.

The script itself uses __tar__ to backup smaller directories while using
 __cp__ to backup larger multi-gig directories. The reasoning is that
 multi-gig tar files are slow to open and annoying to use.

3 levels of incremental backups are created by the program:
1. Full backups
2. Monthly backups (or everything since the last full backup)
3. Weekly backups

The program automatically selects the type of backup to do based on the
existence of a previous backup (full backups are done before monthly
backups for example) and the time stamps found on the backups.

## Why?

This was something I wrote up as a student just for practice. I found
that the script was good enough for my purposes and the other, probably
much better and faster, backup programs that came with my Linux distro
were both annoying to use and caused my CPU to run really hot. I've 
continued to use this as a force of habit.

## Usage

1. Edit the DESTINATION location, the first uncommented line right at the
top of the file, to point to where you want your backups to go.
2. Modify the list of directories to skip or copy. This means:
  - Lines that start with "--exclude" skip a directory
  - LInes that start with  "cp  -auv" copy files
 3. Run the script
