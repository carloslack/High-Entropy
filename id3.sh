#!/bin/bash
# id3.sh
# Carlos Carvalho <carloslack@gmail.com>

DB=./test.db
tracks=$HOME/Music
t_artists="artists"
t_albums="albums"
t_tracks="tracks"

if [ -f $DB ] ; then
   rm -rf $DB
fi

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

#Create empty database or exit if sqlite3 not found
$sql $DB ".dump" >/dev/null 2>&1
if [ $? != 0 ] ; then
   >&2 echo "error creating database"
fi

#Exit if not found
$id3 >/dev/null 2>&1

$sql $DB "CREATE TABLE $t_artists (id INTEGER PRIMARY KEY, name TEXT);"
$sql $DB "CREATE TABLE $t_albums (id INTEGER PRIMARY KEY, id_artist INTEGER, name TEXT NOT NULL, genre TEXT DEFAULT NULL, year INTEGER DEFAULT 0, image TEXT DEFAULT NULL);"
$sql $DB "CREATE TABLE $t_tracks (id INTEGER PRIMARY KEY, id_artist INTEGER, id_album INTEGER, name TEXT, track INTEGER, file TEXT);"

#create artists
find $tracks -name "*.mp3" |while read line ; do
    $id3 -l "$line" > .tmpfile
    artist=$(cat .tmpfile |grep '^TPE2' |cut -d ":" -f2| cut -d "/" -f1 |sed -e 's/^ //g;s/^  //g;s/\x27//g')
    if [ ! -z "$artist" ] ; then
       row=$($sql $DB "SELECT * FROM $t_artists WHERE name = '$artist';" 2>/dev/null)
      if [ -z "$row" ] ; then
         $sql -echo $DB "INSERT INTO $t_artists (name) VALUES('$artist');"
      fi
   fi
done

#create albums
find $tracks -name "*.mp3" |while read line ; do
    $id3 -l "$line" > .tmpfile
    artist=$(cat .tmpfile |grep '^TPE2' |cut -d ":" -f2| cut -d "/" -f1 |sed -e 's/^ //g;s/^  //g;s/\x27//g')
    if [ ! -z "$artist" ] ; then
      name=$(cat .tmpfile |grep '^TALB' |cut -d ":" -f2| sed -e 's/^ //g;s/^  //g;s/\x27//g')
      id_artist=$($sql $DB "SELECT id FROM $t_artists WHERE name = '$artist';")
      row=$($sql $DB "SELECT * FROM $t_albums WHERE name = '$name' AND id_artist = "$id_artist";")
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
            $sql -echo $DB "INSERT INTO $t_albums (id_artist, name, genre, year, image) VALUES($id_artist, '$name', '$genre', $year, '$p/${array[0]}');" 2>/dev/null
         else
            $sql -echo $DB "INSERT INTO $t_albums (id_artist, name, genre, year) VALUES($id_artist, '$name', '$genre', $year);" 2>/dev/null
         fi
      fi

    fi
done
#TODO: create tracks
rm -rf .tmpfile 2>/dev/null



