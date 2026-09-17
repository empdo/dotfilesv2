pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string min 
    property string hour
    property string month 
    property string day

    Process {
        id: dateProc
        command: ["date"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                // Example output: "Fri Nov  7 03:09:49 PM CET 2025"
                let parts = this.text.trim().split(/\s+/); // -> ["Fri","Nov","7","03:09:49","PM","CET","2025"]

                if (parts.length >= 7) {
                    let month = parts[1];
                    let day = parts[2];
                    let time = parts[3];
                    let timeSplit = time.split(/:/);
                    let ampm = parts[4];

                    root.hour = timeSplit[0];
                    root.min = timeSplit[1];
                    root.month = `${month}`;
                    root.day = `${day}`;
                } else {
                    root.min = this.text.trim();
                    root.hour = this.text.trim();
                    root.month = this.text.trim();
                    root.day = this.text.trim();
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}
