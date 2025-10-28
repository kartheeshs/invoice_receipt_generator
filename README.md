# Easy Invoice GM7（和式請求書ジェネレーター）

Easy Invoice GM7 は Next.js と Firebase を組み合わせて構築した請求書・領収書ジェネレーターです。以前の Flutter 版で好評だったダッシュボード／インボイス編集／テンプレート選択 UI をそのままウェブアプリとして再現し、ブラウザだけで請求書の作成・プレビュー・PDF エクスポートまで完結できます。

## 主な機能

- 📊 トップナビゲーション付きダッシュボードで「ダッシュボード / 請求書 / テンプレート / クライアント / 設定」を素早く行き来
- 🧾 請求書エディタとライブプレビューを同一画面に配置し、数値入力と同時に金額を再計算
- 📄 ワンクリックで印刷用 HTML を生成し PDF としてダウンロード
- ☁️ Firebase Firestore を利用した請求書の保存と最新履歴の取得（認証情報が未設定の場合はサンプルデータを表示）
- 🌐 Next.js App Router を使った SEO 対応のマーケティングページとアプリ UI の共存

## リポジトリ構成

```
.
├── next-app/        # Next.js (App Router) フロントエンド
├── functions/       # Firebase Functions（サーバー拡張が必要な場合に使用）
├── server/          # Stripe 連携などの Node/Express ユーティリティ
├── firebase.json    # Firebase Hosting / Firestore / Functions の設定
└── storage.rules    # Firebase Storage ルール
```

## セットアップ

### 1. フロントエンド (`next-app`)

> 💡 ルートディレクトリで `npm install` や `npm run dev` を実行すると、自動的に `next-app` ワークスペースに委譲されます。手動で `cd next-app` する必要はありません。

1. 依存関係をインストール
   ```bash
   npm install
   ```
2. Firebase プロジェクトを利用する場合は `.env.local` を作成（または `next-app/.env.example` をコピー）し、以下の環境変数を設定します。
   ```env
   NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyC9yXs3QnOfRyLyN74QyilSfeKL-fVUxAQ
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=invoice-receipt-generator-g7.firebaseapp.com
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=invoice-receipt-generator-g7
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=invoice-receipt-generator-g7.firebasestorage.app
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=798489264335
   NEXT_PUBLIC_FIREBASE_APP_ID=1:798489264335:web:b1bc7f6fe8dc5e68de37ba
   NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=G-TKYV2VSPMZ
   ```
3. 開発サーバーを起動
   ```bash
   npm run dev
   ```
   ブラウザで `http://localhost:3000` を開くとマーケティングページと `/app` ワークスペースが利用できます。
4. Firebase Hosting へデプロイする静的ビルドを生成
   ```bash
   npm run build:static
   ```
   出力先は `next-app/out/` です（`firebase.json` もこのパスを参照しています）。

### 2. Firebase Functions (`functions`)

必要に応じて以下を実行してください。

```bash
cd functions
npm install
npm run lint
npm run build
```

### 3. Node/Express サーバー (`server`)

Stripe Webhook など追加のバックエンドが必要な場合に利用できます。

```bash
cd server
npm install
npm run dev
```

## Firebase Hosting へのデプロイ

1. フロントエンドを静的ビルド
   ```bash
   npm run build:static
   ```
2. Firebase CLI からデプロイ
   ```bash
   firebase deploy --only hosting
   ```
   `next-app/out/` の内容がそのまま配信されます。

## 利用技術

| カテゴリ | 技術 |
| --- | --- |
| フロントエンド | Next.js 15 (App Router), React 18, TypeScript |
| UI / スタイリング | CSS Modules (グローバル), 自前デザインシステム |
| 認証 / データ | Firebase Authentication, Firestore (REST API) |
| PDF 生成 | ブラウザの `window.print()` を利用した HTML ベースのプレビュー |
| その他 | Firebase Hosting, Firebase Functions, Stripe (server ディレクトリ) |

---

本番運用時は Firebase セキュリティルール、HTTPS、Stripe Webhook のシークレット管理などを適切に設定してください。
