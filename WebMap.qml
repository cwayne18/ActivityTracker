import QtQuick 2.4
import QtPositioning 5.3
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
import QtSystemInfo 5.0
import QtLocation 5.3
import ubuntu_component_store.Curated.PageWithBottomEdge 1.0
import ubuntu_component_store.Curated.EmptyState 1.0
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import "./lib/polyline.js" as Pl
import Ubuntu.Web 0.2



Page {
   header: PageHeader {
      title: i18n.tr("Activity Map")
   }
   property var polyline;
   id: map
   WebView {
      id: webView
      url: "html/map.html?polyline="+polyline
      anchors.fill: parent
   }
}
