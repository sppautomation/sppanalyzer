#!/usr/bin/awk
# Usage: 
# awk -f ./printFileSpecificLineMulti.awk <lnFile> <file>

FNR==NR {
    ln[$1] = FNR
    next
}
(FNR in ln) {
    print 
    getline
    while ( $0 ~ /^[^\[]/ || ( FNR in ln && $0 != "" ) ) {
        print 
        getline
    }
}

