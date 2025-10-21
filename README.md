# 和式請求書ジェネレーター

日本のフリーランスや個人事業主がすぐに使える請求書・領収書作成アプリです。Google 認証でログインし、クラウドに請求書を保存・編集、ワンクリックで日本語スタイルのPDFを出力できます。無料プランでは月3件までPDFダウンロード可能、Stripeサブスクリプションでプレミアム（月額¥500）へアップグレードすると無制限で利用できます。

## 主な機能

- 🇯🇵 日本の商習慣に合わせたレイアウトの PDF を jsPDF で生成
- 🔐 Firebase Authentication（Google）によるログイン
- ☁️ Firestore への請求書データ保存と月次ダウンロード数トラッキング
- 💳 Stripe Checkout / Billing Portal を使ったサブスクリプション課金
- 🎨 Material UI を使ったプロフェッショナルな React ダッシュボード
- 📱 レスポンシブ対応（PC / タブレット / スマートフォン）

## リポジトリ構成

```
.
├── web/        # React + Vite フロントエンド
└── server/     # Express + Stripe + Firebase Admin バックエンド
```

## 必要要件

- Node.js 18 以上
- Firebase プロジェクト（Authentication + Firestore）
- Stripe アカウント（定期課金用の Price ID と Webhook Secret）

## セットアップ手順

### 1. フロントエンド (`web`)

1. 依存関係をインストール
   ```bash
   cd web
   npm install
   ```
2. `.env` を作成（テンプレートは `.env.example`）
   ```bash
   cp .env.example .env
   ```
   必要項目:
   - `VITE_FIREBASE_*`: Firebase コンソールで取得
   - `VITE_API_BASE_URL`: バックエンドの URL (ローカルの場合 `http://localhost:3001`)
3. 開発サーバー起動
   ```bash
   npm run dev
   ```

### 2. バックエンド (`server`)

1. 依存関係をインストール
   ```bash
   cd server
   npm install
   ```
2. `.env` を作成（テンプレートは `.env.example`）
   ```bash
   cp .env.example .env
   ```
   主な項目:
   - `STRIPE_SECRET_KEY` / `STRIPE_PRICE_ID` / `STRIPE_WEBHOOK_SECRET`
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: Firebase サービスアカウント JSON を base64 エンコードして設定
   - `FRONTEND_URL`: フロントエンド URL（例: `http://localhost:5173`）
3. 開発サーバー起動
   ```bash
   npm run dev
   ```
4. Stripe Webhook のローカル転送（任意）
   ```bash
   stripe listen --forward-to localhost:3001/billing/webhook
   ```

## Stripe 設定メモ

- 定期課金用の Price を Stripe ダッシュボードで作成し、`STRIPE_PRICE_ID` に設定します。
- Webhook エンドポイント (`/billing/webhook`) に対して以下イベントの送信を有効化してください。
  - `checkout.session.completed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`

## Firebase セキュリティルール例

Firestore で `users/{userId}` 配下に請求書を保存します。最低限のルール例:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /invoices/{invoiceId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## 利用している主な技術

| カテゴリ | 技術 |
| --- | --- |
| フロントエンド | React 18, Vite, TypeScript, Material UI, React Router |
| 状態管理・認証 | Firebase Authentication, Firestore |
| PDF 生成 | jsPDF + jspdf-autotable |
| 課金 | Stripe Checkout / Billing Portal |
| バックエンド | Express, Firebase Admin, Stripe SDK |

## スクリプト一覧

### フロントエンド (`web`)
- `npm run dev` – 開発サーバー起動
- `npm run build` – 本番ビルド
- `npm run preview` – ビルド結果のプレビュー
- `npm run lint` – ESLint による静的解析

### バックエンド (`server`)
- `npm run dev` – ts-node-dev でホットリロード開発
- `npm run build` – TypeScript をコンパイル
- `npm run start` – ビルド済みコードを実行

## 今後の拡張アイデア

- プレミアム向けにロゴアップロードやカスタムテンプレートを追加
- 発行済み請求書のメール送信機能
- 日本語フォントを埋め込んだ PDF の高品質化
- 月次請求書の自動生成スケジューラ

---

プロダクション展開には HTTPS 対応、Stripe Webhook のシークレット管理、Firestore ルールの最適化などを行ってください。
