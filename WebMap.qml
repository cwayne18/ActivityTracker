import QtQuick 2.3
import QtPositioning 5.2
import Ubuntu.Components 1.1
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.4
import QtSystemInfo 5.0
import QtLocation 5.2
import ubuntu_component_store.Curated.PageWithBottomEdge 1.0
import ubuntu_component_store.Curated.EmptyState 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import "./lib/polyline.js" as Pl
import "./keys.js" as Keys
import Ubuntu.Web 0.2



Page {
    title: "Activity Map"
    property var polyline;
    id:map
    WebView {
        id: webView
        url: "html/map.html?polyline="+polyline
        anchors.fill: parent

    }

}

