import Lomiri.Components 1.3
import QtQuick 2.4
import Lomiri.Components.Popups 1.3
import "components"


Dialog {
   id: activity_dialogue
   property Item sportsComponent    //TODO if editing, set sportsComponent.selected to the sport of the track
   property alias save: save_button
   property alias cancel: cancel_button
   property alias trackName: tf.name
   Component.onCompleted: sportsComponent.previous = sportsComponent.selected

   Label {
      text: i18n.tr("Name")
   }
   TextField {
      placeholderText: sportsComponent.selected == -1 ? i18n.tr("Select a sport below") : sportsComponent.translated[sportsComponent.selected] + " " + day
      id: tf
      // text: get from track info if editing an existing track, or get from metadata if importing TODO
      property var name: displayText == "" ? placeholderText : displayText
      Component.onCompleted: {
         var d = new Date();
         day = d.toDateString();
      }
   }
   SportSelector {
      text: i18n.tr("Activity Type")
      sportsComponent: activity_dialogue.sportsComponent
      currentlyExpanded: sportsComponent.selected == -1
      containerHeight: itemHeight*3.5
      onDelegateClicked: sportsComponent.selected=index
   }
   Row {
      spacing: units.gu(1)
      PopUpButton {
         id: save_button
         texth: i18n.tr("Save")
         height: units.gu(8)
         width: parent.width /2 -units.gu(0.5)
         color: LomiriColors.green
         enabled: sportsComponent.selected != -1
         // on clicked event is handled in Tracker.qml
      }

      PopUpButton {
         id: cancel_button
         texth: i18n.tr("Cancel")
         height: units.gu(8)
         width: parent.width /2 -units.gu(0.5)
         color: LomiriColors.red
         onClicked: {
           PopupUtils.close(activity_dialogue)
        }
      }
   }
}
