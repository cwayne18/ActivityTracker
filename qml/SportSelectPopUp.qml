import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick 2.4
import "components"

Dialog {
   id: sportselectdialog
   property Item sportsComponent

   title: i18n.tr("Choose sport:")
   SportSelector {
      sportsComponent: sportselectdialog.sportsComponent
      expanded: true
      onDelegateClicked: {
         sportsComponent.selected=index
         PopupUtils.close(sportselectdialog)
         openDialog=false
      }
   }
   Button {
      text: sportsComponent.selected != -1 ? i18n.tr("Cancel") : i18n.tr("Choose later")
      onClicked:{
         PopupUtils.close(sportselectdialog)
         openDialog=false
      }
   }
}
