import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../state/app_state.dart';
import 'app_language.dart';

class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static const supportedLocales = [Locale('ja', 'JP'), Locale('en', 'US')];

  Locale get locale => language.locale;

  String get _localeTag => language.currencyLocale;

  NumberFormat get currencyFormat =>
      NumberFormat.currency(locale: _localeTag, symbol: '¥', decimalDigits: 0);

  String formatDate(DateTime date) {
    if (language == AppLanguage.japanese) {
      return DateFormat('yyyy/MM/dd', _localeTag).format(date);
    }
    return DateFormat.yMMMd(_localeTag).format(date);
  }

  String _select(String ja, String en) =>
      language == AppLanguage.japanese ? ja : en;

  // General labels
  String get appTitle => _select('和式請求書ジェネレーター', 'Invoice Studio');
  String get dashboardNav => _select('ダッシュボード', 'Dashboard');
  String get invoicesNav => _select('請求書', 'Invoices');
  String get settingsNav => _select('設定', 'Settings');
  String get upgradeToPremiumButton =>
      _select('プレミアムへアップグレード', 'Upgrade to Premium');
  String get premiumActiveLabel =>
      _select('プレミアム適用中', 'Premium Active');
  String get notificationsTooltip => _select('通知', 'Notifications');
  String get menuTitle => _select('メニュー', 'Menu');
  String get newInvoiceAction =>
      _select('新しい請求書', 'New invoice');
  String get newInvoiceShort => _select('新規作成', 'Create');
  String get cancelAction => _select('キャンセル', 'Cancel');
  String get closeAction => _select('閉じる', 'Close');
  String get deleteAction => _select('削除する', 'Delete');
  String get upgradeDialogTitle =>
      _select('プレミアムプラン', 'Premium plan');
  String get upgradeDialogMessage => _select(
        '月額¥500でPDFダウンロード無制限・ブランドロゴ設定などの機能が利用できます。アップグレードしますか？',
        'Upgrade for ¥500/month to unlock unlimited PDF downloads, brand customization, and priority support. Proceed with the upgrade?',
      );
  String get upgradeDialogCta => _select('アップグレード', 'Upgrade');
  String get notificationsTitle => _select('最新のお知らせ', 'Latest updates');
  String get notificationTaxUpdateTitle => _select(
        '請求書テンプレートに「軽減税率」項目を追加しました。',
        'Added a “Reduced tax rate” field to the invoice template.',
      );
  String get notificationPremiumUpdateTitle => _select(
        'Stripe 決済がプレミアムプランでも利用可能になりました。',
        'Stripe payments are now available on the premium plan.',
      );
  String get invoiceCreatedSnack =>
      _select('請求書を作成しました。', 'Invoice created.');
  String get invoiceUpdatedSnack =>
      _select('請求書を更新しました。', 'Invoice updated.');
  String get invoiceDeletedSnack =>
      _select('請求書を削除しました。', 'Invoice deleted.');
  String deleteInvoiceMessage(String client, String number) => _select(
        '${client}向けの請求書（${number}）を削除しますか？',
        'Delete the invoice for $client (No. $number)?',
      );
  String get deleteInvoiceTitle =>
      _select('請求書の削除', 'Delete invoice');
  String get upgradeToPremiumCta =>
      _select('プレミアムにアップグレード', 'Upgrade to premium');
  String get downgradeToFreeCta =>
      _select('フリープランにダウングレード', 'Switch to free plan');
  String get downgradeToFreePlanButton =>
      _select('フリープランに戻す', 'Switch to free plan');
  String get premiumPlanActiveLabel =>
      _select('プレミアム適用中', 'Premium active');
  String get accountMenuTooltip =>
      _select('アカウント', 'Account');
  String get signOut => _select('サインアウト', 'Sign out');
  String get languageSettingLabel =>
      _select('表示言語', 'Display language');
  String get languageJapanese => _select('日本語', 'Japanese');
  String get languageEnglish => _select('英語', 'English');

  // Dashboard
  String dashboardGreeting(String ownerName) =>
      _select('おかえりなさい、${ownerName}さん', 'Welcome back, $ownerName');
  String dashboardLead(String amount) => _select(
        '今月は${amount}の入金が確認できています。未回収分のフォローアップを行いましょう。',
        '$amount has been collected this month. Follow up on the remaining invoices.',
      );
  String get dashboardCreateInvoiceButton =>
      _select('請求書を作成', 'Create invoice');
  String get metricPaidTitle => _select('入金済み', 'Paid');
  String metricPaidSubtitle(int count) => _select(
        '過去30日で${count}件',
        '$count invoices in the last 30 days',
      );
  String get metricOutstandingTitle => _select('未入金', 'Outstanding');
  String metricOutstandingSubtitle(int dueSoon) => _select(
        '今後7日以内の期限: ${dueSoon}件',
        '$dueSoon due within the next 7 days',
      );
  String get metricOverdueTitle => _select('期限切れ', 'Overdue');
  String metricOverdueSubtitle(bool enabled) => _select(
        'リマインドメール設定: ${enabled ? 'ON' : 'OFF'}',
        'Reminder emails: ${enabled ? 'On' : 'Off'}',
      );
  String get metricDraftTitle => _select('下書き', 'Draft');
  String metricDraftSubtitle(bool enabled) => _select(
        '自動採番: ${enabled ? '有効' : '無効'}',
        'Auto numbering: ${enabled ? 'Enabled' : 'Disabled'}',
      );
  String get dashboardFollowUpTitle =>
      _select('フォローアップ推奨', 'Suggested follow-ups');
  String get dashboardNoPending =>
      _select('対応が必要な請求書はありません。', 'No invoices need attention.');
  String dashboardFollowUpLine(String client, String amount) => _select(
        '${client} への請求（${amount}）',
        'Invoice for $client ($amount)',
      );
  String dashboardFollowUpSubtitle(String dueDate, String status) => _select(
        '支払期限: ${dueDate} • ステータス: ${status}',
        'Due: $dueDate • Status: $status',
      );
  String get dashboardNewInvoiceCta =>
      _select('新しい請求書を作成', 'Create new invoice');
  String get dashboardDownloadsTitle =>
      _select('PDF ダウンロード上限', 'PDF download quota');
  String get dashboardDownloadsUnlimited => _select(
        'プレミアムプランのため上限はありません。',
        'Unlimited downloads on the premium plan.',
      );
  String dashboardDownloadsUsage(int used, int limit) => _select(
        '今月は${limit}件中${used}件ダウンロード済みです。',
        '$used of $limit downloads used this month.',
      );
  String get dashboardRecentInvoicesTitle =>
      _select('最近の請求書', 'Recent invoices');
  String dashboardRecentInvoiceSubtitle(String issueDate, String amount) =>
      _select('発行日: ${issueDate} • 金額: ${amount}',
          'Issued: $issueDate • Total: $amount');

  // Invoices page
  String get invoicesHeaderTitle => _select('請求書管理', 'Invoice management');
  String get invoicesHeaderSubtitle => _select(
        'クライアント別にフィルタし、ワンクリックでPDFを生成できます。',
        'Filter by client and generate PDFs in one click.',
      );
  String get invoicesSearchHint =>
      _select('クライアント名や請求書番号で検索', 'Search by client or invoice number');
  String get filterAll => _select('すべて', 'All');
  String get noInvoicesFound =>
      _select('該当する請求書がありません。', 'No invoices match your filters.');
  String get createFirstInvoice =>
      _select('最初の請求書を作成', 'Create your first invoice');
  String get issueDateLabel => _select('発行日', 'Issue date');
  String get dueDateLabel => _select('支払期限', 'Due date');
  String get invoiceActionsTooltip =>
      _select('操作', 'Actions');
  String get edit => _select('編集', 'Edit');
  String get delete => _select('削除', 'Delete');
  String get selectInvoiceEmptyState => _select(
        '請求書を選択すると詳細が表示されます。',
        'Select an invoice to preview the details.',
      );
  String get createInvoiceAction =>
      _select('請求書を作成', 'Create invoice');

  // Settings page
  String get settingsTitle => _select('ワークスペース設定', 'Workspace settings');
  String get settingsSubtitle => _select(
        '請求書テンプレートや課金ステータスの管理を行います。',
        'Manage invoice templates and billing preferences.',
      );
  String get settingsBusinessSectionTitle =>
      _select('事業者情報', 'Business information');
  String get businessNameLabel => _select('事業者名', 'Business name');
  String get ownerLabel => _select('担当者', 'Owner');
  String get addressLabel => _select('所在地', 'Address');
  String get postalCodeLabel => _select('郵便番号', 'Postal code');
  String get emailLabel => _select('メールアドレス', 'Email');
  String get phoneLabel => _select('電話番号', 'Phone');
  String get editProfile =>
      _select('プロフィールを編集', 'Edit profile');
  String get settingsPlanSectionTitle =>
      _select('プラン', 'Plan');
  String get premiumPlanName =>
      _select('プレミアムプラン（¥500/月）', 'Premium plan (¥500/mo)');
  String get freePlanName => _select('無料プラン', 'Free plan');
  String get premiumPlanDescription => _select(
        'PDFダウンロード無制限 / カスタムブランド / 優先サポート',
        'Unlimited PDFs / Custom branding / Priority support',
      );
  String get freePlanDescription => _select(
        '月3件までPDFダウンロード / 基本テンプレート',
        'Up to 3 PDF downloads per month / Basic templates',
      );
  String planStripeNotice() => _select(
        'Stripe 決済は有効化済みです。請求書テンプレートに表示される課金情報は自動で更新されます。',
        'Stripe payments are enabled. Billing details on your invoices update automatically.',
      );
  String get settingsTemplateSectionTitle =>
      _select('請求書テンプレート', 'Invoice template');
  String get autoNumberingTitle =>
      _select('請求書番号を自動採番する', 'Auto-generate invoice numbers');
  String get autoNumberingSubtitle => _select(
        '「INV-YYYYMM-001」の形式で連番を採番します。',
        'Generate numbers like “INV-YYYYMM-001”.',
      );
  String get reminderEmailsTitle =>
      _select('支払期限メールを自動送信', 'Send due-date reminders automatically');
  String get reminderEmailsSubtitle => _select(
        '期限切れの請求書に対して、1日後にリマインドメールを送信します。',
        'Send reminder emails one day after the due date.',
      );
  String get japaneseEraTitle =>
      _select('日付を和暦表示にする', 'Show Japanese era dates');
  String get japaneseEraSubtitle => _select(
        '請求書上の日付を令和表記に変更します。',
        'Display invoice dates using the Reiwa era style.',
      );
  String get defaultTaxRateLabel =>
      _select('標準税率', 'Default tax rate');
  String get supportSectionTitle =>
      _select('サポートとリソース', 'Support and resources');
  String get helpCenter => _select('ヘルプセンター', 'Help center');
  String get helpCenterSubtitle =>
      _select('FAQや使い方ガイドを確認できます。', 'Browse FAQs and guides.');
  String get supportContact =>
      _select('サポートへ問い合わせ', 'Contact support');
  String get community => _select('コミュニティ', 'Community');
  String get communitySubtitle => _select(
        'Slackで他のユーザーと情報交換しましょう。',
        'Connect with other users on Slack.',
      );

  // Invoice form dialog
  String get invoiceDialogTitleCreate =>
      _select('請求書を作成', 'Create invoice');
  String get invoiceDialogTitleEdit =>
      _select('請求書を編集', 'Edit invoice');
  String get invoiceNumberLabel =>
      _select('請求書番号', 'Invoice number');
  String get invoiceNumberHint =>
      _select('INV-202405-001', 'INV-202405-001');
  String get invoiceNumberRequired =>
      _select('請求書番号を入力してください。', 'Enter an invoice number.');
  String get statusLabel => _select('ステータス', 'Status');
  String get clientLabel =>
      _select('請求先（会社名）', 'Client (company)');
  String get clientRequired =>
      _select('請求先を入力してください。', 'Enter a client name.');
  String get projectLabel => _select('案件名 / 件名', 'Project / subject');
  String get projectRequired =>
      _select('案件名を入力してください。', 'Enter a project name.');
  String get billingEmailLabel =>
      _select('請求書送付先メールアドレス', 'Billing email');
  String get billingEmailHint =>
      _select('billing@example.jp', 'billing@example.com');
  String get taxRateLabel => _select('税率', 'Tax rate');
  String get issueDateField => _select('発行日', 'Issue date');
  String get dueDateField => _select('支払期限', 'Due date');
  String get lineItemsTitle => _select('請求内容', 'Line items');
  String get addItem => _select('品目を追加', 'Add item');
  String get notesLabel =>
      _select('備考・メッセージ', 'Notes / message');
  String get notesHint => _select(
        '例: お振込手数料は貴社負担にてお願いいたします。',
        'e.g. Please cover the bank transfer fee.',
      );
  String get summarySubtotal => _select('小計', 'Subtotal');
  String get summaryTax => _select('消費税', 'Tax');
  String get summaryTotal => _select('合計', 'Total');
  String get createButton => _select('作成する', 'Create');
  String get updateButton => _select('更新する', 'Update');
  String get quantityMustBePositive =>
      _select('数量は1以上で入力してください。', 'Quantity must be at least 1.');
  String get addAtLeastOneItem =>
      _select('品目を1件以上追加してください。', 'Add at least one line item.');
  String get itemDescriptionLabel =>
      _select('品目名', 'Item name');
  String get itemDescriptionRequired =>
      _select('品目名を入力してください。', 'Enter an item name.');
  String get quantityLabel => _select('数量', 'Quantity');
  String get unitPriceLabel => _select('単価 (¥)', 'Unit price (¥)');
  String get removeItemTooltip => _select('削除', 'Remove');
  String get taxOptionZero => _select('0%', '0%');
  String get taxOptionReduced =>
      _select('8% (軽減税率)', '8% (reduced)');
  String get taxOptionStandard =>
      _select('10% (標準税率)', '10% (standard)');
  String get taxOptionTwenty => _select('20%', '20%');

  // Invoice preview
  String invoiceTitle(String? number) => number == null || number.isEmpty
      ? _select('請求書（番号未設定）', 'Invoice (no number)')
      : _select('請求書 ${number}', 'Invoice $number');
  String previewClient(String client) =>
      _select('請求先: ${client}', 'Client: $client');
  String previewProject(String project) =>
      _select('案件名: ${project}', 'Project: $project');
  String get previewAmountLabel => _select('請求金額', 'Amount due');
  String get previewTaxRateLabel => _select('税率', 'Tax rate');
  String get itemsHeaderDescription => _select('品目', 'Item');
  String get itemsHeaderQuantity => _select('数量', 'Qty');
  String get itemsHeaderUnitPrice => _select('単価', 'Unit price');
  String get itemsHeaderAmount => _select('金額', 'Amount');
  String get downloadPdf => _select('PDFをダウンロード', 'Download PDF');
  String get sendReminder => _select('リマインドを送る', 'Send reminder');

  // Authentication
  String get signInTitle => _select('アカウントにサインイン', 'Sign in to your account');
  String get signInSubtitle => _select(
        'Firebaseアカウントでログインし、請求書を管理しましょう。',
        'Use your Firebase account to manage invoices.',
      );
  String get registerTitle =>
      _select('アカウントを作成', 'Create an account');
  String get emailFieldLabel => _select('メールアドレス', 'Email');
  String get emailRequired =>
      _select('メールアドレスを入力してください。', 'Enter your email.');
  String get passwordFieldLabel => _select('パスワード', 'Password');
  String get passwordRequired =>
      _select('パスワードを入力してください。', 'Enter your password.');
  String get passwordLengthError =>
      _select('パスワードは6文字以上で入力してください。', 'Use at least 6 characters.');
  String get submitSignIn => _select('ログイン', 'Sign in');
  String get submitRegister => _select('登録する', 'Register');
  String get toggleToRegister =>
      _select('アカウントをお持ちでない場合はこちら', 'Need an account? Register');
  String get toggleToSignIn =>
      _select('すでにアカウントをお持ちの場合はこちら', 'Already have an account? Sign in');
  String get authGenericError =>
      _select('認証に失敗しました。時間をおいて再度お試しください。',
          'Authentication failed. Please try again later.');
  String authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return _select('ユーザーが見つかりませんでした。',
            'No user found with that email.');
      case 'wrong-password':
        return _select('パスワードが正しくありません。', 'Incorrect password.');
      case 'email-already-in-use':
        return _select('既に登録済みのメールアドレスです。',
            'That email is already registered.');
      case 'weak-password':
        return _select('パスワードが弱すぎます。',
            'Your password is too weak. Try something stronger.');
      default:
        return authGenericError;
    }
  }

  String invoiceStatusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return _select('下書き', 'Draft');
      case InvoiceStatus.sent:
        return _select('送信済み', 'Sent');
      case InvoiceStatus.paid:
        return _select('支払い済み', 'Paid');
      case InvoiceStatus.overdue:
        return _select('期限切れ', 'Overdue');
    }
  }
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n {
    final language = watch<AppState>().language;
    return AppLocalizations(language);
  }
}
