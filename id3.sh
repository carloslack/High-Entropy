#!/bin/bash
# id3.sh
# Carlos Carvalho <carloslack@gmail.com>
#
# SQLite3 create/insert for testing purposes.
#
# This script works by searching for mp3 files in
# your $HOME/Music directory.
# It will not add all your files, instead only
# compatible ones, i.e, id3 version. I could make it
# work for any mp3 files but the idea is only
# to add some in the the database so we can execute
# some queries over them later in our application so
# there is no reason to add each entry manually.
#
# I suggest you to improve this code (easy job)
# or even better, rewrite it again in Perl :P
#

DB=./test.db
tracks=$HOME/Music
t_artists="artists"
t_albums="albums"
t_tracks="tracks"

exists()
{
   exe=$(which $1)
   if [ ! -f "$exe" ] ; then
      >&2 echo "error: $1 not found"
      echo "exit"
   fi
   echo $exe
}

sql=$(exists 'sqlite3')
id3=$(exists 'id3v2')


init()
{
   #Exit if not found
   $id3 >/dev/null 2>&1
         
   #touch database or exit if sqlite3 is not found
   $sql $DB ".dump" >/dev/null 2>&1
   if [ $? != 0 ] ; then
      >&2 echo "error creating database"
   fi

   echo "<Init>"
   if [ ! -z $1 ] && [ $1 == "r" ] ; then
      if [ -f $DB ] ; then
         rm -rfv $DB
      fi
   fi
   $sql -echo $DB "CREATE TABLE IF NOT EXISTS $t_artists (id INTEGER PRIMARY KEY, name TEXT NOT NULL);"
   $sql -echo $DB "CREATE TABLE IF NOT EXISTS $t_albums (id INTEGER PRIMARY KEY, id_artist INTEGER,\
name TEXT NOT NULL, genre TEXT DEFAULT NULL, year INTEGER DEFAULT 0, image BLOB DEFAULT 0);"
   $sql -echo $DB "CREATE TABLE IF NOT EXISTS $t_tracks (id INTEGER PRIMARY KEY, id_artist INTEGER,\
id_album INTEGER, name TEXT NOT NULL, track INTEGER, file TEXT NOT NULL);"
   echo "</Init>"
}

loadinput()
{
   >.input.txt
   find $tracks -name "*.mp3" |while read line ; do
      echo "$line" >> .input.txt
   done
}

#create artists
artist_insert()
{
   echo "<Artist Insert>"
   cat .input.txt |while read line ; do
      $id3 -l "$line" > .tmpfile
      artist=$(cat .tmpfile |grep '^TPE2' |cut -d ":" -f2| cut -d "/" -f1 |sed -e 's/^ //g;s/^  //g;s/\x27//g')
      if [ ! -z "$artist" ] ; then
         row=$($sql $DB "SELECT * FROM $t_artists WHERE name = '$artist';") 2>/dev/null
         if [ -z "$row" ] ; then
            $sql -echo $DB "INSERT INTO $t_artists (name) VALUES('$artist');" 2>/dev/null
         fi
      fi
   done
   echo "</Artist Insert>"
}

#create albums
album_insert()
{
   echo "<Album Insert>"
   cat .input.txt |while read line ; do
      $id3 -l "$line" > .tmpfile
      artist=$(cat .tmpfile |grep '^TPE2' |cut -d ":" -f2| cut -d "/" -f1 |sed -e 's/^ //g;s/^  //g;s/\x27//g')
      if [ ! -z "$artist" ] ; then
         name=$(cat .tmpfile |grep '^TALB' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g')
         id_artist=$($sql $DB "SELECT id FROM $t_artists WHERE name = '$artist';") 2>/dev/null
         row=$($sql $DB "SELECT * FROM $t_albums WHERE name = '$name' AND id_artist = "$id_artist";") 2>/dev/null
         if [ -z "$row" ] ; then
            p=$(dirname "$line")
            cd "$p"
            list=$(ls *.jpg 2>/dev/null)
            status=$(echo $?)
            array=($list)
            cd - >/dev/null 2>&1
            genre=$(cat .tmpfile |grep '^TCON' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g')
            year=$(cat .tmpfile |grep '^TYER' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g')
            if [ $status -eq 0 ] ; then
               p=$(dirname "$line")
               # readfile() && writefile() are extensions
               # so this will only work if you configured these extensions
               # otherwise default value will take place :(
               $sql -echo $DB "INSERT INTO $t_albums (id_artist, name, genre, year, image)\
                  VALUES($id_artist, '$name', '$genre', $year, readfile('$p/${array[0]}'));" 2>/dev/null
            else
               $sql -echo $DB "INSERT INTO $t_albums (id_artist, name, genre, year)\
                  VALUES($id_artist, '$name', '$genre', $year);" 2>/dev/null
            fi
         fi
      fi
   done
   echo "</Album Insert>"
}

#create tracks
track_insert()
{
   echo "<Track Insert>"
   cat .input.txt |while read line ; do
      $id3 -l "$line" > .tmpfile
      artist=$(cat .tmpfile |grep '^TPE2' |cut -d ":" -f2| cut -d "/" -f1 |sed -e 's/^ //g;s/^  //g;s/\x27//g')
      if [ ! -z "$artist" ] ; then
         name_album=$(cat .tmpfile |grep '^TALB' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g')
         name_track=$(cat .tmpfile |grep '^TIT2' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g')
         n_track=$(cat .tmpfile |grep '^TRCK' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g' |cut -d "/" -f1)
         id_artist=$($sql $DB "SELECT id FROM $t_artists WHERE name = '$artist';") 2>/dev/null
         id_album=$($sql $DB "SELECT id FROM $t_albums WHERE id_artist = "$id_artist" AND name = '$name_album';") 2>/dev/null
         if [ ! -z $id_album ] ; then #XXX
            row=$($sql $DB "SELECT * FROM $t_tracks WHERE name = '$name_track'\
               AND id_artist = "$id_artist" AND id_album = "$id_album";") 2>/dev/null
            if [ -z "$row" ] ; then
               $sql -echo $DB "INSERT INTO $t_tracks (id_artist, id_album, name,\
                  track, file) VALUES($id_artist, $id_album, '$name_track', $n_track, '$line');" 2>/dev/null
            fi
         fi
      fi
   done
   echo "</Track Insert>"
}

init $1
loadinput
artist_insert
album_insert
track_insert

#Display created db
$sql $DB ".dump"

rm -rf .tmpfile 2>/dev/null
rm -rf .input.txt 2>/dev/null

#EOF

