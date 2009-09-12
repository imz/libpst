#!/bin/bash


function consistency()
{
    # check source and xml documentation for consistency
    (
        cd ..   # back to top level of project
        f1=/tmp/f1$$
        f2=/tmp/f2$$
        grep 'case 0x' src/libpst.c   | awk '{print $2}' | tr A-Z a-z | sed -e 's/://g'             | sort >$f1
        grep '^0x'     xml/libpst.in  | awk '{print $1}' | (for i in {1..19}; do read a; done; cat) | sort >$f2
        diff $f1 $f2
        less $f1
        rm -f $f1 $f2
    )
}

function dodii()
{
    n="$1"
    fn="$2"
    echo $fn
    ba=$(basename "$fn" .pst)
    size=$(stat -c %s $fn)
    rm -rf output$n
    if [ -z "$val" ] || [ $size -lt 10000000 ]; then
        mkdir output$n
        $val ../src/pst2dii -f /usr/share/fonts/bitstream-vera/VeraMono.ttf -B "bates-" -o output$n -O $ba.mydii -d $fn.log $fn >$fn.dii.err 2>&1
    fi
}


function doldif()
{
    n="$1"
    fn="$2"
    echo $fn
    ba=$(basename "$fn" .pst)
    size=$(stat -c %s $fn)
    rm -rf output$n
    if [ -z "$val" ] || [ $size -lt 10000000 ]; then
        mkdir output$n
        $val ../src/pst2ldif -d $ba.ldif.log -b 'o=ams-cc.com, c=US' -c 'inetOrgPerson' $fn >$ba.ldif.err 2>&1
    fi
}


function dopst()
{
    n="$1"
    fn="$2"
    echo $fn
    ba=$(basename "$fn" .pst)
    size=$(stat -c %s $fn)
    jobs=""
    [ -n "$val" ] && jobs="-j 0"
    rm -rf output$n
    if [ -z "$val" ] || [ $size -lt 10000000 ]; then
        mkdir output$n
        if [ "$regression" == "yes" ]; then
            $val ../src/readpst $jobs -te -r -cv -o output$n $fn >$ba.err 2>&1
        else
            #val ../src/readpst $jobs -r -D -cv -o output$n            $fn
            $val ../src/readpst $jobs -te -r -D -cv -o output$n -d $ba.log $fn >$ba.err 2>&1
            #$val ../src/readpst $jobs -r -cv -o output$n -d $ba.log $fn >$ba.err 2>&1
            #../src/getidblock -p $fn 0 >$ba.fulldump
        fi
    fi
}




pushd ..
make || exit
popd

rm -rf output* *.err *.log

v="valgrind --leak-check=full"
val=""

func="dopst"
[ "$1" == "pst"  ] && func="dopst"
[ "$1" == "pstv" ] && func="dopst" && val=$v
[ "$1" == "ldif" ] && func="doldif"
[ "$1" == "dii"  ] && func="dodii"

regression=""
[ "$2" == "reg" ] && regression="yes"
[ "$regression" == "yes" ] && val=""

$func   1 ams.pst
$func   2 sample_64.pst
$func   3 test.pst
$func   4 big_mail.pst
$func   5 mbmg.archive.pst
$func   6 Single2003-read.pst
$func   7 Single2003-unread.pst
$func   8 ol2k3high.pst
$func   9 ol97high.pst
$func  10 returned_message.pst
$func  11 flow.pst
$func  12 test-html.pst
$func  13 test-text.pst
$func  14 joe.romanowski.pst
$func  15 hourig1.pst
$func  16 test-mac.pst
$func  17 harris.pst
$func  18 spam.pst
$func  19 rendgen.pst       # single email appointment
$func  20 rendgen2.pst      # email appointment with no termination date
$func  21 rendgen3.pst      # mime signed email
$func  22 rendgen4.pst      # appointment test cases
$func  23 rendgen5.pst      # appointment test cases

[ -n "$val" ] && grep 'lost:' *err | grep -v 'lost: 0 '

if [ "$regression" == "yes" ]; then
    (
        (for i in output*; do find $i -type f; done) | while read a; do
            grep -v iamunique "$a"
            rm -f "$a"
        done
    ) >regression.txt
fi
