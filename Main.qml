import QtQuick 2.3
import QtPositioning 5.2
import Ubuntu.Components 1.2
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.4
import QtSystemInfo 5.0
import QtLocation 5.2
import ubuntu_component_store.Curated.PageWithBottomEdge 1.0
import ubuntu_component_store.Curated.EmptyState 1.0
//import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import "./lib/polyline.js" as Pl
import "./keys.js" as Keys
import UserMetrics 0.1


/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "activitytracker.cwayne18"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    automaticOrientation: false
    // Removes the old toolbar and enables new features of the new header.
    //useDeprecatedToolbar: false

    width: units.gu(100)
    height: units.gu(75)
    property int count;
    property var gpxx;
    property string day;
    property bool am_running;
    property string runits;

    //keep screen on so we still get to read GPS
    ScreenSaver {
        id: screenSaver
        screenSaverEnabled: !Qt.application.active
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
                    console.warn(runits)
                    if (runits == "miles"){
                        console.warn(result[i].distance)
                        var mi
                        mi = result[i].distance * 0.62137
                        result[i].distance = "Distance: "+mi.toFixed(2) + "mi"
                    }
                    else if (runits == "kilometers"){
                        result[i].distance = "Distance: "+result[i].distance + "km"
                    }
                    listModel.append(result[i]);
                }

            });
        }
        function addrun(name){
            console.warn("addiing run")
            call('geepeeex.add_run', [gpxx, name], function(result){
                console.warn("run added")
            }
            )
        }//addrun
        function writeit(gpx, name,act_type){
            console.warn("Writing file")
            var b = Pl.polyline;

            //console.log("https://maps.googleapis.com/maps/api/staticmap?size=400x400&path=weight:3%7Ccolor:blue%7Cenc:"+b.encode(c,4))
            call('geepeeex.write_gpx', [gpxx,name,act_type]

                 )
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


    }//Python

    Component {
        id: pageComponent


        PageWithBottomEdge {
            id: page1
            visible: true
            title: i18n.tr("Recent Activities")
            bottomEdgeTitle: "Log new Activity"
            head.actions: [Action {
                    text: "Second action"
                    iconName: "settings"
                    onTriggered: pageStack.push(Qt.resolvedUrl("./Settings.qml"))
                    
                    // override the text of the action:
                    //text: "action 2"
                }
            ]

            

            Rectangle {
                visible : if(thelist.model.count > 0) false;else true;
                id: rekt
                anchors.fill:parent
                color: "transparent"
                EmptyState {
                    iconName: "alarm-clock"
                    title: i18n.tr("No saved activities")
                    iconSource: Qt.resolvedUrl("./images/runman.png")
                    subTitle: i18n.tr("Swipe up to log a new activity")
                    anchors.centerIn: parent
                }
            }
            Component.onCompleted: {
                //  listModel.clear()
                //  pygpx.get_runs(listModel)
            }

            UbuntuListView {
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
                    Row {
                        spacing: units.gu(1)
                        Item{
                            id: blank
                            width: units.gu(.1)
                            height: parent.height

                        }
                        Image {
                            source: "images/"+act_type+".png"
                            height: del.height-units.gu(2)
                            width: height
                            anchors.topMargin: units.gu(1)
                            anchors.top: parent.top

                        }
                        Column {
                            anchors.topMargin: units.gu(1)
                            anchors.top: parent.top
                            Label{
                                text: name


                            }
                            Row {
                                spacing: units.gu(1)
                                Label {
                                    text: speed
                                }
                                Label {
                                    text: distance
                                }
                            }
                        }
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    print("=====================================" + id)
                                    pygpx.rm_run(id)
                                    listModel.remove(index)
                                    //listModel.clear()
                                    //pygpx.get_runs()
                                }
                            }
                        ]
                    }
                }
            }


            bottomEdgePageComponent: Page{
                title: "New Activity"
                id:newrun

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

                        if (gpxx){

                            if (src.position.latitudeValid && src.position.longitudeValid && src.position.altitudeValid) {
                                pygpx.addpoint(gpxx,coord.latitude,coord.longitude,coord.altitude)
                                pline.addCoordinate(QtPositioning.coordinate(coord.latitude,coord.longitude, coord.altitude))
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
                        preferred: ["mapbox", "nokia", "osm"]
                        required.mapping: Plugin.AnyMappingFeatures
                        required.geocoding: Plugin.AnyGeocodingFeatures
                        parameters: [
                            PluginParameter { name: "app_id"; value: Keys.here_appid },
                            PluginParameter { name: "token"; value: Keys.here_token },
                            PluginParameter { name: "mapbox.access_token"; value: Keys.mb_pk },
                            PluginParameter { name: "mapbox.map_id"; value: Keys.mp_mid }
                        ]
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
                        title: "Save Activity"
                        text: ""

                        OptionSelector {
                            id: os
                            text: i18n.tr("Activity Type")
                            model: [i18n.tr("Run"),
                                i18n.tr("Bike Ride"),
                                i18n.tr("Walk"),
                                i18n.tr("Hike")]
                        }
                        Label {
                            text: "Name"
                        }

                        TextField {
                            text: os.model[os.selectedIndex] + " " + day
                            id: tf
                            Component.onCompleted: {
                                var d = new Date();
                                day = d.toDateString();
                            }
                        }

                        Button {
                            text: "Save Activity"
                            color: UbuntuColors.green
                            onClicked: {

                                PopupUtils.close(dialogue)
                                pygpx.writeit(gpxx,tf.displayText,os.model[os.selectedIndex])
                                console.log(tf.displayText)
                                //  listModel.append({"name": tf.displayText, "act_type": os.model[os.selectedIndex]})
                                //   pygpx.addrun(tf.displayText)
                                listModel.clear()
                                pygpx.get_runs(listModel)
                                stack.pop()
                            }
                        }
                        Button {
                            text: "Cancel"
                            color: UbuntuColors.red
                            onClicked: PopupUtils.close(dialogue)
                        }
                    }
                }//Dialog component

                Item {
                    width: parent.width

                    height: units.gu(10)
                    // z:100
                    anchors.bottom: parent.bottom
                    Column{
                        anchors.horizontalCenter: parent.horizontalCenter
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
                                newrun.title = "Activity in Progress"

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
                                PopupUtils.open(dialog)

                            }
                        }
                    }
                }//Item (buttons)









            }//Bottom component page

        }//Page
    }//Page component
    PageStack {
        id: stack
        Component.onCompleted: {
            am_running = false
            stack.push(pageComponent)
        }
    }
}
