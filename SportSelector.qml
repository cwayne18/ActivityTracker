import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick 2.4
import "components"

OptionSelector {
   id: os
   property Item sportsComponent
   model: sportsComponent.name
   selectedIndex: sportsComponent.selected
   delegate: Component {
      id: selectorDelegate
      OptionSelectorDelegate {
         text: sportsComp.translated[index]
         iconSource: "images/"+sportsComp.name[index]+"-symbolic.svg"
         constrainImage: true
      }
   }
}

// Grid {
//    property int itemWidth: units.gu(12)
//
//    // The amount of whitespace, including column spacing
//    property int space: parent.width - columns * itemWidth
//
//    // The column spacing is 1/n of the left/right margins
//    property int n: 4
//
//    columnSpacing: space / ((2 * n) + (columns - 1))
//    rowSpacing: units.gu(3)
//    width: (columns * itemWidth) + columnSpacing * (columns - 1)
//    anchors.horizontalCenter: parent.horizontalCenter
//    columns: {
//       var items = Math.floor(parent.width / itemWidth)
//       var count = repeater.count
//       return count < items ? count : items
//    }
// }
