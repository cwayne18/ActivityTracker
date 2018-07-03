import QtQuick 2.4
import QtPositioning 5.3
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
import QtSystemInfo 5.0
import QtLocation 5.3
//import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import "./lib/polyline.js" as Pl
import UserMetrics 0.1

MainView {
   // objectName for functional testing purposes (autopilot-qt5)
   objectName: "mainView"

   // Note! applicationName needs to match the "name" field of the click manifest
   applicationName: "activitytracker.ernest"

   // Removes the old toolbar and enables new features of the new header.
   //useDeprecatedToolbar: false

   width: units.gu(100)
   height: units.gu(75)
   property int count;
   property int counter;
   property var gpxx;
   property string day;
   property bool am_running;
   property string runits;
   property string timestring : "00:00"
   property string smashkey;
   property string dist;
   property string distmet: i18n.tr("%1 run today")
   property string bikedistmet: i18n.tr("%1 biked today")
   property string drivedistmet: i18n.tr("%1 drived today")

   //keep screen on so we still get to read GPS
   ScreenSaver {
      id: screenSaver
      screenSaverEnabled: !am_running
   }

   function stopwatch(seconds) {
      var totalNumberOfSeconds = seconds;
      var hours = parseInt( totalNumberOfSeconds / 3600 );
      var minutes = parseInt( (totalNumberOfSeconds - (hours * 3600)) / 60 );
      var seconds = Math.floor((totalNumberOfSeconds - ((hours * 3600) + (minutes * 60))));
      var hours2 = (hours == 0 ? "" : (hours < 10 ? "0" + hours +":" : hours+":"))
      var result = hours2 + (minutes < 10 ? "0" + minutes : minutes) + ":" + (seconds  < 10 ? "0" + seconds : seconds);
      return result
   }


   function formatDist(distance) {
      if (runits == "miles"){
         var mi
         mi = distance * 0.62137 / 1000
         distance = mi.toFixed(2) + "mi"
      }
      else if (runits == "kilometers"){
         if (distance > 1000){
            distance = distance / 1000
            distance = distance.toFixed(2) + "km"
         }
         else
         distance = distance.toFixed(2) + "m"
      }
      return distance
   }

   function formatSpeed(speed) {
      if (runits == "miles"){
         var mi
         mi = speed * 0.62137 / 1000 * 3600
         speed = mi.toFixed(1) + "mi/h"
      }
      else if (runits == "kilometers"){
         speed = speed / 1000 * 3600
         speed = speed.toFixed(1) + "km/h"
      }
      return speed
   }

   ListModel {
      id: listModel
   }
   onRunitsChanged: {
      listModel.clear()
      pygpx.get_runs(listModel)
   }
   Python {
      id: pygpx
      Component.onCompleted: {
         function loadit(result){
            console.warn("STARTING GPX")
            listModel.clear()
            call('geepeeex.onetime_db_fix',[])
            call('geepeeex.onetime_db_fix_again_cus_im_dumb',[])
            get_units(result)
         }
         addImportPath(Qt.resolvedUrl('py/'))
         importModule('geepeeex', loadit)
         console.warn('imported gpxpy')
      }//Component.onCompleted
      function addpoint(gpx,lat,lng,alt,speed){
         call('geepeeex.add_point', [gpxx,lat,lng,alt])
      }//addpoint


      function get_runs(model){
         listModel.clear()
         call('geepeeex.get_runs', [], function(result) {
            // Load the received data into the list model
            listModel.clear()
            for (var i=0; i<result.length; i++) {
               console.warn(runits);
               if (runits == "miles"){
                  console.warn(result[i].distance)
                  //console.warn(result[i].speed)
                  var mi
                  mi = result[i].distance * 0.62137
                  result[i].distance = i18n.tr("Distance: ")+mi.toFixed(2) + "mi"
               }
               else if (runits == "kilometers"){
                  result[i].distance = i18n.tr("Distance: ")+result[i].distance + "km"
               }
               var seconds = parseFloat(result[i].speed) * 60
               result[i].speed = i18n.tr("Time: ") + stopwatch(seconds)
               listModel.append(result[i]);
            }

         });
      }
      function addrun(name){
         console.warn("addiing run")
         call('geepeeex.add_run', [gpxx, name], function(result){
            console.warn("run added")
         })
      }//addrun
      function writeit(gpx, name,act_type){
         console.warn("Writing file")
         var b = Pl.polyline;

         //console.log("https://maps.googleapis.com/maps/api/staticmap?size=400x400&path=weight:3%7Ccolor:blue%7Cenc:"+b.encode(c,4))
         call('geepeeex.write_gpx', [gpxx,name,act_type])
      }//writeit

      function logit(result) {
         console.warn(result)
         gpxx = result
      }//logit
      function create_gpx() {
         call('geepeeex.create_gpx', [], logit);

      }//create_gpx

      function get_units(result) {
         call('geepeeex.get_units', [], function(result){
            console.warn("getting units")
            console.warn(result[0])
            runits = result[0]
            return runits
         }
      )}
      function set_units(units) {
         call('geepeeex.set_units', [units]
      )}

      function rm_run(run) {
         call('geepeeex.rm_run', [run])
      }
      function current_distance(gpx) {
         call('geepeeex.current_distance', [gpxx], function(result) {
            console.warn("DIST")
            console.warn(result)
            //distlabel.text=result
            if (runits == "miles"){
               var mi
               mi = result * 0.62137
               dist = mi.toFixed(2) + "mi"
            }
            else if (runits == "kilometers"){
               dist = result + "km"
            }
            //dist=result
            return dist
         })
      }
      function format_timer(secs){
         call('geepeeex.stopwatchery', [counter], function(result){
            timestring=result
            return result
         })
      }


   }//Python

   Page {
      id: page1
      visible: true
      header: PageHeader {
         title: i18n.tr("Recent Activities")
         id: page1Header
         trailingActionBar.actions: [
         Action {
            text: i18n.tr("Settings")
            iconName: "settings"
            onTriggered: stack.push(Qt.resolvedUrl("Settings.qml"))
         },
         Action {
            text: i18n.tr("About")
            iconName: "info"
            onTriggered: stack.push(Qt.resolvedUrl("About.qml"))
         }
         ]
      }

      Rectangle {
         visible : !(thelist.model.count > 0)
         id: rekt
         anchors {
            left: page1.left
            right: page1.right
            bottom: page1.bottom
            top: page1Header.bottom
         }
         color: "transparent"
         EmptyState {
            title: i18n.tr("No saved activities")
            iconSource: Qt.resolvedUrl("./images/runman.svg")
            subTitle: i18n.tr("Swipe up to log a new activity")
            anchors.centerIn: parent
         }
      }
      Component.onCompleted: {
         //  listModel.clear()
         //  pygpx.get_runs(listModel)
      }

      UbuntuListView {
         anchors {
            left: page1.left
            right: page1.right
            bottom: page1.bottom
            top: page1Header.bottom
         }
         width: parent.width
         height: parent.height
         clip:true
         id:thelist
         model: listModel
         // let refresh control know when the refresh gets completed
         pullToRefresh {
            enabled: false
            onRefresh: pygpx.get_runs()
         }
         delegate: ListItem {
            id :del
            onClicked: {
               stack.push(Qt.resolvedUrl('WebMap.qml'), {polyline: polyline})
            }

            ListItemLayout {
               ProportionalShape {
                  SlotsLayout.position: SlotsLayout.Leading
                  source: Image { source: "images/"+act_type+".png" }
                  height: del.height-units.gu(2)
                  anchors.topMargin: units.gu(1)
                  anchors.top: parent.top
                  aspect: UbuntuShape.DropShadow
               }
               title.text: name
               subtitle.text: speed+"   "+distance
            }

            leadingActions: ListItemActions {
               actions: [
               Action {
                  iconName: "delete"
                  onTriggered: {
                     pygpx.rm_run(id)
                     listModel.remove(index)
                  }
               }
               ]
            }
         }
      }
      Metric {
         id: runmetric
         name: 'activitytracker-runs'
         format: '%1 activities logged today'
         emptyFormat: 'No activities today, go do something!'
         domain: 'metrics-activitytracker'
      }
      Metric {
         id: rundist
         name: 'activitytracker-runsdist'
         format: '%1 ' + distmet.arg(runits)
         emptyFormat: '0 ' + distmet.arg(runits)
         domain: 'metrics-activitytracker'
      }
      Metric {
         id: bikedist
         name: 'activitytracker-bikes'
         format: '%1 ' + bikedistmet.arg(runits)
         emptyFormat: '0 ' + bikedistmet.arg(runits)
         domain: 'metrics-activitytracker'
      }
      Metric {
         id: drivedist
         name: 'activitytracker-drive'
         format: '%1 ' + drivedistmet.arg(runits)
         emptyFormat: '0 ' + drivedistmet.arg(runits)
         domain: 'metrics-activitytracker'
      }

      BottomEdge {
         id:newrunEdge
         hint.text: i18n.tr("Log new Activity")
         preloadContent: true
         contentComponent: Rectangle {
            color: "white"
            width: page1.width
            height: page1.height
            Page {
               anchors.fill: parent
               id: newrunPage
               header: PageHeader {
                  title: (am_running) ? i18n.tr("Activity in Progress") : i18n.tr("New Activity")
                  leadingActionBar.actions: [
                  Action {
                     iconName: "back"
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
                        text: "Yes I'm sure"
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
                           pygpx.addpoint(gpxx,coord.latitude,coord.longitude,coord.altitude)
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
               Component.onCompleted: {
                  src.start()
               }

               Map {
                  id: map
                  anchors.fill: parent
                  center: src.position.coordinate
                  zoomLevel: map.maximumZoomLevel - 5
                  plugin : Plugin {
                     id: plugin
                     allowExperimental: true
                     preferred: ["osm"]
                     required.mapping: Plugin.AnyMappingFeatures
                     required.geocoding: Plugin.AnyGeocodingFeatures
                     //parameters: [
                     //    PluginParameter { name: "mapbox.access_token"; value: "" },
                     //    PluginParameter { name: "mapbox.map_id"; value: "cwayne18.lklp3m7i" }
                     //]
                  }

                  Component.onCompleted: {
                     map.addMapItem(circle)
                     // pline.addCoordinate(src.position.coordinate)
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
                     title: i18n.tr("Save Activity")
                     text: ""

                     OptionSelector {
                        id: os
                        text: i18n.tr("Activity Type")
                        expanded: true
                        model: [
                        // FIXME: some codes depends on the name of the activity
                        // cannot translate atm...
                        /*i18n.tr(*/"Run"/*)*/,
                        /*i18n.tr(*/"Bike Ride"/*)*/,
                        /*i18n.tr(*/"Walk"/*)*/,
                        /*i18n.tr(*/"Drive"/*)*/,
                        /*i18n.tr(*/"Hike"/*)*/
                        ]
                     }
                     Label {
                        text: i18n.tr("Name")
                     }

                     TextField {
                        text: os.model[os.selectedIndex] + " " + day
                        id: tf
                        Component.onCompleted: {
                           var d = new Date();
                           day = d.toDateString();
                        }
                     }
                     Row {

                        Button {
                           text: i18n.tr("Save Activity")
                           height: units.gu(10)
                           width: parent.width /2
                           color: UbuntuColors.green
                           onClicked: {
                              PopupUtils.close(dialogue)
                              pygpx.writeit(gpxx,tf.displayText,os.model[os.selectedIndex])
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
                              //stack.pop()

                           }
                        }
                        Button {
                           text: i18n.tr("Cancel")
                           height: units.gu(10)
                           width: parent.width / 2
                           color: UbuntuColors.red
                           onClicked: {
                              PopupUtils.close(dialogue)
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
                           am_running = false
                           timer.stop()
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
      }//Bottom edge

   }//Page

   PageStack {
      id: stack
      Component.onCompleted: {
         am_running = false
         stack.push(page1)
      }
   }
}
