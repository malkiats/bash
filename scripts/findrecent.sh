#!/bin/bash
SEARCH_DIR=/home/mali/Downloads

mkdir -p found
find $SEARCH_DIR -mtime -1- -type f -iname "*.txt" | xargs -I % cp % /home/mali/found

#mtime - modified time 
#-1 - Less than one day
#xarg - It reads lines of text from standard input
