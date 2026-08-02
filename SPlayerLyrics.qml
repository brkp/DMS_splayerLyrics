import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    widgetWidth: 420
    widgetHeight: 260
    minWidth: 280
    minHeight: 140

    // ---------------- settings (pluginData / instance config) ----------------
    // transparency is the canonical key (matches builtin widgets); bgOpacity kept as legacy fallback
    property real bgOpacity: pluginData.transparency ?? pluginData.bgOpacity ?? 0.8
    property int lyricFontSize: pluginData.lyricFontSize ?? 15
    property bool showTitle: pluginData.showTitle ?? true
    property string apiBase: pluginData.apiBase ?? "http://127.0.0.1:25884"

    // ---------------- MPRIS state ----------------
    readonly property MprisPlayer player: MprisController.activePlayer

    property string trackId: player && player.metadata && player.metadata["mpris:trackid"]
                             ? String(player.metadata["mpris:trackid"]) : ""
    property string trackTitle: player ? (player.trackTitle || "") : ""
    property string trackArtist: player ? (player.trackArtist || "") : ""
    property bool playing: player ? player.isPlaying : false

    // ---------------- lyrics state ----------------
    property var lyricsLines: []
    property int currentLineIndex: -1
    property string statusText: "等待播放器…"
    property string _lastFetchedTrackId: ""

    readonly property color bgColor: Theme.withAlpha(Theme.surface, root.bgOpacity)
    readonly property color textColor: Theme.surfaceText
    readonly property color dimColor: Theme.surfaceVariantText
    readonly property color accentColor: Theme.primary

    // ---------------- helpers ----------------
    function trackIdToNumeric(idStr) {
        if (!idStr) return "";
        var m = idStr.match(/(\d+)/);
        return m ? m[1] : "";
    }

    function parseLrc(lrcText) {
        if (!lrcText) return [];
        var timeRegex = /\[(\d{2}):(\d{2})\.(\d{2,3})\]/;
        var result = lrcText.split("\n").reduce(function (acc, rawLine) {
            var line = rawLine.trim();
            if (!line) return acc;
            var match = timeRegex.exec(line);
            if (!match) return acc;
            var millis = parseInt(match[3]);
            if (match[3].length === 2) millis *= 10;
            acc.push({
                time: parseInt(match[1]) * 60 + parseInt(match[2]) + millis / 1000,
                text: line.replace(/\[\d{2}:\d{2}\.\d{2,3}\]/g, "").trim()
            });
            return acc;
        }, []);
        result.sort(function (a, b) { return a.time - b.time; });
        return result;
    }

    function fetchLyrics() {
        var id = root.trackIdToNumeric(root.trackId);
        if (!id) {
            root.lyricsLines = [];
            root.currentLineIndex = -1;
            root.statusText = "未获取到歌曲 ID";
            return;
        }
        if (id === root._lastFetchedTrackId) return;

        root._lastFetchedTrackId = id;
        root.lyricsLines = [];
        root.currentLineIndex = -1;
        root.statusText = "加载歌词…";

        var url = root.apiBase + "/api/netease/lyric?id=" + id;
        Proc.runCommand("splayerLyrics.fetchLyrics", ["curl", "-s", "-m", "3", url], function (stdout, exitCode) {
            if (exitCode === 0 && stdout) {
                try {
                    var obj = JSON.parse(stdout);
                    var lyric = obj && obj.lrc && obj.lrc.lyric ? obj.lrc.lyric : "";
                    if (lyric) {
                        root.lyricsLines = root.parseLrc(lyric);
                        root.statusText = root.lyricsLines.length > 0
                            ? "已加载 " + root.lyricsLines.length + " 行歌词"
                            : "歌词为空";
                    } else {
                        root.statusText = "未找到歌词";
                    }
                } catch (e) {
                    root.statusText = "歌词解析失败";
                }
            } else {
                root.statusText = "歌词接口错误 (" + exitCode + ")";
            }
        }, 100);
    }

    // ---------------- track change ----------------
    onTrackIdChanged: {
        if (root.trackId) {
            root.fetchLyrics();
        }
    }

    Component.onCompleted: {
        if (root.trackId) {
            root.fetchLyrics();
        } else {
            root.statusText = "等待 SPlayer…";
        }
    }

    // ---------------- position timer ----------------
    Timer {
        id: positionTimer
        interval: 200
        running: root.playing && root.lyricsLines.length > 0
        repeat: true
        onTriggered: {
            var pos = root.player ? (root.player.position || 0) : 0;
            var newIndex = -1;
            for (var i = root.lyricsLines.length - 1; i >= 0; i--) {
                if (pos >= root.lyricsLines[i].time) {
                    newIndex = i;
                    break;
                }
            }
            if (newIndex !== root.currentLineIndex) {
                root.currentLineIndex = newIndex;
                if (newIndex >= 0) {
                    lyricsView.positionViewAtIndex(newIndex, ListView.Center);
                }
            }
        }
    }

    // ---------------- UI ----------------
    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: root.bgColor
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            // header: title + artist + status
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(titleRow.implicitHeight, 20)

                RowLayout {
                    id: titleRow
                    anchors.fill: parent
                    spacing: Theme.spacingXS
                    visible: root.showTitle

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.trackTitle ? (root.trackTitle + (root.trackArtist ? " - " + root.trackArtist : "")) : root.statusText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: root.accentColor
                    }

                    StyledText {
                        visible: !root.trackTitle
                        Layout.alignment: Qt.AlignRight
                        text: root.statusText
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.dimColor
                    }
                }
            }

            // lyrics list
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, root.bgOpacity)

                ListView {
                    id: lyricsView
                    anchors.fill: parent
                    anchors.margins: Theme.spacingXS
                    clip: true
                    spacing: Theme.spacingXS

                    model: root.lyricsLines
                    currentIndex: root.currentLineIndex

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: lyricsView.width
                        height: lyricText.implicitHeight + Theme.spacingXS

                        StyledText {
                            id: lyricText
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            text: modelData.text || ""
                            font.pixelSize: root.lyricFontSize
                            font.weight: index === root.currentLineIndex ? Font.Bold : Font.Normal
                            color: index === root.currentLineIndex ? root.accentColor : root.dimColor
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    // empty state
                    StyledText {
                        anchors.centerIn: parent
                        visible: root.lyricsLines.length === 0
                        text: root.statusText
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.dimColor
                    }
                }
            }
        }
    }
}
