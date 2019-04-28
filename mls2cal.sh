#!/bin/bash

org=dcunited.com
version=1
site=https://www.dcunited.com/schedule

if [ -n "$1" ]; then
    site="$1"
fi

tmpsched=tmpsched.html
tmpfiltered=tmpfiltered.txt
tmpfields=tmpfields.txt

if [ ! -t ]; then     # REMOVE ME!!!

echo curl -s -k -o $tmpsched "$site"
curl -s -k -o $tmpsched "$site"
if [ $? -ne 0 ]; then echo curl failed; exit 1; fi
echo egrep '(match_home_away|match_date|match_matchup|match_location_short)' $tmpsched
egrep '(match_home_away|match_date|match_matchup|match_location_short)' $tmpsched > $tmpfiltered
if [ $? -ne 0 ]; then echo egrep failed; exit 1; fi
echo "cat $tmpfiltered | sed -e 's/<[^>]*>//g'"
cat $tmpfiltered | sed -e 's/<[^>]*>//g' > $tmpfields
if [ $? -ne 0 ]; then echo sed failed; exit 1; fi
head -8 $tmpfields

fi     # REMOVE ME!!!

#**
#* Echo the month number for the month name in $1.
#*
month_number() {
    local lo=$(echo $1 | tr '[:upper:]' '[:lower:]')
    case $lo in
        jan*) echo 1 ;;
        feb*) echo 2 ;;
        mar*) echo 3 ;;
        apr*) echo 4 ;;
        may*) echo 5 ;;
        jun*) echo 6 ;;
        jul*) echo 7 ;;
        aug*) echo 8 ;;
        sep*) echo 9 ;;
        oct*) echo 10 ;;
        nov*) echo 11 ;;
        dec*) echo 12 ;;
        *) echo 0
    esac
}   # month_number()


# Eh. I could write a state machine. But this is quick and dirty.
weekday_name=Saturday
month_name=February
month=2
day=1
opponent="Who Are Ya FC"
lo_home_away=home
home_away=home

echo BEGIN:VCALENDAR
echo VERSION:2.0
echo PRODID:-//drcal/handcal//NONSGML v0.1//EN

cat $tmpfields | while read line; do
    #      H
    line=$(echo $line | tr -d '\r\n')
    whiteless=$(echo $line | tr -d '[:space:]')
    stripped=$(echo $line | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    lo=$(echo $stripped | tr '[:upper:]' '[:lower:]')
    if [[ "$lo" == "a" ]]; then
        home_away=Away
        home_away_delim=''   # Already 'at ' in MLS schedule.
    elif [[ "$lo" == "h" ]]; then
        home_away=Home
        home_away_delim='vs '
    else
        echo "out of sync."
        exit 1
    fi

    # echo home_away=$home_away

    #        Satuday, April 6, 2019 3:00PM ET
    read line
    stripped=$(echo $line | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'| tr -d ,)
    lo=$(echo $stripped | tr '[:upper:]' '[:lower:]')
    weekday_name=$(echo $line | cut -d, -f1)
    # echo weekday_name=$weekday_name
    month_name=$(echo $lo | egrep -o '(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)')
    # echo month_name=$month_name
    month=$(month_number $month_name)

    day=$(echo $lo | cut '-d ' -f 3)
    year=$(echo $lo | cut '-d ' -f 4)
    time=$(echo $lo | cut '-d ' -f 5)
    hour=$(echo $time | sed -e 's/^\([0-9]*\).*/\1/')
    minute=$(echo $time | sed -e 's/^[0-9]*:\([0-9]*\).*/\1/')
    second=0
    if [[ "${time#*pm}" != "$time" ]]; then
        hour=$[hour + 12]
    fi
    zone=$(echo $line | cut '-d ' -f 6)

    # echo year=$year
    # echo month=$month
    # echo day=$day
    # echo hour=$hour
    # echo minute=$minute
    # echo second=$second
    # echo zone=$zone

    #        LOS ANGELES FOOTBALL CLUB
    read line
    opponent=$(echo $line | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # echo opponent=$opponent

    #        AUDI FIELD
    read line
    venue=$(echo $line | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # echo venue=$venue

    #printf "New event: date=%04d%02d%02d time=%02d%02d%02d zone=%s venue='%s'\n" \
    #    $year $month $day $hour $minute $second "$zone" "$venue"

    if [[ "$(uname -s)" = "Darwin" ]]; then
        # Darwin-date-specific:
        timespec=$(printf %02d%02d%02d%02d%04d $month $day $hour $minute $year)
        epoch_seconds=$(date -j $timespec +%s)
        # Assume EDT:
        utc_start=$(date -j -r $[epoch_seconds + (4 * 3600)] +%Y%m%dT%H%M%SZ)
        utc_end=$(date -j -r $[epoch_seconds + (6 * 3600)] +%Y%m%dT%H%M%SZ)
        #printf "           start=%s end=%s venue='%s'\n" $utc_start $utc_end "$venue"
    else
        # Assumes EDT:
        timespec=$(printf %04d-%02d-%02dT%02d:%02d $year $month $day $hour $min)
        epoch_seconds=$(date  +%s --date=$timespec)
        start_seconds=$[epoch_seconds + (4 * 3600)]   # Assume EDT
        end_seconds=$[start_seconds + (2 * 3600)]
        utc_start=$(date --date=@$start_seconds +%Y%m%dT%H%M%SZ)
        utc_end=$(date --date=@$end_seconds +%Y%m%dT%H%M%SZ)
    fi
    
    uid=$utc_start-$version@$org

    echo BEGIN:VEVENT
    echo UID:$uid
    echo DTSTAMP:$utc_start
    echo DTSTART:$utc_start
    echo DTEND:$utc_end
    echo SUMMARY:[$home_away] DC United $home_away_delim$opponent
    echo LOCATION:$venue
    echo END:VEVENT
done

echo END:VCALENDAR
