#!/bin/bash
#
# id3.sh
#
# Carlos Carvalho <carloslack@gmail.com>
#
# Script to be used for automatic sqlite3 insert queries
# for database tests, although database insertion is not
# present in this version.

id3=$(which id3v2)

tracks=$HOME/Music

if [ ! -f $id3 ] ; then
    echo "id3v2 executable not found"
    exit
fi

find $tracks -name "*.mp3" |while read line ; do
    i=0
    $id3 -l "$line" > .tmpfile
    track=$(cat .tmpfile |grep '^TRCK' |cut -d ":" -f2| cut -d "/" -f1 |sed -e 's/^ //g;s/^  //g')
    if [ ! -z $track ] ; then
        album=$(cat .tmpfile |grep '^TALB' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g')
        year=$(cat .tmpfile |grep '^TYER' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g')
        title=$(cat .tmpfile |grep '^TIT2' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g')
        artist=$(cat .tmpfile |grep '^TPE' |head -1 |cut -d ":" -f2 |sed -e 's/^ //g;s/^  //g')

        echo "<item>"
        echo "Artist:$artist"
        echo "Title:$title"
        echo "Album:$album"
        echo "Year:$year"
        echo "Track number:$track"
        echo "File:$line"
        # execute your query here
        find "`dirname $line`" -name "*.jpg" |while read jpg ; do
            # execute your query here too
            echo "Image $i:$jpg"| sed -e 's/^ //g;s/^  //g'
            i=$(expr $i + 1)
        done
        echo "</item>"
    fi
done
rm -rf .tmpfile 2>/dev/null



