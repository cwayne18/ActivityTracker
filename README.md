

# ActivityTracker
This repos is a forked of the original application created by CWayne18.

The application has been upgraded by Michele and Ernes_t to work only on 16.04 ubuntu touch.
Due to older QML lib on 15.04 the changes cannot be retrofited.

## Majors changes :
- Add speed and altitude, thanks to https://github.com/cwayne18/ActivityTracker/pull/17
- Update of the QML code,
- Uniformise and change the tile service to QML/OSM.
- Implement a routing to parse locally the gpx track
- Allow to set the frequency of position recording. (it's adviced to have a frequency not below 10 or 5 seconds in order to not saturate the gpx file. More data point the gpx has, longer it will take to display it.)

## General information
 - Due to OS limitation the recording must happen screen on
 - The gpx files are located in .local/share/activitytracker.cwayne18/

 ## Thanks
  - Michele for the logo
  - Joan CiberSheep for the icons.
  - Anne for the French translation : https://github.com/cwayne18/ActivityTracker/pull/14
  - Wagafo for the Catalan translation
  - j2g2rp  for the Spanish translation
