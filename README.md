# Gas Mask

[![Build Status](https://github.com/dmm-aoi-yuki/gasmask/actions/workflows/push.yml/badge.svg)](https://github.com/dmm-aoi-yuki/gasmask/actions/workflows/push.yml)
[![Latest Release](https://img.shields.io/github/v/release/dmm-aoi-yuki/gasmask?display_name=tag)](https://github.com/dmm-aoi-yuki/gasmask/releases)
[![License: GPL v2 or later](https://img.shields.io/badge/license-GPL%20v2%20or%20later-blue.svg)](LICENSE)

Gas Mask は、macOS 向けのシンプルな hosts ファイルマネージャーです。
ローカル hosts の編集、リモート hosts の同期、複数 hosts の切り替えを GUI で扱えます。

このリポジトリは、更新が止まっている本家 Gas Mask をベースに Apple Silicon と現行 Xcode 向けの保守を続ける fork です。

## 概要

Gas Mask は `/etc/hosts` を監視し、選択中の hosts ファイルの内容をシステムへ反映します。

- ローカル hosts ファイルの編集
- リモート hosts ファイルの定期同期
- 複数の hosts ファイルの素早い切り替え
- 複数ソースを束ねる Combined hosts の利用

カスタム hosts ファイルは `~/Library/Gas Mask` に保存されます。
ログは `~/Library/Logs/Gas Mask.log` に出力されます。問題報告時はこのログを確認すると原因を追いやすくなります。

## 動作環境

- macOS 13 Ventura 以降

## ダウンロード

- 最新版は [GitHub Releases](https://github.com/dmm-aoi-yuki/gasmask/releases) から入手してください。
- 現在の arm64 公開版は `0.8.6-arm64.2` を想定しています。

## インストール

1. ダウンロードしたアプリを Applications フォルダへ移動します。
2. 初回起動時に管理者権限を要求されます。

`/etc/hosts` を更新するため、初回起動時にパスワード入力が必要です。

## 使い方

Gas Mask は通常バックグラウンドで動作し、メニューバーにアイコンを表示します。メニューバーからメイン画面を開いたり、アクティブな hosts ファイルを素早く切り替えたりできます。

メイン画面は、ツールバー、左側の hosts ファイル一覧、右側のエディタで構成されます。初期状態では `Local` 配下に `Original file` があり、これは元の `/etc/hosts` のコピーです。

### 基本操作

- 追加: ツールバーの `Create (+)` から `Local`、`Remote`、`Combined` を選択
- 削除: 対象ファイルを選択して `Remove` を実行
- 有効化: 対象ファイルを選択して `Activate` を実行

有効化されたファイルは一覧でチェック表示され、設定の `Preferences > Show Host File Name in Status Bar` を有効にするとメニューバーにもファイル名を表示できます。

### ファイル種別

#### Local

通常のローカル hosts ファイルです。内容を直接編集できます。

#### Remote

指定した URL からダウンロードして同期する hosts ファイルです。更新間隔は Preferences で設定でき、メニューバーから手動更新もできます。同期時に上書きされるため、直接編集はできません。

#### Combined

複数の Local / Remote hosts をまとめて扱うためのファイルです。hosts エントリそのものではなく、参照する hosts ファイルの組み合わせを保持します。

## hosts ファイルの入手先

公開 hosts リストの例として、次のリポジトリが利用できます。

- https://github.com/StevenBlack/hosts

## ビルド

Gas Mask のビルドには Xcode 15 以降が必要です。

- Apple Silicon 向け標準ビルド: `./build.sh`
- Apple Silicon 向け互換エイリアス: `./build-arm.sh`
- 旧来の universal build (arm64 + x86_64): `./build-universal.sh`
- リリース用 zip 生成: `CONFIGURATION=Release ARCHS=arm64 ./package-release.sh`

リリース作業の詳細は [docs/RELEASING.md](docs/RELEASING.md) を参照してください。

## 配布と更新

- 配布は GitHub Releases を基準に行います。
- アプリ内自動更新は fork 側の appcast と署名鍵を整備するまで無効化しています。
- 配布用のリリースノート雛形は [docs/release-notes/0.8.6-arm64.2.md](docs/release-notes/0.8.6-arm64.2.md) に置いています。

## ライセンス

このプロジェクトは GNU General Public License v2 またはそれ以降の条件で提供されています。
詳細は [LICENSE](LICENSE) を参照してください。GPL に従う限り、商用利用も可能です。
