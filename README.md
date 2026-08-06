# DMS_splayerLyrics

Dank Material Shell (dms) 桌面部件插件：显示 SPlayer 正在播放歌曲的歌词。

## 功能

- 通过 MPRIS 读取 SPlayer 播放状态（歌名、歌手、播放进度）
- 通过 SPlayer 本地接口（`http://127.0.0.1:25884/api/netease/lyric?id=`) 获取歌词
- 按播放进度高亮当前行，自动居中滚动
- 支持设置背景透明度和歌词字号
- SPlayer 未运行时自动隐藏并开启鼠标穿透

## 安装

插件已上架 dms 官方插件注册表，直接用 dms 命令安装：

```bash
dms plugins install splayerDesktopLyrics
```

安装后在 dms 设置中启用 SPlayer Lyrics (Desktop)。

## 更新

```bash
dms plugins update splayerDesktopLyrics
```

## 依赖

- SPlayer 正在运行并播放歌曲
- dms (Dank Material Shell)

## 文件

- `plugin.json` — 插件注册信息
- `SPlayerLyrics.qml` — 主组件
- `Settings.qml` — 设置面板
