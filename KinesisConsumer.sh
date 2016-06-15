#!/bin/bash -f

#
# AWS Kinesis consumer script. Kinesis consumer pull model.
#
# It continuously reads the records from each Kinesis shards independently and in parallel.
# Then sends them to stdout. Therefore, the typical usage is piping the output of this script
# to a real-time processing application.
#
# See the comments and prerequisites in KinesisCommon.sh
#
# Resharding is not supported.
#

#
# In an infinite loop gets the records from the shard.
#
# $1: shard id
# $2: shard iterator type
# $3: temp filename
#
getShardRecords() {
    local SHARD_ID=$1
    local SHARD_ITERATOR_TYPE=$2
    local SHARD_TMP_FILE=${3}-${1}
    local RECORD_COUNT=0

    # get the first shard iterator of the shard
    $AWSK get-shard-iterator --stream-name $STREAM_NAME --shard-id $SHARD_ID --shard-iterator-type $SHARD_ITERATOR_TYPE > $SHARD_TMP_FILE
    [[ $? == 0 ]] || showMsgAndExit 1 "Failed to get initial iterator for shard $SHARD_ID of stream $STREAM_NAME"

    local SHARD_ITERATOR_JSON_NAME="ShardIterator"
    while true
    do
        # shard iterator is valid only for 5 minutes and is limited to 5 transactions per second per account per shard
        local SHARD_ITERATOR=$(cat $SHARD_TMP_FILE | jq --raw-output ".${SHARD_ITERATOR_JSON_NAME}")
        [[ $SHARD_ITERATOR == "null" ]] && {
            showMsgAndExit 1 "Null shard iterator. Stream $STREAM_NAME closed because of split-shard/merge-shards"
        }

        # can get up to 10MB of records with --limit option, max 10,000
        $AWSK get-records --shard-iterator "$SHARD_ITERATOR" --limit 1 > $SHARD_TMP_FILE

        local PARTITION_KEY=$(cat $SHARD_TMP_FILE | jq --raw-output '.Records[0].PartitionKey')
        local SEQ_NUM=$(cat $SHARD_TMP_FILE | jq --raw-output '.Records[0].SequenceNumber')

        # records with null value fields are expected from time to time
        [[ "$PARTITION_KEY" -eq "null" || "$SEQ_NUM" -eq "null" ]] || {
            let RECORD_COUNT++

            # data in Kinesis shard is Base64 encoded
            local DATA=$(cat $SHARD_TMP_FILE | jq --raw-output '.Records[0].Data' | base64 --decode)

            echo $(cat $SHARD_TMP_FILE | jq --raw-output '.Records[0].Data' | base64 --decode)
            debugMsg "\tSHARD_ID=$SHARD_ID\n\tPARTITION_KEY=$PARTITION_KEY\n\tSEQ_NUM=$SEQ_NUM\n\tSHARD_RECORD_COUNT=$RECORD_COUNT\n"
        }

        # consider sleeping for one second to avoid exceeding the limit on getRecords() frequency.

        SHARD_ITERATOR_JSON_NAME="NextShardIterator"
    done
}

source ./KinesisCommon.sh

SHARD_ID_LIST=$(cat $TMP_FILE | jq --raw-output '.StreamDescription.Shards[].ShardId')
debugMsg "SHARD_ID_LIST=$SHARD_ID_LIST"
cat /dev/null > $TMP_FILE

# resharding is not supported
for SHARD_ID in $SHARD_ID_LIST
do
    getShardRecords $SHARD_ID LATEST $TMP_FILE >> $TMP_FILE &
done

tail -f $TMP_FILE


