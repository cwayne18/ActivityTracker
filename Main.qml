import QtQuick 2.4
import QtPositioning 5.9
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
import QtSystemInfo 5.0
import QtLocation 5.9
//import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import "./lib/polyline.js" as Pl
import Qt.labs.settings 1.0
import Ubuntu.Content 1.3
import "components"

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
   property var importfile;
   property var infofile;
   property var info_display;
   property var gpxx;
   property var name;
   property var infodis;
   property var act_type;
   property var filename;
   property var indexrun;
   property var polyline;
   property string day;
   property bool am_running;
   property string runits;
   property string timestring : "00:00"
   property string smashkey;
   property string dist;
   Sports {id:sportsComp}

   //keep screen on while tracking an activity so we still get to read GPS
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
         };
         addImportPath(Qt.resolvedUrl('py/'));
         importModule('geepeeex', loadit);
         console.warn('imported gpxpy');
         importModule('gpximport', loadit);
         console.warn('imported gpximport');
         importModule('gpxinfo', loadit);
         console.warn('imported gpxinfo');

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
               //console.warn(runits);
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
         console.warn("adding run")
         call('geepeeex.add_run', [gpxx, name], function(result){
            console.warn("run added")
         })
      }//addrun
      function writeit(gpx, name,act_type){
         console.warn("Writing file")
         var b = Pl.polyline;
         call('geepeeex.write_gpx', [gpxx,name,act_type])
      }//writeit
      function import_run(importfile, name,act_type){
         console.warn("importing " +  importfile)
         call('gpximport.Import_run', [importfile,name,act_type])
      }//Import gpx file
      function info_run(id){
        // console.warn("Printing info : " +  infofile)
         call('gpxinfo.Info_run', [id],function(info_display)
         {//console.log("2 ",info_display);
         infodis = info_display;
          //console.log("[LOG]: Reading contents from Python");
         })
      }//gpx file info
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
      function set_units(units) {call('geepeeex.set_units', [units])}
      function rm_run(run) {call('geepeeex.rm_run', [run])}
      function edit_run(run,name,act_type) {call('geepeeex.edit_run', [run,name,act_type])}
      function current_distance(gpx) {
         call('geepeeex.current_distance', [gpxx], function(result) {
            console.warn("DIST")
            console.warn(result)
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
          },
         Action {
            text: i18n.tr("Import")
            iconName: "import"
            onTriggered: {

            var importPage = stack.push(Qt.resolvedUrl("ImportPage.qml"),{"contentType": ContentType.All, "handler": ContentHandler.Source})
            importPage.imported.connect(function(fileUrl) {
                importfile = fileUrl
                PopupUtils.open(save_dialog)
              })//Import
          }//trigger
        }//Action
      ]
    }//PageHeader

       Component {
          id: save_dialog
          ActivityDialog {
             id: save_dialogue
             sportsComponent: sportsComp
             title: i18n.tr("Select the type and the name of your activity")
             save.onClicked: {
                PopupUtils.close(save_dialogue)
                pygpx.import_run(importfile,trackName,sportsComponent.name[sportsComponent.selected])
                listModel.clear()
                pygpx.get_runs(listModel)
             }
          }
       }

      Component {
         id: edit_dialog
         ActivityDialog {
            id: edit_dialogue
            sportsComponent: sportsComp
            title: i18n.tr("Edit the type and the name of your activity")
            save.onClicked: {
                PopupUtils.close(edit_dialogue)
                pygpx.edit_run(indexrun,sportsComponent.name[sportsComponent.selected],trackName)
                listModel.clear()
                pygpx.get_runs(listModel)
            }
         }
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
            iconColor: Theme.palette.normal.backgroundText
            subTitle: i18n.tr("Swipe up to log a new activity")
            anchors.centerIn: parent
         }
      }
      Component.onCompleted: {
         //  listModel.clear()
         //  pygpx.get_runs(listModel)
         newrunEdge.preloadContent = true
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
               stack.push(Qt.resolvedUrl('Map.qml'), {polyline: filename, index: id})
            }

            ListItemLayout {
               ProportionalShape {
                  SlotsLayout.position: SlotsLayout.Leading
                  source: Image { source: "images/"+(act_type=="Bike Ride"?"BikeRide":act_type)+".svg" } //Legacy, old act_type was "Bike Ride" substituted with "BikeRide"
                  height: del.height-units.gu(2)
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
            }//leading
            trailingActions: ListItemActions {
              actions: [
              Action {
                 iconName: "edit"
                 onTriggered: {
                      indexrun = id;
                      print(indexrun);
                      PopupUtils.open(edit_dialog)
                 }
              },
              Action {
                 iconName: "info"
                 onTriggered: {
                      indexrun = id
                      infodis=""
                      PopupUtils.open(infogpx)
                      pygpx.info_run(id)
                 }
              }
             ]
           }//Trailing
         }//ListItem
      }
      Component {
         id: infogpx
         Dialog {
            id: infogpxdialog
            title: i18n.tr("Track information")
            text: infodis
            onTextChanged: {
               refreshIndicator.visible = false
               refreshIndicator.running = false
               refreshIndicator.focus = false
            }
            ActivityIndicator {
               id:refreshIndicator
               visible: true
               running: true
               focus: true
            }
            Button {
               text: i18n.tr("Close")
               onClicked: {
                  PopupUtils.close(infogpxdialog)
               }
            }
         }
      }

      BottomEdge {
         id:newrunEdge
         hint {
            text: i18n.tr("Log new Activity")
            iconSource: "images/runman.svg"
            status: "Active"
            flickable: thelist
         }
         onCollapseStarted: hint.status = "Active"
         onCommitCompleted: contentItem.openDialog = true
         preloadContent: false
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
