import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

ColumnLayout {
    id: root
    required property string elemName
    required property var elemSchema
    property int elemValue

    Repeater {
        model: elemSchema.choices

        RadioButton {
            required property int index
            required property string modelData
            text: modelData
            checked: root.elemValue === index
            onCheckedChanged: if(checked) root.elemValue = index
        }
    }
}
