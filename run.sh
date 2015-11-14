#!/bin/bash

export MALLOC_ARENA_MAX=1
export JRUBY_OPTS="-J-Xmx384m -J-Xms384m"

bin/rake db:migrate

eval "bin/puma -t 5:5 -p $PORT -e $RACK_ENV > log/puma.log 2>&1 &"
pid=$!

echo -n "Waiting for process to start..."

until $(curl -o /dev/null -s -I -f 0.0.0.0:$PORT); do
  sleep 5
  echo -n "."
done

echo "Process started! (PID $pid)"

SMAPS_LOG=log/smaps.log
touch $SMAPS_LOG

while true; do
  echo "Parsing smaps for PID $pid" >> $SMAPS_LOG
  ruby parse.rb /proc/${pid}/smaps >> $SMAPS_LOG
  echo "===========" >> $SMAPS_LOG

  tail -n 8 $SMAPS_LOG

  echo -n "Making requests..."
  for i in $(seq 1 999); do curl -s -o /dev/null -d "widget[name]=$(openssl rand -base64 32)" 0.0.0.0:$PORT/widgets; done
  echo "done"
done
