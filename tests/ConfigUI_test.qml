import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Window 2.15
import QtQml 2.15

Window {
    id: mainWindow
    width: configUi.implicitWidth
    height: configUi.implicitHeight
    visible: true
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMaximizeButtonHint | Qt.MSWindowsFixedSizeDialogHint | Qt.CustomizeWindowHint
    title: qsTr("ConfigUI")
    color: systemPalette.window

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    ConfigUI {
        id: configUi
        simBridge: simBridge_mock
    }

    QtObject {
        id: simBridge_mock

        function sendEvent(name, data) {
            console.log(`ConfigUI_test: received event "${name}" with data: ${JSON.stringify(data)}`)
        }
    }

    Component.onCompleted: configUi.setConfigAndSchema({
        schema: {
            string1: {
                name: 'String value',
                type: 'string',
                ui: {control: 'edit', group: 0,},
            },
            float1: {
                name: 'Bounded float',
                type: 'float',
                minimum: 0.001,
                maximum: 1,
                ui: {control: 'slider', group: 0,},
            },
            float2: {
                name: 'Unbounded float',
                type: 'float',
                decimals: 3,
                step: 0.025,
                ui: {control: 'spinbox', group: 0, col: 1,},
            },
            int1: {
                name: 'Int',
                type: 'float',
                decimals: 0,
                minimum: 0,
                maximum: 100,
                step: 2,
                ui: {control: 'spinbox', group: 0, col: 1,},
            },
            checkbox1: {
                name: 'Checkbox',
                type: 'bool',
                ui: {control: 'checkbox', group: 0,},
            },
            color1: {
                name: 'Color',
                type: 'color',
                ui: {control: 'color', group: 1,},
            },
            button1: {
                name: 'Button action',
                type: 'callback',
                callback: 'buttonClicked',
                ui: {control: 'button', group: 1, col: 1,},
            },
            combo1: {
                name: 'Combo selection',
                choices: ['foo', 'bar', 'baz',],
                labels: ['Fried Foo', 'Broiled Bar', 'Boiled Baz'],
                ui: {control: 'combo', group: 2,},
            },
            radio1: {
                name: 'Radio group',
                type: 'choices',
                choices: ['x', 'y', 'z'],
                ui: {control: 'radio', group: 2, col: 1,},
            },
                                  foo: {ui: {tab: "Other",}},
        },
        config: {
            combo1: 'bar',
            color1: [0.85, 0.85, 1],
            float1: 0.5,
            float2: 0.005,
            int1: 42,
            button1: 'foo',
            checkbox1: true,
            string1: 'bar',
            radio1: 'y',
        }
    })
}
