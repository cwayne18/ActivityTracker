import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtPositioning 5.9
import QtLocation 5.9
import "components"

Rectangle {
   id: trackerroot
   property bool openDialog: false
   onOpenDialogChanged: openDialog == true ? PopupUtils.open(sportselect) : ""
   Sports {id:sportsComp}
   color: Theme.palette.normal.background
   width: page1.width
   height: page1.height
   property int altitudeCorrected

   Component {
      id:sportselect
      SportSelectPopUp {
         sportsComponent: sportsComp
      }
   }

   Page {
      id: newrunPage
      anchors.fill: parent
      header: PageHeader {
         title: (am_running) ? i18n.tr("Activity in Progress") : i18n.tr("New Activity")
         leadingActionBar.actions: [
         Action {
            iconName: "down"
            onTriggered: {
               if (am_running) {
                  PopupUtils.open(areyousure)
               }
               else {
                  newrunEdge.collapse()
               }
            }
         }
         ]

         trailingActionBar.actions: [
         Action {
            iconSource: "images/"+sportsComp.name[sportsComp.selected]+"-symbolic.svg"
            visible: sportsComp.selected != -1
            onTriggered: PopupUtils.open(sportselect)
         }
         ]
      }

      Timer {
         interval: 1000
         running: false
         repeat: true
         id:timer
         onTriggered: {
            counter++
            pygpx.format_timer(counter)
         }
      }
      Component {
         id: areyousure
         Dialog {
            id: areyousuredialog
            title: i18n.tr("Do you want to cancel the activity?")
            PopUpButton {
               id: yesimsure
               texth: i18n.tr("Yes, cancel")
               color: UbuntuColors.red
               onClicked: {
                  PopupUtils.close(areyousuredialog)
                  timer.start()
                  counter = 0
                  pygpx.format_timer(0)
                  var distfloat
                  distfloat = parseFloat(dist.slice(0,-2)) //clean up the gpx array but not the maps / path
                  map.removeMapItem(pline)
                  timer.restart()
                  timer.stop()
                  am_running = false
                  sportsComp.reset()
                  newrunEdge.collapse()
               }
            }
            PopUpButton {
               id: noooooooodb
               texth: i18n.tr("No, continue")
               color: UbuntuColors.green
               onClicked: {
                  PopupUtils.close(areyousuredialog)
                  am_running = true
                  timer.start()
               }
            }
         }
      }

      PositionSource {
         id: src
         updateInterval: 1000
         active: true
         preferredPositioningMethods: PositionSource.SatellitePositioningMethods


         onPositionChanged: {
            var coord = src.position.coordinate;
            count++
            //  console.log("Coordinate:", coord.longitude, coord.latitude);
            map.center = QtPositioning.coordinate(coord.latitude, coord.longitude)
            circle.center = QtPositioning.coordinate(coord.latitude, coord.longitude)

            if (gpxx && am_running){

               if (src.position.latitudeValid && src.position.longitudeValid && src.position.altitudeValid) {
                  //pygpx.addpoint(gpxx,coord.latitude,coord.longitude,coord.altitude)
                  altitudeCorrected = coord.altitude + persistentSettings.altitudeOffset
                  pline.addCoordinate(QtPositioning.coordinate(coord.latitude,coord.longitude, altitudeCorrected))
                  pygpx.current_distance(gpxx)
                  distlabel.text = dist
                  console.warn("========================")
                  //console.warn(pygpx.current_distance(gpxx))
               }
               if (src.position.altitudeValid) {
                  altlabel.text = formatAlt(altitudeCorrected)
               } else {
                  altlabel.text = i18n.tr("No data")
               }
               if (src.position.speedValid) {
                  speedlabel.text = formatSpeed(src.position.speed)
               } else {
                  speedlabel.text = i18n.tr("No data")
               }
            }
         }
      }
      Timer {
         id: loggingpoints
         interval: persistentSettings.pointsInterval; running: true; repeat: true
         onTriggered: {
            var coord = src.position.coordinate
            if (gpxx && am_running){

               if (src.position.latitudeValid && src.position.longitudeValid && src.position.altitudeValid) {
                 altitudeCorrected = coord.altitude + persistentSettings.altitudeOffset
                  pygpx.addpoint(gpxx,coord.latitude,coord.longitude,altitudeCorrected)
                  console.log("Coordinate:", coord.longitude, coord.latitude)
                  console.log("calibrated altitude :", altitudeCorrected, "& raw Altitude:", coord.altitude )
               }

            }
         }
      }
      Component.onCompleted: {
         src.start()
      }

      Map {
         id: map
         anchors.fill: parent
         center: src.position.coordinate
         zoomLevel: map.maximumZoomLevel - 2
         color: Theme.palette.normal.background
         plugin : Plugin {
            id: plugin
            allowExperimental: true
            preferred: ["osm"]
            required.mapping: Plugin.AnyMappingFeatures
            required.geocoding: Plugin.AnyGeocodingFeatures
         }

         Component.onCompleted: {
            map.addMapItem(circle)
            map.center = src.position.coordinate
         }
      }//Map

      MapCircle{
         id:circle
         center : src.position.coordinate
         radius : 30.0
         opacity: .3
         color : UbuntuColors.green
         border.width : 3
      }
      MapPolyline {
         id: pline
         line.width: 4
         line.color: 'red'
         path: []
      }
      Component {
         id: dialog
         Dialog {
            id: dialogue
            title: i18n.tr("Do you want to stop the recording?")
            PopUpButton {
               texth: i18n.tr("Yes, Stop!")
               color: UbuntuColors.green
               onClicked: {
                  PopupUtils.close(dialogue)

                  //FIXME: do I want to add a point even if gps params aren't valid? I want to add a point here to get the exact time of activity
                  var coord = src.position.coordinate
                  if (gpxx && am_running){
                     if (src.position.latitudeValid && src.position.longitudeValid && src.position.altitudeValid) {
                       altitudeCorrected = coord.altitude + persistentSettings.altitudeOffset
                        pygpx.addpoint(gpxx,coord.latitude,coord.longitude,altitudeCorrected)
                        //pygpx.addpoint(gpxx,coord.latitude,coord.longitude,coord.altitude)
                     }
                  }
                  src.stop()
                  am_running = false
                  timer.stop()
                  PopupUtils.open(save_dialog)
               }
            }
            PopUpButton {
               texth: i18n.tr("No, Continue")
               color: UbuntuColors.red
               onClicked: PopupUtils.close(dialogue)
            }
         }
      }//Dialog component

      Component {
         id: save_dialog
         ActivityDialog {
            id: save_dialogue
            sportsComponent: sportsComp
            title: i18n.tr("Select the type and the name of your activity")
            save.onClicked: {
               PopupUtils.close(save_dialogue)
               pygpx.writeit(gpxx,trackName,sportsComponent.name[sportsComponent.selected])
               console.log(trackName)
               console.log("----------restart------------")
               // counter & timer stuff used only here in Tracker -> why? FIXME
               counter = 0
               pygpx.format_timer(0)
               timer.restart()
               timer.stop()

               //  listModel.append({"name": tf.displayText, "act_type": sportsComp.name[sportsComp.selected]})
               //   pygpx.addrun(tf.displayText)
               listModel.clear()
               // distfloat stuff used only here in Tracker -> why? FIXME
               var distfloat
               distfloat = parseFloat(dist.slice(0,-2))
               pygpx.get_runs(listModel)
               newrunEdge.collapse()
               newrunEdge.contentUrl = ""
               newrunEdge.contentUrl = Qt.resolvedUrl("Tracker.qml")
            }
            cancel.onClicked: {
               PopupUtils.close(save_dialogue)
               am_running = true
               timer.start()
               sportsComp.selected=sportsComp.previous
            }
         }
      }

      Rectangle {
         width: parent.width

         height: units.gu(10)
         // z:100
         anchors.bottom: parent.bottom
         color: theme.palette.normal.background
         opacity: 0.8
         Row{
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            id: stuffrow


            Column {
               Label {
                  text: "Time"
                  //fontSize: "small"
               }
               Label {
                  text: timestring
                  fontSize: "large"
                  //text: "00:00"
               }
               Label {
                  text: "Speed"
                  fontSize: "small"
               }
               Label {
                  id: speedlabel
                  text: "No data"
                  fontSize: "large"
               }
            }

            Button {
               text: i18n.tr("Start")
               color: UbuntuColors.green
               visible: !am_running
               height: units.gu(10)
               //   width:parent.width/2
               //   height:parent.height
               onClicked: {
                  // loggingpoints.interval = persistentSettings.pointsInterval //useful or not ?
                  //listModel.clear()
                  if (!src.active){
                     src.start()
                  }
                  timer.start()
                  if (src.valid){
                     pygpx.create_gpx()
                     map.addMapItem(pline)
                     am_running=true
                  }
               }
            }
            Button {
               text: i18n.tr("Stop")
               color: UbuntuColors.red
               visible:am_running
               height: units.gu(10)
               //   width:parent.width/2
               //   height:parent.height
               onClicked: {
                  PopupUtils.open(dialog)

               }
            }//Button
            Column {
               Label {
                  text: "Distance"
                  //fontSize: "small"
               }
               Label {
                  id: distlabel
                  text: "0"
                  fontSize: "large"
               }
               Label {
                  text: "Altitude"
                  //  fontSize: "small"
               }
               Label {
                  id: altlabel
                  text: "No data"
                  fontSize: "large"
               }
            }

         }
      }//Item (buttons)
   }
}
