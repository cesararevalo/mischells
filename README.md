# mischells
Miscellaneous Shell Scripts

## Backup

This shell script makes a backup of a folder to another folder in a very safe manner.

This script receives two parameters, first is the source folder to be backed up, and secondly is the destination folder where we want to store the backup.

This script will backup recursively through the sub-directories of the source folder. It will created sub-folders in the destination folder if they do not exist in the destination.

For copying the files it will use rsync. If the file being copied already exists in the destination folder, it will create a backup out of the existing file and suffix it with a ~ (uses the --backup option of the rsync command). The copying of the file will timeout after 1 second if there is not movement of data. If the destination file already exists and the checksums are the same as the source file, then the file will not be copied again nor a backup made.

This shell script will keep a backup log of the file paths that have been successfully backed up. If for whatever reason the backup script needs to be restarted then this log prevents the reprocessing of the successful files.

This shell script does not backup .dropbox files. This shell script will output messages for files that failed to be copied, search for "Failed to copy"
