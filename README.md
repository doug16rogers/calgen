# Converting calendars from online

## Standard for calendars

The calendar standard (RFC-5545, .ics files) discusses the VEVENT field at
https://tools.ietf.org/html/rfc5545#section-3.6.1. Below is a sample calendar
from section 3.4 of the RFC:

```
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//hacksw/handcal//NONSGML v1.0//EN
    BEGIN:VEVENT
    UID:19970610T172345Z-AF23B2@example.com
    DTSTAMP:19970610T172345Z
    DTSTART:19970714T170000Z
    DTEND:19970715T040000Z
    SUMMARY:Bastille Day Party
    END:VEVENT
    END:VCALENDAR
```

Converting to UTC might be a pain in these scripts. Eh, 'date' does the trick
but it requires extensions that differ across unices.

## DC United

They do not provide a calendar in a standard format - they funnel everything
through ecal.com, which wants to have access to your calendar.

Use mls2cal.sh and pass the URL of the team's MLS schedule page. It defaults
to DC United's page. It will print the commands it is running so you can see
how it works if you care.

## Loudoun United FC

The scheulde web page is https://www.loudoununitedfc.com/schedule-2019.

See lufc2cal.sh for details.

Here's an excerpt of the results of the final run:

```
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//drcal/handcal//NONSGML v0.1//EN
    BEGIN:VEVENT
    UID:20190310T000000Z-1@loudoununitedfc.com
    DTSTAMP:20190310T010000Z
    DTSTART:20190310T010000Z
    DTEND:20190310T030000Z
    SUMMARY:[Away] Loudoun United FC @ Nashville SC
    LOCATION:First Tennessee Park
    END:VEVENT
    BEGIN:VEVENT
    UID:20190317T000000Z-1@loudoununitedfc.com
    DTSTAMP:20190317T000000Z
    DTSTART:20190317T000000Z
    DTEND:20190317T020000Z
    SUMMARY:[Away] Loudoun United FC @ Memphis 901 FC
    LOCATION:AutoZone Park
    END:VEVENT
    ...
    END:VCALENDAR
```

This was tested on both Google Calendar and Apple's MacOS Calendar.

## Instructions for adding to Google Calendar

Here are instructions for installing the calendar in Google Calendar (similar idea for MacOS Calendar):

0. Save lufc-2019.ics to your computer.
1. On your main Google Calendar page, click on the vertical "..." next to the
   "Add calendar" text box on the left. Select "Create new calendar".
2. Set the calendar Name to "Loudoun United FC 2019".
3. Click the "Create calendar" button.
4. Click on the arrow in the upper left to leave the Settings page.
5. Click on the vertical "..." next to your new Loudoun United calendar and select a color. I like "Graphite".
6. Click the vertical "..." next to the "Add calendar" text box again, but this time select "Import".
7. Click "Select file from your computer" and browse to the file's location to select it.
8. Click the "Open" button.
9. Change the "Add to Calendar" field to be "Loudoun United FC 2019". This
   will make it easy to delete the calendar later if a new schedule is released.
10. Click the "Import" button.

Ta-da! You've got a nice, color-coded calendar with all of LUFC's matches
listed, giving date, time, opponent, and place.

## Deleting the calendar events

To have the events be removed, add STATUS:CANCELLED to each event, like:

```
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//drcal/handcal//NONSGML v0.1//EN
    BEGIN:VEVENT
    UID:20190310T000000Z-1@loudoununitedfc.com
    STATUS:CANCELLED
    DTSTAMP:20190310T010000Z
    DTSTART:20190310T010000Z
    DTEND:20190310T030000Z
    SUMMARY:[Away] Loudoun United FC @ Nashville SC
    LOCATION:First Tennessee Park
    END:VEVENT
    BEGIN:VEVENT
    UID:20190317T000000Z-1@loudoununitedfc.com
    STATUS:CANCELLED
    DTSTAMP:20190317T000000Z
    DTSTART:20190317T000000Z
    DTEND:20190317T020000Z
    SUMMARY:[Away] Loudoun United FC @ Memphis 901 FC
    LOCATION:AutoZone Park
    END:VEVENT
    ...
    END:VCALENDAR
```


