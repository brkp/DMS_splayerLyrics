# DMS_splayerLyrics

Dank Material Shell (dms) 桌面部件插件：显示 SPlayer 正在播放歌曲的歌词。

## 功能

- 通过 MPRIS 读取 SPlayer 播放状态（歌名、歌手、播放进度）
- 通过 SPlayer 本地接口（`http://127.0.0.1:25884/api/netease/lyric?id=`) 获取歌词
- 按播放进度高亮当前行，自动居中滚动
- 支持设置背景透明度和歌词字号

## 安装

将插件目录放到 dms 插件扫描路径，例如：

```
~/.config/DankMaterialShell/plugins/splayerLyrics/
```

然后打开 dms 设置 → 插件 → 扫描 → 启用 SPlayer Lyrics，桌面添加部件即可。

## 依赖

- SPlayer 正在运行并播放歌曲
- dms (Dank Material Shell)

## 文件

- `plugin.json` — 插件注册信息
- `SPlayerLyrics.qml` — 主组件
