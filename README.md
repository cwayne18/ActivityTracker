

# ActivityTracker
This repo is a fork of the original app created by CWayne18.

The app has been upgraded by Michele and Ernes_t to work only on 16.04 Ubuntu Touch.
Due to older QML lib on 15.04, the changes cannot be retrofitted.

## Majors changes 0.12:
- Improved sport selection
- Missing appname substitution and removed unused images
- Back to appname cwayne18, UX and translation improvements. Updated it.po
- Add features: Importing GPX files from another folder through the contenthub, renaming and changing activity
- Bumping the software revsion to 0.12
- Add GPX info feature next to editing
- Add refresh indicator to load GPX info + some cleanup
- Created proper components to handle useful dialogs
- Code cleanup: Remove metrics, contentPickerDialog & Polyline
- Fixed PositionSource not being closed and code cleaning
- Theme support

## Majors changes initial Xenial version:
- Add speed and altitude, thanks to https://github.com/cwayne18/ActivityTracker/pull/17
- Update of the QML code
- Uniformise and change the tile service to QML/OSM.
- Implement a routing to parse locally the gpx track
- Allow setting frequency of position recording. (it's adviced to not go below a frequency of 10 or 5 seconds in order to not saturate the GPX file. The more data points it has, the longer it will take to display.)

## General information
 - Due to a OS limitation the recording must occur with the screen on
 - The GPX files are located in .local/share/activitytracker.cwayne18/

 ## Thanks
  - Michele for the logo
  - Joan CiberSheep for the icons.
  - Anne for the French translation: https://github.com/cwayne18/ActivityTracker/pull/14
  - Wagafo for the Catalan translation
  - j2g2rp for the Spanish translation
