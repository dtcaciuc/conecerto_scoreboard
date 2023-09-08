# Conecerto Scoreboard

Concerto Scoreboard is an alternative score display program for
[MJTiming](https://github.com/mjtiming/mjtiming). It was originally designed to
present results at [VCMC](https://vcmc.ca/) autocross events.

The app is a webserver that runs on the same machine as MJTiming and replaces
the bundled *mjannounce.exe*.

It provides the following endpoints:

* `/` - Set of mobile browser-optimized pages with full result lists which
  would be accessed by participants from their mobile phones. The content can be
  accessed via a local event WiFi or through an external static website (see below).

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

## Setting up TV kiosk

The suggested way to drive the live dashboard TV is with a Raspberry Pi 4 or a
similar single board PC running Chromium browser which connects to the timing
computer via WiFi or an Ethernet cable. Copy the `misc/kiosk.sh` template
script, change the IP to the one of the timing computer in your specific
network setup, and make the script run on the startup. The script will wait
until the scoreboard server is reachable and then attempt to start Chromium in
kiosk mode.

## Posting results to an external server

If the timing computer where Scoreboard is running has access to the Internet,
the program can be set up to continuously upload `/` endpoint contents to an
FTP server whenever a new result comes in. This will allow the attendees to use
their mobile data connectivity to access the scores and to not be limited by
the local event WiFi range.

See Configuration below for more details.

## Running a release

Set up environment variables listed below, and run `bin/server.bat` in the
release directory.

The program is configured through [environment variables](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/set_1).

Rather than modifying `server.bat`, it's recommended to create a wrapper `.bat`
file outside of the release directory and place all of the configuration there.
This way, when it's time to upgrade to a new version, you can simply replace
the entire release directory with the new content.

Unless you set `EVENT_DATE` environment variable, the program will read the
same day's results by default.

Note: Currently, if program is left running after the previous event, it needs
to be restarted on the day of the next event to start reading new data.

## Configuration

The following environment variables need to be manually set:

* `PHX_HOST` - IP/hostname of the machine that will be running the scoreboard.
  This is required for LiveViews to work and cannot just be `localhost`.

Additionally, you can optionally set the following:

* `ANNOUNCE_FONT_SIZE` (float, optional) - /announce endpoint font size.
* `TV_FONT_SIZE` (float, optional) - /tv endpoint font size.
* `TV_REFRESH_INTERVAL` (integer, optional) - Sets how long /tv displays a page of
  scores (in seconds) in each panel before moving onto next one.
* `EVENT_DATE` (`yyyy_mm_dd`, optional) - Forces specified event date. Use this to read past event's data.
* `RADIO_FREQUENCY` (optional) - Displays commentary broadcast frequency on top of the `/` home page.
* `MJ_DIR` (path, optional) - Path to MJTiming directory (defaults to `C:\mjtiming`).
* `MJ_DEBOUNCE_INTERVAL` (integer, optional) - Interval (in ms) between when MJTiming .csv
  files are updated and when Scoreboard tries reading them. For larger events
  with more people and runs in them, MJTiming might require more time to flush
  all data to disk. If you see CSV reading errors in the console, try
  increasing this value (defaults to 1000).
* `DATABASE_PATH` (path, optional) - Path to SQLite3 database file where Scoreboard stores data
  while its running (defaults to `conecerto_scoreboard.db` in user's temporary directory).
* `SECRET_KEY_BASE` (string, optional) - Secret key base required for Phoenix to operate (64
  characters; auto-generated on every launch if not specified)

To continuously upload scores to an external server, set the following:

* `LIVE_FTP_HOST` - FTP hostname
* `LIVE_FTP_USER` - FTP username
* `LIVE_FTP_PASS` - FTP password
* `LIVE_FTP_PATH` (optional) - Website root path relative to FTP account home directory (defaults to home directory).

Note: On Windows, if your password contains `^`, make sure to escape it with another `^`.

Note: The web server needs to be configured to serve pre-compressed pages. See
`misc/htaccess` for the base configuration.

## Developing

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

Copyright (C) 2023 Dimitri Tcaciuc.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.
