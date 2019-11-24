import QtQuick 2.4
import QtPositioning 5.9
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
import QtSystemInfo 5.0
import QtLocation 5.9
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Morph.Web 0.1



Page {
   header: PageHeader {
      id: map_header
      title: i18n.tr("Activity Map")
      trailingActionBar.actions: [
         Action {
            text: i18n.tr("Info")
            iconName: "info"
            onTriggered: {
                 indexrun = index
                 infodis=""
                 PopupUtils.open(infogpx)
                 pygpx.info_run(index)
            }
         }
      ]
   }
   id: mainPage
   property var polyline
   property var index

   ActivityIndicator {
       id:refreshmap
       anchors.centerIn: parent
       z: 5
   }

   Python {
      id: pygpxmap
      Component.onCompleted: {

         addImportPath(Qt.resolvedUrl('py/'));
         importModule("geepeeex", function() {
            console.warn("calling python script to load the gpx file")
            refreshmap.visible = true
            refreshmap.running = true
            refreshmap.focus = true
            pygpxmap.call("geepeeex.visu_gpx", [polyline], function(result) {
               var t = new Array (0)
               for (var i=0; i<result.length; i++) {
                  pline.addCoordinate(QtPositioning.coordinate(result[i].latitude,result[i].longitude));
               }
               map.center = QtPositioning.coordinate(result[(i/2).toFixed(0)].latitude,result[(i/2).toFixed(0)].longitude); // Center the map on the enter of the track
               refreshmap.visible = false
               refreshmap.running = false
               refreshmap.focus = false
            });
         });
      }//Component.onCompleted
   }
   Plugin {
      id: mapPlugin
      name: "osm"
   }
   Map {
      id: map
      anchors.fill: parent
      center: QtPositioning.coordinate(29.62289936, -95.64410114) // Oslo
      zoomLevel: map.maximumZoomLevel - 5
      color: Theme.palette.normal.background
      plugin : Plugin {
         id: plugin
         allowExperimental: true
         preferred: ["osm"]
         required.mapping: Plugin.AnyMappingFeatures
         required.geocoding: Plugin.AnyGeocodingFeatures
      }

      MapPolyline {
         id: pline
         line.width: 4
         line.color: 'red'
         path: []
      }
   }

}
