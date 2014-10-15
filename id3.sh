#!/bin/bash
#
# id3.sh
#
# Carlos Carvalho <carloslack@gmail.com>
#
# Script to be used for automatic sqlite3 insert/create table queries
# for database tests.
#
# This is the first version, not optimal, just working
# without the need to be perfect yet, the idea is just to automatically
# insert some data in sqlite3 for our tests.
#
# ps: I don't even know yet if I will use this script
# but decided to share anyway because it may be useful to someone else.
#

id3=$(which id3v2)
trackn=

tracks=$HOME/Music

if [ ! -f $id3 ] ; then
    echo "id3v2 not found"
    exit
fi

find $tracks -name "*.mp3" |while read line ; do
    i=0
    a=$($id3 -l "$line"| grep "Artist:" |head -1)
    t=$($id3 -l "$line"| grep "Track:" |head -1)
    a_tokens=( $a )
    t_tokens=( $t )

    # I don't think id3v2 would provide an already parsed
    # information about tracks, artists, albums...
    while [ $i -lt ${#a_tokens[@]} ] ; do
        #Track number
        x=0
        while [ $x -lt ${#t_tokens[@]} ] ; do
            show=$(echo ${t_tokens[$i]} |grep "Track:")
            range=$(echo ${t_tokens[*]:$i + 1:10})
            chars=$(echo $range |wc -c)
            if [ ! -z $show ] && [ $chars -gt 1 ] ; then
                trackn=$range
                break
            fi
            x=$(expr $x + 1)
        done

        #Artist, album, title
        show=$(echo ${a_tokens[$i]} |grep "Artist:")
        range=$(echo ${a_tokens[*]:$i + 1:100})
        chars=$(echo $range |wc -c)
        if [ ! -z $show ] && [ $chars -gt 1 ] ; then
            imgcounter=0
            artist=$range
            album=$($id3 -l "$line" |grep ^Album |cut -d ":" -f2 |sed -e 's/Year//g;s/^ //g;s/  //g')
            title=$($id3 -l "$line" |grep ^Title |cut -d ":" -f2 |sed -e 's/Artist//g;s/^ //g;s/  //g')
            echo "<item>"
            echo "Artist: $artist"
            echo "Title: $title"
            echo "Album: $album"
            echo "Track number: $trackn"
            echo "File: $line"
            # execute your query here
            find "`dirname $line`" -name "*.jpg" |while read jpg ; do
                # execute your query here too
                echo "Image $imgcounter: $jpg"
                imgcounter=$(expr $imgcounter + 1)
            done
            echo "</item>"
        fi
        i=$(expr $i + 1)
    done
done



