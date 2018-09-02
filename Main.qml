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
import Qt.labs.settings 1.0

MainView {
   id: mainView
   // objectName for functional testing purposes (autopilot-qt5)
   objectName: "mainView"

   // Note! applicationName needs to match the "name" field of the click manifest
   applicationName: "activitytracker.cwayne18"

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
   property string drivedistmet: i18n.tr("%1 driven today")

   //keep screen on so we still get to read GPS
   ScreenSaver {
      id: screenSaver
      screenSaverEnabled: !am_running
   }
   Settings {
      id: persistentSettings
      property int pointsInterval: 5000
      // onPointsIntervalChanged: {/*console.log("pointsInterval has changed: "+pointsInterval);*/loggingpoints.interval = pointsInterval}
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
            iconColor: UbuntuColors.jet
            subTitle: i18n.tr("Swipe up to log a new activity")
            anchors.centerIn: parent
         }
      }
      Component.onCompleted: {
         //  listModel.clear()
         //  pygpx.get_runs(listModel)
      }

      ListView {
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
         // pullToRefresh {
         //    enabled: false
         //    onRefresh: pygpx.get_runs()
         // }
         delegate: ListItem {
            id :del
            onClicked: {
               stack.push(Qt.resolvedUrl('QMLMap.qml'), {polyline: filename})
            }

            ListItemLayout {
               ProportionalShape {
                  SlotsLayout.position: SlotsLayout.Leading
                  source: Image { source: "images/"+act_type+".svg" }
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
         hint {
            text: i18n.tr("Log new Activity")
            iconSource: "images/runman.svg"
            status: "Active"
            flickable: thelist
            // onStatusChanged: {
            //    switch (hint.status) {
            //    case 1: console.log("hint status: "+1); hint.status=2; break;
            //    case 0: console.log("hint status: "+0); break;
            //    case 2: console.log("hint status: "+2); break;
            // }
         }
         onCollapseStarted: hint.status = "Active"
         preloadContent: true
         contentUrl: Qt.resolvedUrl("Tracker.qml")
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
