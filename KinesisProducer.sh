#!/bin/bash -f

#
# AWS Kinesis producer script. It reads from its stdin and publishes them to Kinesis.
# So, typical usage is piping the output of another CLI e.g. tail, to this script.
#
# See the comments and prerequisites in KinesisCommon.sh.
#

source ./KinesisCommon.sh

# read from stdin and publish them to Kinesis
RECORD_COUNT=0
while read RECORD
do
    PARTITION_KEY=$(./KinesisPartitionKeyGenerator.sh $STREAM_NAME $RECORD_COUNT "$RECORD")
    [[ $? == 0 ]] || showMsgAndExit 1 "$PARTITION_KEY"

    # Kinesis input should be max 50KB and will be kept for max 24 hours.
    #
    # The documentation mistakenly says that the record should be Base64 encoded as in:
    #   RECORD=$(echo "$RECORD" | base64)
    # That is not required as Kinesis will do that for us.
    #
    $AWSK put-record --stream-name $STREAM_NAME --partition-key $PARTITION_KEY  --data "$RECORD" > $TMP_FILE
    [[ $? == 0 ]] || showMsgAndExit 1 "Failed to put record in stream $STREAM_NAME"

    let RECORD_COUNT++

    [[ ${KINESIS_DEBUG,,} == "true" ]] && {
        SHARD_ID=$(cat $TMP_FILE | jq --raw-output '.ShardId')
        SEQ_NUM=$(cat $TMP_FILE | jq --raw-output '.SequenceNumber')
        echo -e "$RECORD\n\tSHARD_ID=$SHARD_ID\n\tPARTITION_KEY=$PARTITION_KEY\n\tSEQ_NUM=$SEQ_NUM\n\tTOTAL_RECORD_COUNT=$RECORD_COUNT\n"
    } || {
        echo -n "."
        eraseDots
    }
done

showMsgAndExit 0 "\n$RECORD_COUNT records published to Kinesis stream $STREAM_NAME"


