import QtQuick 2.15
import QtQuick.Controls 2.15

SpinBox {
    id: root
    required property string elemName
    required property var elemSchema
    property real elemValue

    readonly property int decimals: elemSchema.decimals || 0
    readonly property int k: Math.pow(10, Math.max(0, Math.round(decimals)))
    readonly property real realValue: value / k

    from: k * (elemSchema.minimum || 0)
    value: k * elemValue
    to: k * (elemSchema.maximum || 1)
    stepSize: elemSchema.step ? Math.max(1, Math.round(elemSchema.step * k)) : 1

    validator: DoubleValidator {
        bottom: Math.min(root.from, root.to)
        top: Math.max(root.from, root.to)
    }

    textFromValue: function(value, locale) {
        return Number(value / root.k).toLocaleString(locale, 'f', root.decimals)
    }

    valueFromText: function(text, locale) {
        return Number.fromLocaleString(locale, text) * root.k
    }

    onRealValueChanged: elemValue = realValue
}
