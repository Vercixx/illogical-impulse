pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"

    property bool active: false
    property bool restartDialogOpen: false
    property list<string> panels: []

    function load() {
        firstRunFileView.reload();
    }

    function shows(panel) {
        return !root.active || root.panels.includes(panel);
    }

    function restart() {
        root.restartDialogOpen = false;
        root.panels = [];
        root.active = true;
    }

    function finish() {
        firstRunFileView.setText(root.firstRunFileContent);
        root.active = false;
        root.panels = [];
    }

    FileView {
        id: firstRunFileView
        path: Qt.resolvedUrl(root.firstRunFilePath)
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.active = true;
        }
    }
}
