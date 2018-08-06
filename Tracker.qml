import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtPositioning 5.3
import QtLocation 5.3

Rectangle {
   color: "white"
   width: page1.width
   height: page1.height
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
            title: i18n.tr("Are you sure?")
            text: i18n.tr("Are you sure you want to cancel the activity?")
            Button {
               id: yesimsure
               text: i18n.tr("Yes I'm sure")
               height: units.gu(10)
               color: UbuntuColors.green
               onClicked: {
                  PopupUtils.close(areyousuredialog)
                  //timer.start()
                  counter = 0
                  pygpx.format_timer(0)
                  timer.restart()
                  timer.stop()
                  am_running = false
                  newrunEdge.collapse()
               }
            }
            Button {
               id: noooooooodb
               text: i18n.tr("No")
               height: units.gu(10)
               color: UbuntuColors.red
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
                  pline.addCoordinate(QtPositioning.coordinate(coord.latitude,coord.longitude, coord.altitude))
                  pygpx.current_distance(gpxx)
                  distlabel.text = dist
                  console.warn("========================")
                  //console.warn(pygpx.current_distance(gpxx))
               }
               if (src.position.altitudeValid) {
                  altlabel.text = formatDist(coord.altitude)
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
                  pygpx.addpoint(gpxx,coord.latitude,coord.longitude,coord.altitude)
                  console.log("Coordinate:", coord.longitude, coord.latitude)
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
            title: i18n.tr("Stop Recording Activity?")
            text: i18n.tr("Do you want to stop recording your activity?")
            Button {
               text: i18n.tr("Yes, Stop!")
               height: units.gu(10)
               color: UbuntuColors.green
               onClicked: {
                  PopupUtils.close(dialogue)
                  am_running = false
                  timer.stop()
                  PopupUtils.open(save_dialog)
               }
            }
            Button {
               text: i18n.tr("No, Continue")
               height: units.gu(10)
               color: UbuntuColors.red
               onClicked: {
                  PopupUtils.close(dialogue)
               }
            }
         }
      }//Dialog component

      Component {
         id: save_dialog
         Dialog {
            id: save_dialogue
            title: i18n.tr("Save Activity")
            text: i18n.tr("Select the type and the name of your activity")

            Label {
               text: i18n.tr("Name")
            }

            TextField {
               placeholderText: os.model[os.selectedIndex] + " " + day
               id: tf
               property var name: displayText == "" ? placeholderText : displayText
               Component.onCompleted: {
                  var d = new Date();
                  day = d.toDateString();
               }
            }
            OptionSelector {
               id: os
               text: i18n.tr("Activity Type")
               currentlyExpanded: true
               containerHeight: itemHeight*3.5
               model: [
               // FIXME: some codes depends on the name of the activity
               // cannot translate atm...
               /*i18n.tr(*/"Run"/*)*/,
               /*i18n.tr(*/"Bike Ride"/*)*/,
               /*i18n.tr(*/"Walk"/*)*/,
               /*i18n.tr(*/"Drive"/*)*/,
               /*i18n.tr(*/"Hike"/*)*/
               ]
               onExpansionCompleted: tf.focus = true
            }
            Row {
               spacing: units.gu(1)
               Button {
                  text: i18n.tr("Save Activity")
                  height: units.gu(8)
                  width: parent.width /2 -units.gu(0.5)
                  color: UbuntuColors.green
                  onClicked: {
                     PopupUtils.close(save_dialogue)
                     pygpx.writeit(gpxx,tf.name,os.model[os.selectedIndex])
                     console.log(tf.displayText)
                     console.log("----------restart------------")
                     counter = 0
                     pygpx.format_timer(0)
                     timer.restart()
                     timer.stop()

                     //  listModel.append({"name": tf.displayText, "act_type": os.model[os.selectedIndex]})
                     //   pygpx.addrun(tf.displayText)
                     listModel.clear()
                     runmetric.increment(1)
                     var distfloat
                     distfloat = parseFloat(dist.slice(0,-2))
                     if (os.model[os.selectedIndex] == 'Run'){
                        console.log("LOGARUN")
                        rundist.increment(distfloat)
                     }
                     if (os.model[os.selectedIndex] == "Bike Ride") {
                        bikedist.increment(distfloat)
                     }
                     if (os.model[os.selectedIndex] == "Drive") {
                        drivedist.increment(distfloat)
                     }
                     pygpx.get_runs(listModel)
                     newrunEdge.collapse()
                     newrunEdge.contentUrl = ""
                     newrunEdge.contentUrl = Qt.resolvedUrl("Tracker.qml")
                  }
               }
               Button {
                  text: i18n.tr("Cancel")
                  height: units.gu(8)
                  width: parent.width /2 -units.gu(0.5)
                  color: UbuntuColors.red
                  onClicked: {
                     PopupUtils.close(save_dialogue)
                     am_running = true
                     timer.start()
                  }
               }
            }
         }
      }//Dialog component

      Rectangle {
         width: parent.width

         height: units.gu(10)
         // z:100
         anchors.bottom: parent.bottom
         color: "white"
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
                  // src.stop()
                  // am_running = false
                  // timer.stop()
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
