#!/bin/bash
#
#   hash 
#   /proc/kallsyms symbol sizes
#   Run: ./calcsym.sh  (implicit sudo, see below)

# Output file
ksiz=./ksize.sym

ctrl=0 ; a= ; func=
arr=("\\ " "|" "/" "*" "\\ " "|" "*");lcount=0
# useless but cute
loading()
{
    if [ $lcount -gt ${#arr[@]} ] ; then
        lcount=0
    fi
    printf "${arr[$lcount]}\r"
    lcount=$(expr $lcount + 1)
}

calc()
{
    ret=
    if [ $ctrl == 0 ] ; then
        if [ -n $a ] ; then 
            a=$2 ; func=$3 ; ctrl=1 ; ret=0
        else
            echo "!! Error !!"
            exit
        fi
    else
        _size=$(echo "ibase=16;$a-$2"|bc)
        size=$_size

        # Turning negative offsets into positive ones.
        # We want to know symbol size not relative offsets
        if [ $_size -lt 0 ] ; then
            size=$(expr $_size - `expr $_size + $_size`)
        fi

        # At least from kallsyms we cannot know for sure the size of the symbol
        # because symbols are not guaranteed to be in perfect sequence. 
        # EXPORT_SYMBOL() plays a role here...
        if [ $size -lt 2048 ] ; then
            echo "size=$size entryptr=0x$2 type=$func fn=$4" >>$ksiz
        fi
        ctrl=0 ; a= ; func=
	loading
    fi

}

# Always run. Truncates output
if [ 1 ] ; then
    echo "begin:`date`" >$ksiz
    x=0
    echo "Loading $ksiz"
    sudo tac /proc/kallsyms |while read line ; do
        hex=$(echo $line |awk '{print $1}' |echo `tr "[:lower:]" "[:upper:]"`)
        type=$(echo $line |cut -d " " -f2)
        fn=$(echo $line |cut -d " " -f3)
        calc $x $hex $type $fn
        x=$(expr $x + 1)
    done
    echo "Done generating input file."
    echo "end:`date`" >>$ksiz
fi

#EOF
