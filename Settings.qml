pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Widgets

// Settings panel for SPlayer Lyrics.
// Loaded in two contexts:
//   1. Desktop widget instance card (PluginDesktopWidgetSettings) - injects instanceId/instanceData/pluginService
//   2. Plugin manager page (PluginListItem) - injects only pluginService
// Follows the builtin DesktopClock/SystemMonitor settings pattern: sliders/toggles write config immediately.

Column {
    id: root

    property string instanceId: ""
    property var instanceData: null
    property var pluginService: null

    readonly property var cfg: instanceData?.config ?? {}
    readonly property bool isInstance: instanceId !== "" && instanceData !== null

    function loadValue(key, defaultValue) {
        if (isInstance) {
            return (key in cfg) ? cfg[key] : defaultValue;
        }
        if (pluginService && pluginService.loadPluginData)
            return pluginService.loadPluginData("splayerDesktopLyrics", key, defaultValue);
        return SettingsData.getPluginSetting("splayerDesktopLyrics", key, defaultValue);
    }

    function saveValue(key, value) {
        if (isInstance) {
            var updates = {};
            updates[key] = value;
            SettingsData.updateDesktopWidgetInstanceConfig(instanceId, updates);
        } else if (pluginService && pluginService.savePluginData) {
            pluginService.savePluginData("splayerDesktopLyrics", key, value);
        } else {
            SettingsData.setPluginSetting("splayerDesktopLyrics", key, value);
        }
    }

    width: parent?.width ?? 400
    spacing: 0

    SettingsSliderRow {
        text: I18n.tr("Transparency")
        description: I18n.tr("Controls opacity of the widget background")
        minimum: 0
        maximum: 100
        value: Math.round((root.cfg.transparency ?? 0.8) * 100)
        unit: "%"
        defaultValue: 80
        onSliderValueChanged: newValue => root.saveValue("transparency", newValue / 100)
    }

    SettingsDivider {}

    SettingsSliderRow {
        text: I18n.tr("Lyric Font Size")
        description: I18n.tr("Font size of the lyric text")
        minimum: 10
        maximum: 24
        step: 1
        value: root.cfg.lyricFontSize ?? 15
        unit: "px"
        defaultValue: 15
        onSliderValueChanged: newValue => root.saveValue("lyricFontSize", newValue)
    }

    SettingsDivider {}

    SettingsToggleRow {
        text: I18n.tr("Show Song Title")
        description: I18n.tr("Display the current track title and artist at the top of the widget")
        checked: root.cfg.showTitle ?? true
        onToggled: checked => root.saveValue("showTitle", checked)
    }

    SettingsDivider {}

    Item {
        width: parent.width
        height: resetRow.height + Theme.spacingM * 2
        visible: root.isInstance

        Row {
            id: resetRow
            x: Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingM

            DankButton {
                text: I18n.tr("Reset Position")
                backgroundColor: Theme.surfaceHover
                textColor: Theme.surfaceText
                buttonHeight: 36
                onClicked: {
                    if (!root.instanceId)
                        return;
                    SettingsData.updateDesktopWidgetInstance(root.instanceId, {
                        positions: {}
                    });
                }
            }

            DankButton {
                text: I18n.tr("Reset Size")
                backgroundColor: Theme.surfaceHover
                textColor: Theme.surfaceText
                buttonHeight: 36
                onClicked: {
                    if (!root.instanceId)
                        return;
                    SettingsData.updateDesktopWidgetInstance(root.instanceId, {
                        positions: {}
                    });
                }
            }
        }
    }
}
