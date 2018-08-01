import QtQuick 2.4
import Ubuntu.Components 1.3
import QtSystemInfo 5.0
import QtLocation 5.2
import Ubuntu.Components.ListItems 1.3 as LI
import Ubuntu.Components.Popups 1.3
import "./lib/polyline.js" as Pl



Page {
   header: PageHeader {
      id: settingsHeader
      title: i18n.tr("Settings")
   }
   id:settings
   Column {
      anchors {
         left: parent.left; right: parent.right; bottom: parent.bottom
         top: settingsHeader.bottom
      }

      LI.ItemSelector {
         anchors {
            left: parent.left
            right: parent.right
         }
         text: i18n.tr("Units")
         model: ["Kilometers", "Miles"]
         expanded: true
         selectedIndex: switch(runits) {case "kilometers": return 0; case "miles": return 1;}
         onSelectedIndexChanged: {
            console.warn(model[selectedIndex].toLowerCase())
            runits=model[selectedIndex].toLowerCase()
            pygpx.set_units(model[selectedIndex].toLowerCase())
         }
      }

      ListItem {
         divider.visible: false
         height:pointsIntervalLayout.height
         ListItemLayout {
            id: pointsIntervalLayout
            title.text: i18n.tr("Log a point every:")
            summary.text: i18n.tr("between 50 and 3600000")
            Component.onCompleted: console.log(summary.color)

            TextField {
               // text: persistentSettings.pointsInterval/1000
               color: !acceptableInput ? UbuntuColors.red : UbuntuColors.jet
               placeholderText: "5000"
               inputMethodHints: Qt.ImhDigitsOnly //Qt.ImhFormattedNumbersOnly
               hasClearButton:false
               // double validator not working
               // validator: DoubleValidator {bottom:0.05; top:3600; /*decimals:2; notation: DoubleValidator.StandardNotation*/}//50ms -1h
               validator: IntValidator {
                  bottom:50;
                  top:3600000;
               }//50ms -1h
               width: units.gu(length>0?length:4)+units.gu(3)
               SlotsLayout.position:SlotsLayout.Trailing
               onTextChanged: {
                  if (acceptableInput)
                  persistentSettings.pointsInterval = text/**1000*/ | 0
                  else if (length==0)
                  persistentSettings.pointsInterval = 5000 //default value
               }
               Component.onCompleted: text = persistentSettings.pointsInterval///1000
            }
            Label {
               text:i18n.tr("ms");
               SlotsLayout.position:SlotsLayout.Last;
            }
         }
      }
   }
}
