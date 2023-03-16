import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: root
    required property string elemName
    required property var elemSchema
    property int elemValue

    model: elemSchema.choices
    currentIndex: elemValue
    onCurrentIndexChanged: elemValue = currentIndex
}
