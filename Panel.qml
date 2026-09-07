import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "ozdil.opsec-cleaner"
  ipcTarget: "ozdil.opsec-cleaner"
  manageIpc: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string barText: "OPSEC: READY"
  property int totalCleaned: 0
  property var history: []
  property string lastStatusMsg: "Ready to scrub metadata"

  function resolveEnginePath() {
    return Qt.resolvedUrl("opsec-engine").toString().replace(/^file:\/\//, "")
  }

  function refresh() {
    if (!stateProc.running) {
      stateProc.running = true
    }
  }

  function cleanDownloads() {
    cleanProc.command = ["bash", "-c", "for f in ~/Downloads/*.{jpg,jpeg,png}; do [[ -f \"$f\" ]] && \"" + root.resolveEnginePath() + "\" --clean \"$f\"; done"]
    cleanProc.running = true
  }

  IpcHandler {
    target: "ozdil.opsec-cleaner"
    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.toggle() }
    function refresh() { root.refresh() }
  }

  Process {
    id: stateProc
    command: [root.resolveEnginePath(), "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var clean = String(text || "").slice(0, 65536)
          var d = JSON.parse(clean)
          root.totalCleaned = Number(d.total_cleaned) || 0
          root.history = d.history || []
          root.barText = "OPSEC: READY (" + root.totalCleaned + ")"
        } catch(e) {
          root.barText = "OPSEC: READY"
        }
      }
    }
  }

  Process {
    id: cleanProc
    onExited: function(code) {
      root.lastStatusMsg = "Downloads cleaned successfully."
      root.refresh()
    }
  }

  Component.onCompleted: refresh()
  Component.onDestruction: {
    if (stateProc.running) stateProc.kill()
    if (cleanProc.running) cleanProc.kill()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    tooltipText: "OpSec Cleaner - Metadata Scrubber\nStatus: READY\nCleaned: " + root.totalCleaned

    onPressed: function(b) {
      if (root.opened) root.close()
      else root.open()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(480))
    contentHeight: panel.fittedContentHeight(contentCol.implicitHeight)

    Column {
      id: contentCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(12)

      // ---------- Header ----------
      Item {
        width: parent.width
        implicitHeight: Math.max(heroLabels.implicitHeight, heroActions.implicitHeight)

        Column {
          id: heroLabels
          anchors.left: parent.left
          anchors.right: heroActions.left
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            textFormat: Text.PlainText
            text: "OPSEC CLEANER"
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            text: "DIGITAL PRIVACY & METADATA SCRUBBER"
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }
        }

        RowLayout {
          id: heroActions
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)

          Button {
            text: "Scrub Downloads"
            onClicked: root.cleanDownloads()
          }

          Button {
            text: "Refresh"
            onClicked: root.refresh()
          }
        }
      }

      PanelSeparator {
        foreground: root.bar ? root.bar.foreground : Color.foreground
      }

      // ---------- Telemetry Grid ----------
      Column {
        width: parent.width
        spacing: Style.spacing.labelGap

        GridLayout {
          width: parent.width
          columns: 4
          columnSpacing: Style.space(16)
          rowSpacing: Style.spacing.labelGap

          InfoLabel { text: "Engine" }
          DetailValue { text: "Native Rust (x86_64)" }

          InfoLabel { text: "Cleaned Total" }
          DetailValue { text: String(root.totalCleaned) }

          InfoLabel { text: "Method" }
          DetailValue { text: "Lossless Chunk Strip" }

          InfoLabel { text: "Supported" }
          DetailValue { text: "JPEG, PNG, EXIF" }
        }
      }

      PanelSeparator {
        foreground: root.bar ? root.bar.foreground : Color.foreground
      }

      // ---------- History Table ----------
      Column {
        width: parent.width
        spacing: Style.space(6)

        PanelSectionHeader {
          text: "RECENTLY SCRUBBED FILES"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        }

        Text {
          visible: root.history.length === 0
          textFormat: Text.PlainText
          text: "No scrubbed files recorded yet. Click 'Scrub Downloads' to sanitize image metadata."
          color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Column {
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: Math.min(root.history.length, 5)
            delegate: Item {
              width: parent.width
              height: Style.space(22)

              readonly property var itemData: root.history[index]

              RowLayout {
                anchors.fill: parent
                spacing: Style.space(8)

                Text {
                  textFormat: Text.PlainText
                  Layout.preferredWidth: Style.space(200)
                  text: itemData ? String(itemData.file_name) : "--"
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                }

                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: itemData ? ("Saved: " + Math.max(0, (itemData.original_size - itemData.cleaned_size)) + " bytes") : "--"
                  color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.3)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }
    }
  }
}
