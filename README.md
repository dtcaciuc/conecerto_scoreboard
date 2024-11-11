# Conecerto Scoreboard

Conecerto Scoreboard is an alternative score display program for
[MJTiming](https://github.com/mjtiming/mjtiming). It was originally designed to
present results at [VCMC](https://vcmc.ca/) autocross events.

The app is a webserver that runs on the same machine as MJTiming and replaces
the bundled *mjannounce.exe*.

It provides the following endpoints:

* `/` - Mobile browser-optimized results explorer for participants to access from
  their mobile phones. The content can be accessed via a local event WiFi or
  via a remote static website (see below).

* `/tv` - An periodically refreshed dashboard that should be displayed on a large
  1080p screen positioned in the spectator area. The provided tables display
  top 10 results in each of the raw, PAX, and group categories and cycle
  through the rest of the results after a set time interval. A table showing
  recent runs is refreshed separately whenever a car passes through the finish
  line.

* `/announce` - An automatically refreshed dashboard that is designed to be
  displayed on a smaller screen in the timing booth and intended to be used by
  the commentator. The entire dashboard is refreshed whenever a car passes
  through the finish line. Upon refresh, the dashboard displays the latest run
  and driver's updated results in each of the raw, PAX, and group(s)
  categories.

## Running a release

Follow this guide to set up the configuration and run `bin/server.bat` in the
release directory.

The program is configured through [environment
variables](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/set_1)
(or _envars_).

Rather than modifying `server.bat`, it's recommended to create a wrapper `.bat`
file outside of the release directory and place all of the configuration there.
This way, when it's time to upgrade to a new version, you can simply replace
the entire release directory with the new content.

Unless you set `EVENT_DATE` environment variable, the program will read the
data for the date on which it was started.

> [!NOTE]
> If program was left running after the previous event, it needs to be restarted
> on the day of the next event to start reading new data.

## Setting up TV kiosk

The suggested way to drive the live dashboard TV is with a Raspberry Pi 4 or a
similar single board PC running Chromium browser which connects to the timing
computer via WiFi or an Ethernet cable. Copy the `misc/kiosk.sh` template
script, change the IP to the one of the timing computer in your specific
network setup, and make the script run on the startup. The script will wait
until Scoreboard server is reachable and then attempt to start Chromium in
kiosk mode.

## Configuring event names and dates

By default, Scoreboard reuses event date as the event name. To display custom
event names in the explorer, set `EVENT_SCHEDULE` envar to point to a CSV file
containing the entire schedule of the upcoming events. After that, the correct
event name will be picked up automatically for whatever day you launch
Scoreboard on.

The event CSV file must have two columns:

* `date` - Event date, in the `yyyy_mm_dd` format
* `name` - Event name (must not contain any commas)

> [!NOTE]
> The file must start with a header row containing field names.

You can also set `EVENT_NAME` envar to name the current event directly, however
using the schedule is much easier since you can set it once and forget
about it (unless some of the event dates change).

## Publishing results to a remote server

If the timing computer where Scoreboard is running has access to the Internet,
the program can be set up to continuously upload results explorer contents to an
FTP server whenever a new result comes in to have them served as a static
website. This will allow the attendees to use their mobile data connectivity to
access the results and to not be limited by the local event WiFi range.

> [!NOTE]
> The resulting website contains a local `.htaccess` file. Make sure the web
> server you're using supports mod_rewrite.

See Configuration below for more details.

### Publishing on demand

Scoreboard provides a dedicated `bin/publish_explorer` command which starts up,
publishes the results once, then exits. This is useful if final results are
published to one location as live results but are also exported after the
event is over to another one.

The command takes the same environment variable configuration as the main program.

Just like when running the server, it's recommended to create a wrapper batch
file which will allow you to configure the publisher with environment variables.
You will likely need to set `EXPLORER_REMOTE_HTTP_BASE_PATH` envar which needs
to be set to the URL path where the result are going to be served from.

If you're organizing the results by date, you can use `bin/today` utility to
generate date string in the correct format that can be used to for needed
envars. For example,

```
REM This sets EVENT_DATE; batch files don't have a good way to set variable to a command output.
for /f "delims=" %%i in ('path\to\scoreboard\bin\today.bat') do set EVENT_DATE=%%i

set EXPLORER_REMOTE_HTTP_BASE_PATH=/results/%EVENT_DATE%
```


## Customizing explorer colors

Explorer can be configured to use a custom color scheme to match the club website
theme or for other reasons.

Make a copy of `misc/dark-colors.csv.template` or `misc/light-colors.csv.template`
and adjust the values to your liking. The starter themes are very neutral and it
will likely be sufficient to pick the right `header-active-text` accent color.

Finally, set `EXPLORER_COLORS` envar to point to the custom CSV file.

## Organizer and sponsor advertisements

Scoreboard can display organizer and event sponsors logos on the dashboard TV
in a special footer area and on all explorer pages. Additionally, you can specify
optional brand homepage URLs that explorer can link the logs to.

To enable, create a separate brands directory and set `BRANDS_DIR` configuration
variable (see below).

### Logos
Place organizer and sponsor logos in either .jpg or .png format into the
directory. Organizer logo must be named `organizer.jpg/png` while sponsor logos
can have any file name.

All logos should:

* Be wider than taller for most visibility
* Be 100px in height (if not, they will autoscale, but might look
  blurry or take up more bandwidth than necessary).

Organizer logo will be shown both in the TV dashboard footer which has white
background and the explorer header with background determined by `EXPLORER_COLORS`,
so it might take some tweaking to make it look good in both of these spots.

> [!NOTE]
> With footer present, try readjusting `TV_FONT_SIZE` to make the most out
> of the screen real estate. Recommended value for 1080p displays is `18.0`.

### Homepage URLs

To make the explorer brand logos clickable, create `urls.csv` file in the brands
directory. The event CSV file must have two columns:

* `name` - Brand name. The matching logo image must be called `<name>.jpg` or `<name>.png`
* `url` - The URL of the page you want the logo to link to.

> [!NOTE]
> The file must start with a header row containing field names.

## Configuration

The following environment variables need to be manually set:

* `PHX_HOST` - IP/hostname of the machine that will be running Scoreboard.
  This is required for TV dashboard to work and cannot just be `localhost`.

Additionally, you can optionally set the following:

* `EXPLORER_COLORS` (path, optional) - Path to a CSV file with the custom explorer color palette.
* `ANNOUNCE_FONT_SIZE` (float, optional) - /announce endpoint font size.
* `TV_FONT_SIZE` (float, optional) - /tv endpoint font size.
* `TV_REFRESH_INTERVAL` (integer, optional) - Sets how long /tv displays a page of
  scores (in seconds) in each panel before moving onto next one.
* `EVENT_SCHEDULE` (path, optional) - Path to CSV file with event schedule to read the event name from (see below).
* `EVENT_NAME` (string, optional) - Displays given name on top of the Event page. Leave unset if `EVENT_SCHEDULE` is set.
* `EVENT_DATE` (`yyyy_mm_dd`, optional) - Forces specified event date. Use this to read past event's data.
* `RADIO_FREQUENCY` (optional) - Displays commentary broadcast frequency on top of the Event page.
* `BRANDS_DIR` (optional) - Directory with organizer and sponsor brand logos.
* `MJ_DIR` (path, optional) - Path to MJTiming directory (defaults to `C:\mjtiming`).
* `MJ_DEBOUNCE_INTERVAL` (integer, optional) - Interval (in ms) between when MJTiming .csv
  files are updated and when Scoreboard tries reading them. For larger events
  with more people and runs in them, MJTiming might require more time to flush
  all data to disk. If you see CSV reading errors in the console, try
  increasing this value (defaults to 1000).
* `MJ_POLL_CHANGES` (boolean, optional) - Poll for MJ data changes rather than
  listening for file system alerts. This can be used when MJ data is located somewhere that
  does not reliably notify of changes (such as a mounted Google Drive folder).
  Enable by setting to any non-empty value (e.g. `1`, `true`).
* `MJ_POLL_INTERVAL` (integer, optional) - Change poll interval (in ms,
  defaults to 1000). Used only if `MJ_POLL_CHANGES` is set.
* `DATABASE_PATH` (path, optional) - Path to SQLite3 database file where Scoreboard stores data
  while its running (defaults to `conecerto_scoreboard.db` in user's temporary directory).
* `SECRET_KEY_BASE` (string, optional) - Secret key base required for Phoenix to operate (64
  characters; auto-generated on every launch if not specified)

To continuously upload results to a remote server, set the following:

* `EXPLORER_REMOTE_FTP_HOST` - FTP hostname
* `EXPLORER_REMOTE_FTP_USER` - FTP username
* `EXPLORER_REMOTE_FTP_PASS` - FTP password
* `EXPLORER_REMOTE_FTP_BASE_DIR` (optional) - Directory path relative to FTP account home directory
  where the static version of explorer is going to be uploaded (defaults to FTP account home directory).
  If the directory does not exist, it will be created the first time the upload happens.
* `EXPLORER_REMOTE_HTTP_BASE_PATH` (optional) - URL base path where uploaded results are served from (defaults to "/").

> [!NOTE]
> On Windows, if your password contains `^`, make sure to escape it with another `^`.

## Developing

### Runtime

You must have Elixir 1.17 & Erlang/OTP 27 installed to build Scoreboard.

### Notable dependencies

Scoreboard requires a C++ compiler to build SQLite3 library. On Windows, install
Visual Studio Community edition and work with project from cmd.exe / PowerShell
session for VS 64-bit (here, we're assuming you're using 64-bit Erlang; for
32-bit on, VS 32-bit terminal session accordingly.)

### Running in development mode

Start the server by running

```
iex -S mix phx.server
```
## Building a release

Run `release.bat`. Release files should now be available in `_build/prod/rel`
directory.

## License

Copyright (C) 2024 Dimitri Tcaciuc.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.
