import QtQuick 2.4
import Ubuntu.Components 1.3
import QtSystemInfo 5.0
import QtLocation 5.2
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import "./lib/polyline.js" as Pl



Page {
   header: PageHeader {
      id: settingsHeader
      title: "Units"
   }
   id:settings

   ListItem.ItemSelector {
      anchors {
         top: settingsHeader.bottom
         left: parent.left
         right: parent.right
      }
      text: i18n.tr("Units")
      model: ["Kilometers", "Miles"]
      expanded: true
      selectedIndex: switch(runits) {
         case "kilometers": return 0;
         case "miles": return 1;
      }
      onSelectedIndexChanged: {
         console.warn(model[selectedIndex].toLowerCase())
         runits=model[selectedIndex].toLowerCase()
         pygpx.set_units(model[selectedIndex].toLowerCase())
      }
   }

}
