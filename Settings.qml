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
import Ubuntu.OnlineAccounts.Client 0.1
import Ubuntu.OnlineAccounts 0.1
import "./lib/polyline.js" as Pl
import "./keys.js" as Keys



Page {
    title: "Settings"
    id:settings
    AccountServiceModel {
        id: accounts
        applicationId: "activitytracker.cwayne18_activitytracker"
    }
    Setup {
        id: setup
        applicationId: accounts.applicationId
        providerId: "activitytracker.cwayne18_smashrunaccount"
    }
    AccountService {
        id: accountService
        onAuthenticated: {
            console.log('aa' + JSON.stringify(reply, null, 4));
            smashkey = reply.AccessToken
            console.log(smashkey)
        }
    }
    ListItem.ItemSelector {
        text: i18n.tr("Units")
        model: [i18n.tr("Kilometers"),
            i18n.tr("Miles")]
        selectedIndex: switch(runits) {
                       case "kilometers": return 0;
                       case "miles": return 1;
                       }
        onSelectedIndexChanged: {
            console.warn(model[selectedIndex].toLowerCase())
            runits=model[selectedIndex].toLowerCase()
            pygpx.set_units(model[selectedIndex].toLowerCase())
        }
    }
    Component.onCompleted: {

        if (accounts.count == 1) {

            print("THERE ARE IS ONE");
            print(accounts.get(0, "displayName"))   ;
            print(JSON.stringify(accounts, null, 4));
            accountService.objectHandle = accounts.get(0, "accountServiceHandle")
            accountService.authenticate();

        }

    }
}
