import QtQuick 2.4
import Ubuntu.Components 1.3
import "components"

Page {
   header: PageHeader {
      id: pageHeader
      title: i18n.tr("About")
   }

   Flickable {

      id: page_flickable
      anchors {
         top: pageHeader.bottom
         left: parent.left
         right: parent.right
         bottom: parent.bottom
      }
      contentHeight:  about_column.height + units.gu(6)
      clip: true
      Column {
         id: about_column
         anchors.centerIn: parent
         spacing: units.gu(4)
         width: parent.width-spacing
         // #335280 is the new blue by Canonical
         // https://github.com/CanonicalLtd/desktop-design/blob/master/Colour/colour.png
         property string themableBlue: Theme.name == "Ubuntu.Components.Themes.SuruDark" ? UbuntuColors.blue : "#335280"
         property string linkColor: " style=\"color:"+about_column.themableBlue+";\""  //' style="color:'+ about_column.themableBlue +';"'

         Column {
            width: parent.width

            Label {
               font.weight: Font.DemiBold
               text: i18n.tr("Activity Tracker")
               font.pointSize: units.gu(2.5)
               anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
               text: i18n.tr("Version") + " 0.15"
               anchors.horizontalCenter: parent.horizontalCenter
            }
         }

         ProportionalShape {
            id: logo
            width: units.gu(17)
            source: Image {
               source: "images/new-icon.svg"
            }
            anchors.horizontalCenter: parent.horizontalCenter
            aspect: UbuntuShape.DropShadow
         }

         Column {
            width: parent.width

            Label {
               text: "© 2018-2019 Erne st & Michele Castellazzi"
               anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
               textFormat: Text.RichText
               text: "<a "+about_column.linkColor+" href=\"https://github.com/cwayne18/ActivityTracker\"> © 2015 Chris Wayne</a>"
               anchors.horizontalCenter: parent.horizontalCenter
               color: about_column.themableBlue
            }
         }

         Column {
            width: parent.width
            spacing: units.gu(2)

            Label {
               textFormat: Text.RichText
               font.underline: false
               text: i18n.tr("Released under the terms of the GNU GPL v3.<br>Source code available on") + " <a style=\"text-decoration: none;color:"+about_column.themableBlue+";\" href=\"https://github.com/ernesst/ActivityTracker\">GitHub.com</a>"
               font.pointSize: units.gu(1)
               horizontalAlignment: Text.AlignHCenter
               anchors.horizontalCenter: parent.horizontalCenter
               onLinkActivated: Qt.openUrlExternally(link)
            }

            Label {
               textFormat: Text.RichText
               text: i18n.tr('Part of the icons is made by %1 from %2 is licensed by %3')
               .arg('<a href="http://www.freepik.com" title="Freepik"'+about_column.linkColor+'>Freepik</a>')
               .arg('<a href="https://www.flaticon.com/" title="Flaticon"'+about_column.linkColor+'>www.flaticon.com</a>')
               .arg('<a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank"'+about_column.linkColor+'>CC 3.0 BY</a>"')
               anchors.horizontalCenter: parent.horizontalCenter
               horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.Wrap
               font.pointSize: units.gu(1)
               width: parent.width
            }
            Label {
                textFormat: Text.RichText
                //TRANSLATORS: %1 is the name of the author of the icons, %2 is the project name. args from %3 to %7 are icon name while %8 to %12 are original authors names
                text: i18n.tr("Thanks to %1 for the icons based on:<br>"+
                "%3 by %8 from %2,<br>"+
                "%4 by %9 from %2,<br>"+
                "%5 by %10 from %2,<br>"+
                "%6 by %11 from %2,<br>"+
                "%7 by %12 from %2").arg("Joan CiberSheep").arg("The Noun Project")
                .arg("Run CC").arg("Hiking CC").arg("Bike CC").arg("Walk CC").arg("Car CC")
                .arg("Vladimir Belochkin").arg("Think TIfferent").arg("Sakchai Ruankam").arg("Adrien Coquet").arg("Aneeque Ahmed")
               anchors.horizontalCenter: parent.horizontalCenter
               horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.Wrap
               font.pointSize: units.gu(1)
               width: parent.width
            }
         }

         Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing:units.gu(1)
            Icon {name:"language-chooser";color:UbuntuColors.blue;height:translate.height}
            Button {
               id: translate
               text: i18n.tr("Translate this app on Weblate!")
               onClicked: Qt.openUrlExternally("https://hosted.weblate.org/projects/activity-tracker/")
            }
         }
         Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing:units.gu(1)
            Icon {name:"like";color:UbuntuColors.red;height:supportWL.height}
            Button {
               id:supportWL
               text: i18n.tr("Support Weblate")
               onClicked: Qt.openUrlExternally("https://weblate.org/donate/")
            }
         }
      }
   }
}
