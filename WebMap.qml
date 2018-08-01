import QtQuick 2.4
import QtPositioning 5.6
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
import QtSystemInfo 5.0
import QtLocation 5.6
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import "./lib/polyline.js" as Pl
import Ubuntu.Web 0.2



Page {
   header: PageHeader {
      id: webmap_header
      title: i18n.tr("Activity Map")
   }
   id: mainPage
   property var polyline;

   Python {
      id: pygpx
      Component.onCompleted: {
         addImportPath(Qt.resolvedUrl('py/'));
         importModule("geepeeex", function() {
            console.warn("call python script")
            pygpx.call("geepeeex.visu_gpx", [polyline], function(result) {
               console.warn("loading gpx file")
               var t = new Array (0)
               map.center = QtPositioning.coordinate(result[1].latitude,result[1].longitude);
               for (var i=0; i<result.length; i++) {
                  //gpxmodel.append(result[i]);
                  //gpxtrack.push ("{ latitude: " + result[i].latitude + ", longitude: " + result[i].longitude + " },");
                  pline.addCoordinate(QtPositioning.coordinate(result[i].latitude,result[i].longitude));
                  //console.log("==========================");
                  //console.log(gpxtrack[i]);
                  //console.log(result[i].longitude);
                  //console.log("==========================");
               }
               console.log("fin du script");
            });
         });
      }//Component.onCompleted
      //path : gpxtrack;
   }

   /*ListView {
      id: whattheproblem
      whattheproblem.model:
      id: gpxmodel
      whattheproblem.delegate: Component {
         Text {
            latitude: gpxmodel.latitude
            longitude: gpxmodel.longitude
         }
      }
   }*/


   Plugin {
      id: mapPlugin
      name: "osm"
   }
   Map {
      id: map
      anchors.fill: parent
      center: QtPositioning.coordinate(29.62289936, -95.64410114) // Oslo
      zoomLevel: map.maximumZoomLevel - 8
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
