#!/usr/bin/bash
set -e

for bk in "$@"
do
    if [[ $bk =~ ^[0-9][0-9]\.[0-9][0-9]$ ]]; then 
        ppn=$(catmandu convert kxpnorm --query pica.bkl=$bk --fix 'retain_field(_id)' to CSV --header 0)
        if [[ $ppn =~ ^[0-9]+[0-9X]$ ]]; then
            echo "$bk,$ppn"
        else
            echo >&2 "Failed to get unique PPN for BK $bk"
        fi
    fi
done
