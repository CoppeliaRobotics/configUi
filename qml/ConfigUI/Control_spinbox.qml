import QtQuick 2.15
import QtQuick.Controls 2.15

SpinBox {
    id: root
    required property string elemName
    required property var elemSchema
    property real elemValue

    readonly property int decimals: {
        if(elemSchema.type === 'int')
            return 0
        if(elemSchema.decimals !== undefined)
            return elemSchema.decimals
        else
            return 3
    }
    readonly property int k: Math.pow(10, Math.max(0, Math.round(decimals)))
    readonly property real realValue: value / k

    from: {
        if(elemSchema.minimum !== undefined)
            return k * elemSchema.minimum
        else
            return -2147483648
    }
    to: {
        if(elemSchema.maximum !== undefined)
            return k * elemSchema.maximum
        else
            return 2147483647
    }
    stepSize: {
        if(elemSchema.step !== undefined)
            return Math.max(1, Math.round(elemSchema.step * k))
        else
            return 1
    }

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

    Component.onCompleted: value = k * elemValue
    onRealValueChanged: elemValue = realValue
}
