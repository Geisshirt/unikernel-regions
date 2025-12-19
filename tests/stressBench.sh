#!/bin/bash

request=25

# Make setup, echo and reverse echo.
make setup
make echo-ex-app

# Run echo.
nohup ./echo.exe 2>&1 &
echo $! > PID.txt

sleep 1

# Spawn each request thread.
for ((i=1; i<=request; i++)); do
    (
        cat tests/numbers_short.txt | nc -Nw1 10.0.0.2 8081 > "tests/out_short_${i}.txt" 2>&1
    ) & 
done

sleep 1

# Compare each output file with the reference.
for ((i=1; i<=request; i++)); do
    if diff tests/numbers_short.txt "tests/out_short_${i}.txt" > /dev/null; then
        echo "TCP $i: Files are the same."
    else
        echo "TCP $i ERROR: Files are different!"
        exit 1
    fi
done

# Clean up files.
for ((i=1; i<=request; i++)); do
    rm "tests/out_short_${i}.txt"
done

# Close echo and reverse echo.
kill $(cat PID.txt)
rm PID.txt