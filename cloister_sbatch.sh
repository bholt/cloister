#!/bin/bash
# arguments: <temporary file directory> <ruby script filename> <hostname of launcher>

# copy ruby script from launcher node
scp $3:$1/$2 /tmp/$2
# run ruby script
ruby /tmp/$2
# clean up ruby script
rm /tmp/$2
