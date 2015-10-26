#!/bin/bash

# Description:
#
# This shell script makes a backup of a folder to another folder in a very safe manner.
#
# This script receives two parameters, first is the source folder to be backed up, and secondly is the destination
# folder where we want to store the backup.
#
# This script will backup recursively through the sub-directories of the source folder. It will created sub-folders in
# the destination folder if they do not exist in the destination.
#
# For copying the files it will use rsync. If the file being copied already exists in the destination folder, it will
# create a backup out of the existing file and suffix it with a ~ (uses the --backup option of the rsync command). The
# copying of the file will timeout after 1 second if there is not movement of data. If the destination file already
# exists and the checksums are the same as the source file, then the file will not be copied again nor a backup made.
#
# This shell script will keep a backup log of the file paths that have been successfully backed up. If for whatever
# reason the backup script needs to be restarted then this log prevents the reprocessing of the successful files.
#
# This shell script does not backup .dropbox files.
#
# This shell script will output messages for files that failed to be copied, search for "Failed to copy"

usage() {
    cat <<EOM
    Usage:
    $(basename $0) COPY_FROM COPY_TO
        COPY_FROM is path to source folder to backup
        COPY_TO is path to destination folder of backup

EOM
    exit 0
}

[ $# -lt 2 ] && { usage; }

shopt -s nullglob

COPY_FROM=$1
COPY_TO=$2
BACKUP_LOG=backup.log

function traverse_folder
{
    FOLDER="${1}"
    echo "Starting to copy folder ${FOLDER}"

    # find excludes .dropbox folders
    find "${FOLDER}" \( ! -iname "*.dropbox" \) -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d '' FILENAME; do

        if grep -q "${FILENAME}" "${BACKUP_LOG}"; then
            echo "    Skipping ${FILENAME} because it's already been processed"
            continue
        fi

        fd=$(sed -e "s|${COPY_FROM}|${COPY_TO}|g" <<< ${FILENAME})

        if [[ -d "${FILENAME}" ]]; then
            echo "    Copying folder ${FILENAME} to ${fd}"

            if [[ -d "${fd}" ]]; then
                echo "        Folder to copy ${fd} already existed, skipping making it"
            else
                echo "        Folder to copy ${fd} does not exist, will make it now"
                mkdir -p "$fd"
            fi

            traverse_folder "${FILENAME}"
        elif [[ -f "${FILENAME}" ]]; then
            echo "    Copying file ${FILENAME} to ${fd}"
            {
                rsync --timeout=1 --checksum --backup "${FILENAME}" "${fd}"
            } || {
                echo "    Failed to copy file ${FILENAME} to ${fd}"
                continue
            }
        else
            echo "    ${FILENAME} is not valid"
        fi

        echo ${FILENAME} >> ${BACKUP_LOG}
    done
}


if [[ -d "${COPY_FROM}" ]]; then
    traverse_folder "${COPY_FROM}"
elif [[ -f "${COPY_FROM}" ]]; then
    fd=$(sed -e "s|${COPY_FROM}|${COPY_TO}|g" <<< ${COPY_FROM})
    echo "Copying file ${COPY_FROM} to ${fd}"
    rsync --checksum --backup "${COPY_FROM}" "${fd}"
else
    echo "${COPY_FROM} is not valid"
    exit 1
fi
