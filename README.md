AWS Kinesis Scripts
===================
Prototyping Kinesis Capabilities. The producer and the consumer can run independently.
As such they can be used extensively during production code development. These scripts
assume proper credentials are provided to run the <b>aws</b> CLI tool.

These scripts are only for the proof of concept and are not meant to perform as fast
because the producer is single threaded and the consumer uses the CLI for every single
record in a pull model.

Dependencies
------------
* The <b>aws</b> CLI tool. Download from <u>http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html</u>
* The <b>jq</b> JSON processor. Download from <u>http://stedolan.github.io/jq</u>

KinesisProducer.sh
------------------
The AWS Kinesis producer script. It reads from its stdin and publishes them to Kinesis.
So, typical usage is piping the output of another CLI to this script.

    tail -f <some-log-file> | KinesisProducer.sh <stream-name>
e.g.

    tail -f orders.logs | KinesisProducer.sh Orders

Set the <b>KINESIS_DEBUG</b> environment variable to <b>true</b> to get debug log output.

The <b>KinesisPartitionKeyGenerator.sh</b> is a private script called only by <b>KinesisProducer.sh</b>
to generate partition keys. By changing the algorithm the producer can change the streaming data
parallelism scheme.

KinesisConsumer.sh
------------------
The AWS Kinesis consumer script. It uses the Kinesis consumer pull model by continuously reading the records from the
Kinesis stream and sends them to stdout. The typical usage is piping the output of this script to a real-time
processing application.

Send the output to stdout for testing the producer by

    KinesisConsumer.sh <stream-name>
e.g.

    KinesisProducer.sh Orders


Pipe the output to a real-time application by

    KinesisConsumer.sh <stream-name> | real-time-processor-application


Set the <b>KINESIS_DEBUG</b> environment variable to <b>true</b> to get debug log output.

Each shard in the stream is handled independently and in parallel.  Therefore, in a multi-shard
stream, the sequence of the consumed records will not be the same as the ones produced.
