#!/bin/sh -f

#
# This is a private script called only by the Kinesis producer to generate partition keys.
#
# The following is the simplest implementation.  By changing the algorithm which could
# potentially use the fields from the record, the producer can drive the streaming data
# parallelism scheme.
#

PROG=$(basename $0)
USAGE="Usage: $PROG stream-name record-count record"

[[ $# == 3 ]] || {
    echo $USAGE
    exit 1
}

STREAM_NAME=$1
shift
RECORD_COUNT=$1
shift
RECORD="$@"                   # not used

PARTITION_KEY=${STREAM_NAME}-"PartitionKey-${RECORD_COUNT}"

# partition keys must be unicode strings max 256B
[[ ${#PARTITION_KEY} -gt 256 ]] && {
    echo "PartitionKey too long: $PARTITION_KEY"
    exit 1
}

echo $PARTITION_KEY
exit 0

