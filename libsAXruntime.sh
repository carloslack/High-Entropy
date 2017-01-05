#! /bin/bash

# Uncomment for debugging
#set -x

# For Wheezy

# This is going to be our fixed base directory name
# after extracting Ltd's Runtime package, even though
# the name there is different
IDK_BASE_NAME=LtdAXIDK

CURRENT_BUILDOPTIONS_FILE=../idk/BuildOptions_AXApp_Integration.mk
NEW_BUILDOPTIONS_FILE=$IDK_BASE_NAME/Build/Config/buildoptions/BuildOptions_AXApp_Integration.mk

# Discovering STB's model by
# trying to guess $IDK_BASE_NAME/__lib__/???/
LibsArray=(
    amino-Ax3x-IDK
    amino-Ax4x-AXApp_Integration
    amino-Ax4x-IDK
    amino-Ax5x-IDK
#   Add new ones from here
)

# Now we set a map where the key is the lib name we'll look for
# set as "from" and "to", for renaming, before
# copying them into the tar file.
# map[key]="from_name to_name"
declare -A MAP=(
    [libLtdAXExtensions-amino-Ax3x-AXApp_Integration.a]="amino-Ax3x amino-avm"
    [libLtdAXExtensions-amino-Ax4x-AXApp_Integration.a]="amino-Ax4x amino-avm"
    [libLtdAXExtensions-amino-Ax3x-IDK.a]="amino-Ax3x-IDK amino-avm-AXApp_Integration"
    [libLtdAXExtensions-amino-Ax4x-IDK.a]="amino-Ax4x-IDK amino-avm-AXApp_Integration"
    [libLtdAXExtensions-amino-Ax5x-IDK.a]="amino-Ax5x-IDK amino-avm-AXApp_Integration"
#   Add new ones from here
)

if [ -z $1 ]  || [ -z $2 ]; then
    echo "Use: $0 <input file> <output file>"
    exit 1
fi

### You should not have to change anything beyond this point, hopefully.

# Ignore the possible changes in the base directory
# name from the Runtime package from Ltd and use our own
mkdir -p $IDK_BASE_NAME && tar xfz $1 -C $IDK_BASE_NAME --strip-components 1

if [ ! -d $IDK_BASE_NAME ]; then
    echo "$IDK_BASE_NAME directory not found in $1"
    exit
fi

check=1
for item in ${LibsArray[*]} ; do
    if [ -e $IDK_BASE_NAME/__lib__/$item ]; then
        rm -rf libs
        mkdir -p libs
        cp -v $IDK_BASE_NAME/__lib__/$item/lib/* libs/
        check=$(echo $?)
        break
    fi
done

if [ $check -ne 0 ]; then
    echo "Cannot find libs"
    exit 1
fi

if [ ! -e $NEW_BUILDOPTIONS_FILE ]; then
    echo "Cannot find BuildOptions_AXApp_Integration.mk in $IDK_BASE_NAME"
    exit 1
elif [ ! -e $CURRENT_BUILDOPTIONS_FILE ]; then
    echo "Cannot find current BuildOptions_AXApp_Integration.mk in ../idk/"
    exit 1
else
    diff -q $NEW_BUILDOPTIONS_FILE $CURRENT_BUILDOPTIONS_FILE
    if [ $? -eq 0 ]; then
        echo "New BuildOptions_AXApp_Integration.mk matches current version"
    else
        cp $NEW_BUILDOPTIONS_FILE $CURRENT_BUILDOPTIONS_FILE
        echo "Replaced current BuildOptions_AXApp_Integration.mk with newer version"
    fi
fi

# Rename the libraries if needed
cd libs
for K in "${!MAP[@]}" ; do
    if [ -e $K ] ; then
        arr=(${MAP[$K]})

        # 0:1 from
        # 1:1 to
        for i in `ls`; do mv -v $i ${i/${arr[@]:0:1}/${arr[@]:1:1}}; done

        break
    fi
done

# Everything is set so let's just create our tar file
tar -vzcf ../$2 *.a
cd -
rm -rf libs $IDK_BASE_NAME

printf "Output file: $2\nDone!\n"

