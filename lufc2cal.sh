#!/bin/bash

version=1
year=2019
site=https://www.loudoununitedfc.com/schedule-$year

if [[ $(uname -s) != Darwin ]]; then
    echo "$0: only supported on Darwin (MacOS); fixme by changing the 'date' code." 1>&2
    exit 1
fi

if [[ -n "$1" ]]; then
    site="$1"
fi

tmpsched=tmpsched.html
tmpfiltered=tmpfiltered.txt
tmpfields=tmpfields.txt

#if [ ! -t ]; then     # REMOVE ME!!!

echo curl -s -o $tmpsched "$site" 1>&2
curl -s -o $tmpsched "$site"
if [ $? -ne 0 ]; then echo curl failed 1>&2; exit 1; fi

echo egrep '(<h6 style="text|^<h1 style="text|span style="color:#|</span></span></p>)' $tmpsched 1>&2
egrep '(<h6 style="text|^<h1 style="text|span style="color:#|</span></span></p>)' $tmpsched > $tmpfiltered
if [ $? -ne 0 ]; then echo egrep failed 1>&2; exit 1; fi

echo "cat $tmpfiltered \
    | sed -e 's/<span style=.color:#FFFFFF.>/month=/' \
 -e 's/<[^>]*>//g' -e 's/&nbsp;/ /g' \
 -e 's/<[^>]*>//g' -e \"s/&rsquo;/'/g\"" 1>&2
cat $tmpfiltered \
    | sed -e 's/<span style=.color:#FFFFFF.>/month=/' \
          -e 's/<[^>]*>//g' \
          -e 's/&nbsp;/ /g' \
          -e "s/&rsquo;/'/g" \
    | sed -e 's/<[^>]*>//g' \
    > $tmpfields
if [ $? -ne 0 ]; then echo sed failed 1>&2; exit 1; fi

#fi     # REMOVE ME!!!

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

is_lo_weekday() {
    case $1 in
        mon*) return 0 ;;
        tue*) return 0 ;;
        wed*) return 0 ;;
        thu*) return 0 ;;
        fri*) return 0 ;;
        sat*) return 0 ;;
        sun*) return 0 ;;
        *) return 1 ;;
    esac
}

is_lo_home_away() {
    case $1 in
        home) return 0 ;;
        away) return 0 ;;
        *) return 1 ;;
    esac
}

is_day() {
    numeric=$(echo $1 | sed -e 's/[^0-9]//g')
    if [ "$numeric" == "$1" ]; then
        return 0
    fi
    return 1
}

is_opponent() {
    case $1 in
        @*) return 0 ;;
        vs.*) return 0 ;;
        *) return 1 ;;
    esac
}

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
    line=$(echo $line | tr -d '\r\n')
    whiteless=$(echo $line | tr -d '[:space:]')
    lo=$(echo $whiteless | tr '[:upper:]' '[:lower:]')
    if [[ "${whiteless#*month=}" != "$whiteless" ]]; then
        month_name=$(echo $whiteless | sed -e 's/.*month=\([A-Z][a-z]*\).*/\1/')
        month=$(month_number $month_name)
        #echo "New month: $month_name ($month)"
    elif is_lo_weekday $lo; then
        weekday_name=$whiteless
        #echo "New weekday: $weekday_name"
    elif is_lo_home_away $lo; then
        lo_home_away=$lo
        home_away=$whiteless
        #echo "New home/away: $home_away"
    elif is_day $lo; then
        day=$lo
        #echo "New day: $day"
    elif is_opponent $lo; then
        opponent=$(echo $line | sed -e 's/^\(@ \|vs. \)//')
        #echo "New opponent: $opponent"
    else
        time=$(echo $line | cut '-d ' -f1)
        zone=$(echo $line | cut '-d ' -f2)
        venue=$(echo $line | cut '-d ' -f4-)
        if [[ "$venue" == "TBD" ]]; then
            venue="Venue TBD"
        fi
        if [[ "$time" == "Time" ]]; then
            time="8:00am"
            opponent="$opponent [Time TBD]"
        fi
        hour=$(echo $time | sed -e 's/^\([0-9]*\).*/\1/')
        minute=$(echo $time | sed -e 's/^[0-9]*:\([0-9]*\).*/\1/')
        second=0
        if [[ "${time#*pm}" != "$time" ]]; then
            hour=$[hour + 12]
        fi

        #printf "New event: date=%04d%02d%02d time=%02d%02d%02d zone=%s venue='%s'\n" \
        #    $year $month $day $hour $minute $second "$zone" "$venue"

        # Darwin-date-specific:
        timespec=$(printf %02d%02d%02d%02d%04d $month $day $hour $minute $year)
        epoch_seconds=$(date -j $timespec +%s)
        # Assume EDT:
        utc_start=$(date -j -r $[epoch_seconds + (4 * 3600)] +%Y%m%dT%H%M%SZ)
        utc_end=$(date -j -r $[epoch_seconds + (6 * 3600)] +%Y%m%dT%H%M%SZ)
        #printf "           start=%s end=%s venue='%s'\n" $utc_start $utc_end "$venue"

        uid=$utc_start-$version@loudoununitedfc.com

        echo BEGIN:VEVENT
        echo UID:$uid
        echo DTSTAMP:$utc_start
        echo DTSTART:$utc_start
        echo DTEND:$utc_end
        echo SUMMARY:[$home_away] Loudoun United FC $opponent
        echo LOCATION:$venue
        echo END:VEVENT
    fi
done

echo END:VCALENDAR
