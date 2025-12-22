#!/bin/bash

# Make setup and echo
make setup
make echo-ex-app

# Run echo
nohup ./echo.exe ip=10.0.0.2 2>&1 &
echo $! > PID.txt

# Send the large files.
sleep 1
cat tests/numbers_short.txt | nc -u -nw1 10.0.0.2 8082 > tests/out_short.txt
sleep 1
cat tests/numbers_long.txt | nc -N 10.0.0.2 8080 > tests/out_long.txt
sleep 3

# Close echo
kill $(cat PID.txt)

#Compare short
if diff tests/numbers_short.txt tests/out_short.txt > /dev/null; then
    echo "UDP: Files are the same."
else
    echo "UPD Error: Files are different!"
    exit 1
fi

#Compare long
if diff tests/numbers_long.txt tests/out_long.txt > /dev/null; then
    echo "TCP: Files are the same."
else
    echo "TCP Error: Files are different!"
    exit 1
fi

# Clean
rm PID.txt
rm nohup.out
rm tests/out_short.txt
rm tests/out_long.txt
