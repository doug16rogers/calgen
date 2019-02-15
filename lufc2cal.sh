#!/bin/bash

site=https://www.loudoununitedfc.com/schedule-2019

if [ -n "$1" ]; then
    site="$1"
fi

tmpsched=tmpsched.html
tmpfiltered=tmpfiltered.txt
tmpfields=tmpfields.txt

echo curl -s -o $tmpsched "$site"
curl -s -o $tmpsched "$site"
if [ $? -ne 0 ]; then echo curl failed; exit 1; fi

echo egrep '(<h6 style="text|^<h1 style="text|span style="color:#|</span></span></p>)' $tmpsched
egrep '(<h6 style="text|^<h1 style="text|span style="color:#|</span></span></p>)' $tmpsched > $tmpfiltered
if [ $? -ne 0 ]; then echo egrep failed; exit 1; fi

echo "cat $tmpfiltered | sed -e 's/<span style=.color:#FFFFFF.>/month=/' | sed -e 's/<[^>]*>//g'"
cat $tmpfiltered | sed -e 's/<span style=.color:#FFFFFF.>/month=/' | sed -e 's/<[^>]*>//g' > $tmpfields
if [ $? -ne 0 ]; then echo sed failed; exit 1; fi
head -8 $tmpfields

