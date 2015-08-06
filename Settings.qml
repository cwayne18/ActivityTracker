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



Page {
    title: "Units"
    id:settings
    ListItem.ItemSelector {
            text: i18n.tr("Units")
            model: [i18n.tr("Kilometers"),
                    i18n.tr("Miles")]
            selectedIndex: switch(userSettings.contents["units"]) {
                           case "kilometers": return 0;
                           case "miles": return 1;
                           }
            onDelegateClicked: {
                userSettings.set("units", model[index])
            }
        }
}
