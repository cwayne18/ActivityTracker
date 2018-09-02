import Ubuntu.Components 1.3

Button {
   property string texth
   property alias textSize: label.textSize
   property alias textColor: label.color
   height: units.gu(10)
   Label {
      id: label
      text: parent.texth
      // textSize: Label.Medium
      font.pointSize: units.dp(12)
      anchors.centerIn: parent
      color: "white"
   }
}
