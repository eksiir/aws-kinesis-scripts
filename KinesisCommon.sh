#!/bin/bash -f

#
# AWS Kinesis common script for both the producer and consumer.
#
# It assumes proper credentials are provided e.g. in the ~/.aws/config
# To turn debugging on, set the KINESIS_DEBUG environment variable to "true"
#
# Dependencies:
#   jq JSON processor. Download from http://stedolan.github.io/jq
#

#
# $1: exit code
# $2: Message
#
showMsgAndExit() {
    local EXIT_CODE=$1
    shift
    echo -e $@
    [[ -f $TMP_FILE ]] && rm -f $TMP_FILE*
    exit $EXIT_CODE
}

#
# $1: debug message
#
debugMsg() {
    [[ ${KINESIS_DEBUG,,} == "true" ]] && echo -e $@
}

#
# $1: debug message
#
debugRawMsg() {
    [[ ${KINESIS_DEBUG,,} == "true" ]] && echo $@
}

#
# Erases displayed progress "." every 30 records.
#
eraseDots() {
    [[ $(( $RECORD_COUNT % 30 )) -eq 0 ]] && {
        echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b                              \b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    }
}

which jq  > /dev/null 2>&1
[[ $? == 0 ]] || showMsgAndExit 1 "jq is not installed or not in the PATH.\nDownload from http://stedolan.github.io/jq"

KINESIS_DEBUG=${KINESIS_DEBUG:-"false"}
PROG=$(basename $0)
AWSK="aws --region us-east-1 --endpoint-url https://kinesis.us-east-1.amazonaws.com kinesis"
USAGE="Usage: $PROG stream-name"

[[ $# == 1 ]] && {
        [[ ${1,,} == "help" ]] && showMsgAndExit 0 $USAGE

        STREAM_NAME=$1
} || {
    showMsgAndExit 1 $USAGE
}

TMP_FILE=/tmp/${PROG}-${STREAM_NAME}-$$-$RANDOM

$AWSK describe-stream --stream-name $STREAM_NAME > $TMP_FILE
[[ $? == 0 ]] || showMsgAndExit 1 "Failed to get the description of $STREAM_NAME"

STREAM_DESC=$(cat $TMP_FILE)
fgrep StreamStatus $TMP_FILE | fgrep ACTIVE > /dev/null 2>&1
[[ $? == 0 ]] || showMsgAndExit 1 "Stream $STREAM_NAME is not ACTIVE"

[[ ${KINESIS_DEBUG,,} == "true" ]] && cat $TMP_FILE
