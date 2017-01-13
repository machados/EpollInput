#!/bin/bash

FIFOS=$(for i in {1..20}; do echo -n "fifo$i "; done)

mkfifo $FIFOS

./swift/.build/debug/EpollInputInSwift $FIFOS > epoll.out 2>&1 &
EPOLL_PID=$!

./test/data_generator.py $FIFOS > generator.out 2>&1 &
GEN_PID=$!

echo "Generator Pid is $GEN_PID"

trap "kill -TERM $GEN_PID" SIGINT SIGTERM

wait $GEN_PID
wait $EPOLL_PID

rm -f $FIFOS
