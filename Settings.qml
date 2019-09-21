import QtQuick 2.4
import Ubuntu.Components 1.3
import QtSystemInfo 5.0
import QtLocation 5.3
import Ubuntu.Components.ListItems 1.3 as LI
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Pickers 1.3


Page {
   title: "PickerPanel"
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
            // property date date: new Date()
            title.text: i18n.tr("Log a point every:")
            // subtitle.text: Qt.formatDateTime(date, "ss")
            summary.text: i18n.tr("between 50 and 3600000")
            // Row {
               TextField {
                  id: pointsIntervalField
                  // text: persistentSettings.pointsInterval/1000
                  color: !acceptableInput ? UbuntuColors.red : theme.palette.normal.backgroundText
                  placeholderText: "5000"
                  inputMethodHints: Qt.ImhDigitsOnly //Qt.ImhFormattedNumbersOnly
                  hasClearButton:false
                  // double validator not working
                  // validator: DoubleValidator {bottom:0.05; top:3600; /*decimals:2; notation: DoubleValidator.StandardNotation*/}//50ms -1h
                  validator: IntValidator {
                     bottom:50;
                     top:3600000;
                  }//50ms -1h
                  width: units.gu(length>0?length:placeholderText.length)+units.gu(2.75)
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
               // TRANSLATORS: millisecond abbreviation
               text:i18n.tr("ms");
               SlotsLayout.position:SlotsLayout.Last;
            }
         }
       }
      ListItem {
        divider.visible: false
        height:altitudeOffsetLayout.height
         ListItemLayout {
            id: altitudeOffsetLayout
            title.text: i18n.tr("Altitude offset:")
            summary.text: i18n.tr("between -100 and 100")
               TextField {
                  id: altitudeOffsetField
                  color: !acceptableInput ? UbuntuColors.red : theme.palette.normal.backgroundText
                  placeholderText: "0"
                  inputMethodHints: Qt.ImhDigitsOnly
                  hasClearButton:false
                  validator: IntValidator {
                     bottom:-100;
                     top:100;
                  }
                  width: units.gu(length>0?length:placeholderText.length)+units.gu(2.75)
                  SlotsLayout.position:SlotsLayout.Trailing
                  onTextChanged: {
                     if (acceptableInput)
                     persistentSettings.altitudeOffset = text | 0
                     else if (length==0)
                     persistentSettings.altitudeOffset = 0 //default value
                  }
                  Component.onCompleted: text = persistentSettings.altitudeOffset
               }
            Label {
               text:i18n.tr("meter(s)");
               SlotsLayout.position:SlotsLayout.Last;
            }
         }
      }
   }
}
