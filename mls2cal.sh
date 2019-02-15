#!/bin/bash

site=https://www.dcunited.com/schedule

if [ -n "$1" ]; then
    site="$1"
fi

tmpsched=tmpsched.html
tmpfiltered=tmpfiltered.txt
tmpfields=tmpfields.txt

echo curl -s -o $tmpsched "$site"
curl -s -o $tmpsched "$site"
if [ $? -ne 0 ]; then echo curl failed; exit 1; fi
echo egrep '(match_home_away|match_date|match_matchup|match_location_short)' $tmpsched
egrep '(match_home_away|match_date|match_matchup|match_location_short)' $tmpsched > $tmpfiltered
if [ $? -ne 0 ]; then echo egrep failed; exit 1; fi
echo "cat $tmpfiltered | sed -e 's/<[^>]*>//g'"
cat $tmpfiltered | sed -e 's/<[^>]*>//g' > $tmpfields
if [ $? -ne 0 ]; then echo sed failed; exit 1; fi
head -8 $tmpfields

