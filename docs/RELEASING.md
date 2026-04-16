# Releasing Gas Mask

この fork は GitHub Releases を配布の基準にします。Sparkle の appcast と署名鍵を整備するまでは、アプリ内自動更新は無効のまま運用します。

## 事前確認

1. `README.md` のバッジとダウンロード案内が fork を向いていることを確認する。
2. `Info.plist` のバージョンを更新する。
3. `./build.sh` と `xcodebuild test -project "Gas Mask.xcodeproj" -scheme "Gas Mask" -destination "platform=macOS" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` が通ることを確認する。
4. リリースノートを `docs/release-notes/` に用意する。

## ローカルで配布物を作る

arm64 の zip を作る:

```bash
CONFIGURATION=Release ARCHS=arm64 ./package-release.sh
```

arm64 の zip と dmg を作る:

```bash
CONFIGURATION=Release ARCHS=arm64 CREATE_DMG=1 ./package-release.sh
```

生成物は `dist/` に出力されます。

## GitHub Releases へ公開する

1. 変更を `master` に入れる。
2. 例のようにタグを作る。

```bash
git tag v0.8.6-arm64.1
git push origin v0.8.6-arm64.1
```

3. `.github/workflows/release.yml` が draft release を作成し、zip を添付する。
4. draft release に `docs/release-notes/0.8.6-arm64.1.md` の内容を貼る。
5. 必要なら手元で作った dmg を追加添付して公開する。

## 今後 Sparkle を有効化するとき

1. appcast を fork 管理下で配信する。
2. `SUPublicEDKey` を実値に置き換える。
3. `SUFeedURL` を appcast URL に設定する。
4. `SUEnableAutomaticChecks` の既定値を有効化する。
5. Preferences の Update タブとメニューから動作確認する。