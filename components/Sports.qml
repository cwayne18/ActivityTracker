import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
   //List of available sports translatable to be shown in the GUI
   readonly property var translated: [
   i18n.tr("Run"),
   i18n.tr("BikeRide"),
   i18n.tr("Walk"),
   i18n.tr("Drive"),
   i18n.tr("Hike")
   ]
   //List of available sports not translatable to be used as property value for each track
   readonly property var name: ["Run","BikeRide","Walk","Drive","Hike"]
   // index of the selected sport when editing/importing/saving a track
   property int selected: -1
   // index of the sport selected in the first dialog popped up while tracking a new activity
   // it's used to restore that value if the user select another sport in the saving dialog after finishing tracking
   // but goes back to tracking
   property int previous: -1
   // reset properties value to default one
   function reset() {
       selected=-1;
       previous=-1;
   }
}
