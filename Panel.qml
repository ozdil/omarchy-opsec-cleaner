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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰈤 OpSec"
    slotSize: Style.bar.statusSlot
    tooltipText: "OpSec Cleaner: Privacy metadata & EXIF sanitizer"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    width: 420
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight)

    Column {
      id: mainCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(12)

      Text {
        text: "🔒 OpSec Metadata Cleaner"
        font.pixelSize: Style.font.title
        font.bold: true
        color: root.bar ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: "Fotoğraf ve belgelerinizdeki GPS, kamera ve kullanıcı dijital izlerini temizleyin."
        font.pixelSize: Style.font.body
        color: "#94a3b8"
        wrapMode: Text.WordWrap
        width: parent.width
      }

      Button {
        width: parent.width
        text: "📁 Dosya Seç ve Temizle"
        onClicked: {
          root.close()
          if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation $HOME/.config/omarchy/plugins/opsec-cleaner/cleaner-dashboard")
        }
      }
    }
  }
}
