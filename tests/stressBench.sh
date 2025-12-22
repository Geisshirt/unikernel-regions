#!/bin/bash

request=15

# Make setup, echo and reverse echo.
make setup
make echo-ex-app

# Run echo.
nohup ./echo.exe ip=10.0.0.2 2>&1 &
echo $! > PID.txt

sleep 1

# Spawn each request thread.
for ((i=1; i<=request; i++)); do
    (
        cat tests/numbers_short.txt | nc -N 10.0.0.2 8080 > "tests/out_short_stream${i}.txt" 2>&1
        cat tests/numbers_short.txt | nc -N 10.0.0.2 8081 > "tests/out_short_full${i}.txt" 2>&1
        cat tests/numbers_short.txt | nc -Nw2 -u 10.0.0.2 8082 > "tests/out_short_udp${i}.txt" 2>&1
    ) & 
done

sleep 5

# Compare each output file with the reference.
for ((i=1; i<=request; i++)); do
    if diff tests/numbers_short.txt "tests/out_short_stream${i}.txt" > /dev/null; then
        # echo "TCP stream $i: Files are the same."
        :
    else
        echo "TCP stream $i ERROR: Files are different!"
        exit 1
    fi
done

for ((i=1; i<=request; i++)); do
    if diff tests/numbers_short.txt "tests/out_short_full${i}.txt" > /dev/null; then
        : 
        # echo "TCP full $i: Files are the same."
    else
        echo "TCP full $i ERROR: Files are different!"
        exit 1
    fi
done

for ((i=1; i<=request; i++)); do
    if diff tests/numbers_short.txt "tests/out_short_udp${i}.txt" > /dev/null; then
        : 
        # echo "TCP full $i: Files are the same."
    else
        echo "UDP $i ERROR: Files are different!"
        exit 1
    fi
done

# Clean up files.
for ((i=1; i<=request; i++)); do
    rm "tests/out_short_stream${i}.txt"
    rm "tests/out_short_full${i}.txt"
    rm "tests/out_short_udp${i}.txt"
done

# Close echo and reverse echo.
kill $(cat PID.txt)
rm PID.txt
rm nohup.out

echo "All files the same"
