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
    property int counter;
    property var gpxx;
    property string day;
    property bool am_running;
    property string runits;
    property string timestring : "00:00"
    property string smashkey;
    property string dist;
    property string distmet: "%1 run today"
    property string bikedistmet: "%1 biked today"


    //keep screen on so we still get to read GPS
    ScreenSaver {
        id: screenSaver
        screenSaverEnabled: !Qt.application.active
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
                        result[i].distance = "Distance: "+mi.toFixed(2) + "mi"
                    }
                    else if (runits == "kilometers"){
                        result[i].distance = "Distance: "+result[i].distance + "km"
                    }
                    var seconds = parseFloat(result[i].speed) * 60
                    result[i].speed = "Time: " + stopwatch(seconds)
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
                    onClicked: {
                        stack.push(Qt.resolvedUrl('WebMap.qml'), {polyline: polyline})
                    }

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


            bottomEdgePageComponent: Page{
                title: (am_running) ? "Activity in Progress" : "New Activity"
                id:newrun
                head.backAction: Action {
                    iconName: "back"
                    onTriggered: {
                        PopupUtils.open(areyousure)
                        am_running = false
                        timer.stop()
                        console.log("Run custom back action")
                    }
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
                        title: "Are you sure?"
                        text: "Are you sure you want to cancel the activity?"
                        Button {
                            id: yesimsure
                            text: "Yes I'm sure"
                            color: UbuntuColors.green
                            onClicked: {
                                timer.start()
                                counter = 0
                                pygpx.format_timer(0)
                                timer.restart()
                                timer.stop()
                                am_running = false
                                PopupUtils.close(areyousuredialog)
                                stack.pop()
                            }
                        }
                        Button {
                            id: noooooooodb
                            text: "No"
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
                        Row {

                        Button {
                            text: "Save Activity"
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
                                pygpx.get_runs(listModel)
                                stack.pop()

                            }
                        }
                        Button {
                            text: "Cancel"
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
                                //fontSize: "large"
                            }
                            Label {
                                text: timestring
                                fontSize: "x-large"
                                //text: "00:00"
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
                                // newrun.title = "Activity in Progress"
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
                            }
                            Label {
                                id: distlabel
                                text: "0"
                                fontSize: "x-large"
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
