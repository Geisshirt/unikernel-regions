# TCP 

## File structure:
* Codec  (header, encode, decode)
* State  (connection table, sequencing etc)
* Handle (handle incoming)
* Send   (build outgoing segment)


## How to TCP
1. Decode the segment
2. Lookup state
3. Update state
4. Apply callback function
5. Encode segment
6. Reply with segment

