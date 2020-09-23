TEXT_CYAN='\e[0;36m'
TEXT_RED='\e[0;31m'
TEXT_GREEN='\e[0;32m'
TEXT_PLAIN='\e[0m'
TEXT_BOLD='\e[1m'


explain() {
    echo
    echo -e "${TEXT_CYAN}trace${TEXT_PLAIN}: $1"
}

inform() {
    echo
    echo -e "${TEXT_GREEN}info${TEXT_PLAIN}: ${TEXT_BOLD}$1${TEXT_PLAIN}"
}

error() {
    echo
    echo -e "${TEXT_RED}error${TEXT_PLAIN}: $1"
}

abort() {
    error "$1"
    echo
    exit 1
}

finish() {
    inform "$1"
    echo
    exit 0
}

announce_step() {
    STEP_TITLE=$1
    echo
    echo "############################################################"
    echo "## $STEP_TITLE"
    echo
}

check_command() {
    COMMAND=$1
    
    echo -n "Looking for '$COMMAND'... "
    if which $COMMAND >/dev/null; then
        echo "found."
    else
        echo
        abort "Command '$COMMAND' not found or not in search path. Please install before proceeding."
    fi
}

detect_disk_reader() {
    for DEV in /dev/sd?; do
        if udisksctl info -b $DEV | grep PRS-XXX >/dev/null; then
            abort "Reader found but in recovery mode. Reboot in normal mode and retry."
        fi
        
        if udisksctl info -b $DEV | egrep 'drives/Sony_PRS_T2_' >/dev/null; then
            if udisksctl info -b $DEV | egrep 'IdLabel:\s+READER$' >/dev/null; then
                echo $DEV
                return 0
            fi
        fi
    done
}

detect_disk_sd() {
    for DEV in /dev/sd??; do
        if udisksctl info -b $DEV | grep 'by-id/usb-Sony_PRS-T2_SD' >/dev/null; then
            if udisksctl info -b $DEV | grep 'Partition:$' >/dev/null; then
                echo $DEV
                return 0
            fi
        fi
    done
    return 1
}

prs_mount_reader() {
    DEV=$(detect_disk_reader)
    udisksctl mount -b $DEV >/dev/null
    udisksctl info -b $DEV | grep 'MountPoints:' | tr -d ' ' | cut -d: -f2
}

prs_unmount_reader() {
    sync
    DEV=$(detect_disk_reader)
    udisksctl unmount -b $DEV
}

prs_mount_sd() {
    DEV=$(detect_disk_sd) || return 1

    udisksctl unmount -b $DEV >/dev/null
    udisksctl mount -b $DEV >/dev/null || return 1
    udisksctl info -b $DEV | grep 'MountPoints:' | tr -d ' ' | cut -d: -f2
}

prs_unmount_sd() {
    sync
    DEV=$(detect_disk_sd) || return 1
    udisksctl unmount -b $DEV
}
