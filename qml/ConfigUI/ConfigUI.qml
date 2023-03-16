import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Window 2.15
import QtQml 2.15
import CoppeliaSimPlugin 1.0

PluginWindow {
    id: mainWindow
    width: topLayout.implicitWidth
    height: topLayout.implicitHeight
    visible: true
    flags: Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint
    title: qsTr("ConfigUI")
    color: systemPalette.window

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    onClosing: simBridge.sendEvent('ConfigUI_uiClosing',{})

    property var config: ({})
    property var schema: ({})
    property var schemaSorted: {
        var ss = []
        for(var elemName in schema) {
            var elemSchema = schema[elemName]
            var ui = elemSchema.ui || {}
            var tab = ui.tab || "Main"
            var group = ui.group || 0
            var col = ui.col || 0
            var order = ui.order || 0
            ss.push([tab, group, col, order, elemName, elemSchema])
        }
        ss.sort()
        return ss
    }

    signal updateConfig(newConfig: var)

    function setConfig(c) {
        config = c
        updateConfig(c)
    }

    function setSchema(s) {
        schema = s
    }

    function setConfigAndSchema(o) {
        setConfig(o.config)
        setSchema(o.schema)
    }

    function tabs() {
        var s = new Set()
        for(var o of schemaSorted)
            s.add(o[0])
        return Array.from(s)
    }

    function groups(tab) {
        var s = new Set()
        for(var o of schemaSorted)
            if(o[0] === tab)
                s.add(o[1])
        return Array.from(s)
    }

    function cols(tab, group) {
        var s = new Set()
        for(var o of schemaSorted)
            if(o[0] === tab && o[1] === group)
                s.add(o[2])
        return Array.from(s)
    }

    function elems(tab, group, col) {
        var s = []
        for(var o of schemaSorted)
            if(o[0] === tab && o[1] === group && o[2] === col)
                s.push([o[4], o[5]])
        return s
    }

    property string selectedTab: "Main"

    ColumnLayout {
        id: topLayout

        TabBar {
            id: tabBar
            width: mainWindow.width
            visible: tabButtonsRepeater.model.length > 1
            Repeater {
                id: tabButtonsRepeater
                model: tabs()
                TabButton {
                    text: modelData
                    onClicked: mainWindow.selectedTab = modelData
                    width: implicitWidth
                }
            }
        }

        Rectangle {
            id: topRect
            implicitWidth: groupsLayout.implicitWidth + 10
            implicitHeight: groupsLayout.implicitHeight + 10
            color: systemPalette.window

            ColumnLayout {
                id: groupsLayout
                spacing: 5
                anchors.centerIn: parent

                Repeater {
                    id: tabsRepeater
                    model: tabs()

                    Repeater {
                        id: groupsRepeater
                        required property string modelData
                        readonly property string tab: modelData
                        model: groups(tab)

                        Rectangle {
                            visible: mainWindow.selectedTab === groupsRepeater.tab
                            required property var modelData
                            Layout.margins: 0
                            Layout.fillWidth: true
                            implicitWidth: paddingItem.implicitWidth
                            implicitHeight: paddingItem.implicitHeight
                            color: Qt.rgba(0, 0, 0, 0.04)
                            radius: 10

                            Item {
                                id: paddingItem
                                implicitWidth: colsLayout.implicitWidth + 10
                                implicitHeight: colsLayout.implicitHeight + 10
                            }

                            RowLayout {
                                id: colsLayout
                                spacing: 5
                                anchors.centerIn: parent

                                Repeater {
                                    id: colsRepeater
                                    readonly property string tab: groupsRepeater.tab
                                    readonly property int group: modelData
                                    model: cols(tab, group)

                                    Rectangle {
                                        required property var modelData
                                        Layout.margins: 0
                                        Layout.fillHeight: true
                                        implicitWidth: elemsLayout.implicitWidth
                                        implicitHeight: elemsLayout.implicitHeight
                                        color: 'transparent'

                                        ColumnLayout {
                                            id: elemsLayout
                                            spacing: 5
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            Repeater {
                                                id: elemsRepeater
                                                readonly property string tab: colsRepeater.tab
                                                readonly property int group: colsRepeater.group
                                                readonly property int col: modelData
                                                model: elems(tab, group, col)

                                                ColumnLayout {
                                                    id: elemLayout
                                                    Layout.margins: 0
                                                    required property var modelData
                                                    readonly property string tab: elemsRepeater.tab || 'Main'
                                                    readonly property int group: elemsRepeater.group || 0
                                                    readonly property int col: elemsRepeater.col || 0
                                                    readonly property var elemSchema: modelData[1]
                                                    readonly property string elemName: elemSchema.key || modelData[0]
                                                    readonly property int order: elemSchema.ui.order || 0

                                                    Label {
                                                        visible: elemSchema.ui.control !== 'checkbox'
                                                        text: `${elemSchema.name || elemName}:`
                                                    }

                                                    Loader {
                                                        id: loader
                                                    }

                                                    Connections {
                                                        id: uiChangedConnection
                                                        target: loader.item
                                                        function onElemValueChanged() {
                                                            mainWindow.config[loader.item.elemName] = loader.item.elemValue
                                                            simBridge.sendEvent('ConfigUI_uiChanged',mainWindow.config)
                                                        }
                                                    }

                                                    Connections {
                                                        id: updateConfigConnection
                                                        target: mainWindow
                                                        function onUpdateConfig(c) {
                                                            uiChangedConnection.enabled = false
                                                            var v = c[loader.item.elemName]
                                                            loader.item.elemValue = v
                                                            mainWindow.config[loader.item.elemName] = v
                                                            uiChangedConnection.enabled = true
                                                        }
                                                    }

                                                    Component.onCompleted: {
                                                        loader.setSource(`Control_${elemSchema.ui.control || 'dummy'}.qml`, {
                                                            elemName: elemLayout.elemName,
                                                            elemSchema: elemLayout.elemSchema,
                                                            elemValue: config[elemName],
                                                        })
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
