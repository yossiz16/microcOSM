#!/bin/bash
set -e
flag=true
export PGHOST=$POSTGRES_TILER_HOST
export PGPORT=$POSTGRES_TILER_PORT
export PGDATABASE=$POSTGRES_TILER_DB
export PGUSER=$POSTGRES_TILER_USER
export PGPASSWORD=$POSTGRES_TILER_PASSWORD
replicationDirectory=$REPLICATION_DIR
expiredDirectory=$EXPIRED_DIR
lastAppend=0

function firstImport () {
    echo "first import on db using osm2pgsql"

    osm2pgsql \
    --create \
    --slim \
    -G \
    --hstore \
    --tag-transform-script /src/openstreetmap-carto.lua \
    -C 2500 \
    --number-processes 4 \
    -S /src/openstreetmap-carto.style \
    /src/first-osm-import.osm
}

function updateDataLoop () {
    while true; do 
    if [ -f $replicationDirectory/state.txt ]; then
        # get the relevant change based on the replication sequenceNumber
        sequenceNumber=$(cat $replicationDirectory/state.txt | grep sequenceNumber | cut -d "=" -f2)
        
        # get the last appended replication number
        lastAppend=$(cat $expiredDirectory/state.txt | grep lastAppend | cut -d "=" -f2)

        if [ -z "$lastAppend" ]; then
                lastAppend=-1
        fi
        
        if [ ! $lastAppend -eq $sequenceNumber ]; then
            echo "starting loop from $lastAppend to $sequenceNumber"
            
            # populate the currentlyExpired file with expired tiles
            for (( i=($lastAppend+1); i <= $sequenceNumber; ++i ))
            do
                dir1=$(parseIntegerToDirectoryNumber "$(($i/1000000))")
                dir2=$(parseIntegerToDirectoryNumber "$(($i/1000))")
                state=$(parseIntegerToDirectoryNumber "$(($i%1000))")
		
		        mkdir -p $expiredDirectory/$dir1
                mkdir -p $expiredDirectory/$dir1/$dir2
                
                OSC=$replicationDirectory/$dir1/$dir2/$state.osc.gz

                # create\append changes and push expired tiles into the relevant directory
                if [ -f "$OSC" ]; then
                    osm2pgsql \
                    --append \
                    --slim \
                    -G \
                    --hstore \
                    --tag-transform-script /src/openstreetmap-carto.lua \
                    -C 2500 \
                    --number-processes 4 \
                    -S /src/openstreetmap-carto.style \
                    $OSC \
                    -e17 \
                    -o $expiredDirectory/$dir1/$dir2/$state-expire.list
                fi
            done
            
            # create the state file if needed
            if [ ! -f $expiredDirectory/state.txt ]; then
                touch $expiredDirectory/state.txt
            fi
            
            # update the sequenceNumber and lastAppend in the expiredDirectory state file
            addOrUpdateToFile "sequenceNumber" "$sequenceNumber" $"$expiredDirectory/state.txt"
            addOrUpdateToFile "lastAppend" "$sequenceNumber" $"$expiredDirectory/state.txt"
        fi
    fi
    sleep $OSM2PGSQL_UPDATE_INTERVAL
    done
}

function parseIntegerToDirectoryNumber () {
    echo $( printf '%03d' $1)
}

# (textToBeAdded, fileDirectory, equalsTo, 
function addOrUpdateToFile () {
    if grep -q "$1" $3
    then
        sed -i -e 's/.*'$1'=.*/'$1'='$2'/g' $3
    else
        echo "$1=$2" >> $3
    fi
}

while "$flag" = true; do
    echo "trying to connect to $POSTGRES_TILER_HOST..."
    pg_isready -h $POSTGRES_TILER_HOST -p 5432 >/dev/null 2>&2 || continue

        # Change flag to false to stop ping the DB
        flag=false
        hasData=$(psql "postgresql://$POSTGRES_TILER_USER:$POSTGRES_TILER_PASSWORD@$POSTGRES_TILER_HOST/$POSTGRES_TILER_DB" \
        -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'" | sed -n 3p | sed 's/ //g')
        echo $hasData

        # has 5 by default
        if [ $hasData  -le 5 ]; then
            firstImport
        fi
        updateDataLoop
done
