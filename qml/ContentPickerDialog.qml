/*
 * Copied from webbrowser app
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3 as Popups
import Ubuntu.Content 1.3

Component {
    Popups.PopupBase {
        id: picker
        property var activeTransfer
        property var selectedItems

        property color oldColor

        Rectangle {
            anchors.fill: parent

            ContentTransferHint {
                anchors.fill: parent
                activeTransfer: picker.activeTransfer
            }

            ContentPeerPicker {
                id: peerPicker
                anchors.fill: parent
                visible: true
                contentType: ContentType.All
                handler: ContentHandler.Source
                onPeerSelected: {
                    peer.contentType = "mp3"
                    peer.selectionType = ContentTransfer.Single
                    picker.activeTransfer = peer.request()
                    stateChangeConnection.target = picker.activeTransfer
                }

                onCancelPressed: {
                    mainView.backgroundColor = picker.oldColor
                    PopupUtils.close(picker)
                }
            }
        }

        Connections {
            id: stateChangeConnection
            onStateChanged: {
                if (picker.activeTransfer.state === ContentTransfer.Charged) {
                    romsModel.importFiles(String(picker.activeTransfer.items[0].url).replace("file://", ""))
                    closeTimer.start()
                }
            }
        }
        Timer {
            id: closeTimer
            interval: 10
            repeat: false
            onTriggered: {
                mainView.backgroundColor = picker.oldColor
                PopupUtils.close(picker)
            }
        }
        Component.onCompleted: {
            picker.oldColor = mainView.backgroundColor;
            mainView.backgroundColor = "white"
        }
    }
}
