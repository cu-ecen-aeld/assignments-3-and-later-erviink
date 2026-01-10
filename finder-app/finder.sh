#!/bin/sh
 
 
 filesdir="$1"
 searchstr="$2"
 
 
 #check parameter validity
 
 if [ $# -eq 2 ] ; then
 if [ ! -d "$filesdir" ] ; then
 echo "$filesdir is not a directory. Bye."
 exit 1
 else
 echo "The number of files are $(find "$filesdir" -mindepth 1 | wc -l) and the number of matching lines are "
 echo "$(grep -rI "$searchstr" "$filesdir" | wc -l)" 
 
 fi 
 
 else
 echo "No two arguments provided. Bye."
 exit 1
 fi
