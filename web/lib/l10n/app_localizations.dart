import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ja')];

  static const _localizedValues = {
    'en': {
      'appTitle': 'Invoice & Receipt Generator',
      'signInTitle': 'Sign in to continue',
      'signUpTitle': 'Create your account',
      'emailLabel': 'Email address',
      'passwordLabel': 'Password',
      'confirmPasswordLabel': 'Confirm password',
      'displayNameLabel': 'Full name',
      'signInButton': 'Sign in',
      'signUpButton': 'Create account',
      'forgotPassword': 'Forgot password?',
      'sendResetLink': 'Send reset link',
      'resetPasswordSent': 'Password reset email sent.',
      'noAccountPrompt': "Don't have an account?", 
      'haveAccountPrompt': 'Already have an account?',
      'languageLabel': 'Language',
      'languageSectionLabel': 'Choose application language',
      'languageEnglish': 'English',
      'languageJapanese': 'Japanese',
      'dashboardTab': 'Dashboard',
      'invoicesTab': 'Invoices',
      'settingsTab': 'Settings',
      'welcomeBack': 'Welcome back, {name}',
      'planStatusFree': 'Free plan',
      'planStatusPremium': 'Premium subscriber',
      'subscriptionTitle': 'Subscription',
      'subscriptionDescription':
          'Upgrade via Crisp to unlock unlimited invoices and premium templates.',
      'planFreeBody': 'You are using the free plan. Upgrade any time to unlock unlimited PDF exports.',
      'planPremiumBody': 'You are enjoying premium benefits. Thank you for subscribing!',
      'firebaseBanner':
          'Firebase auth is not configured. Provide FIREBASE_API_KEY via --dart-define to enable authentication.',
      'subscribeCrisp': 'Subscribe via Crisp',
      'manageSubscription': 'Manage subscription',
      'cancelSubscription': 'Cancel subscription',
      'monthlyPrice': 'Monthly price',
      'planPriceLabel': '¥600 / month',
      'planPriceLabelLocalized': '{price} / month',
      'planBenefits': 'Benefits',
      'planBenefitsBody':
          'Unlimited invoices, premium templates, automated reminders.',
      'quickActions': 'Quick actions',
      'createInvoiceAction': 'Create invoice',
      'viewInvoicesAction': 'View invoices',
      'totalInvoices': 'Total invoices',
      'outstanding': 'Outstanding',
      'paid': 'Paid',
      'averageInvoice': 'Average invoice',
      'recentInvoices': 'Recent invoices',
      'invoicesEmptyTitle': 'Create your first invoice',
      'invoicesEmptyBody':
          'Generate invoices and receipts instantly for your clients.',
      'newInvoice': 'New invoice',
      'editInvoice': 'Edit invoice',
      'invoiceFormTitle': 'Invoice details',
      'clientLabel': 'Client name',
      'projectLabel': 'Project name',
      'descriptionLabel': 'Description',
      'amountLabel': 'Amount',
      'invoiceNumberLabel': 'Invoice number',
      'issueDateLabel': 'Issue date',
      'dueDateLabel': 'Due date',
      'notesLabel': 'Notes',
      'statusLabel': 'Status',
      'saveButton': 'Save',
      'cancelButton': 'Cancel',
      'deleteButton': 'Delete',
      'downloadPdf': 'Download PDF',
      'searchInvoices': 'Search invoices',
      'filterAll': 'All',
      'status_draft': 'Draft',
      'status_sent': 'Sent',
      'status_paid': 'Paid',
      'status_overdue': 'Overdue',
      'profileTitle': 'Profile',
      'profileDialogTitle': 'Update profile',
      'profileNameLabel': 'Name',
      'profileCompanyLabel': 'Company',
      'profileAddressLabel': 'Address',
      'profilePhoneLabel': 'Phone',
      'profileTaxIdLabel': 'Tax ID',
      'editProfile': 'Edit profile',
      'profileUpdated': 'Profile updated',
      'invoiceSaved': 'Invoice saved',
      'invoiceDeleted': 'Invoice deleted',
      'pdfReady': 'Invoice PDF is ready to download.',
      'errorUnknown': 'Something went wrong. Please try again.',
      'firebaseMissing':
          'Firebase auth is not configured. Provide FIREBASE_API_KEY via --dart-define to enable password reset.',
      'validationRequired': 'This field is required',
      'validationEmail': 'Enter a valid email address',
      'validationPasswordLength': 'Password must be at least 6 characters',
      'validationPasswordMatch': 'Passwords do not match',
      'validationAmount': 'Enter a valid amount',
      'signOut': 'Sign out',
      'confirmSignOut': 'Do you want to sign out?',
      'confirm': 'Confirm',
    },
    'ja': {
      'appTitle': '請求書・領収書ジェネレーター',
      'signInTitle': 'ログインして続行',
      'signUpTitle': 'アカウントを作成',
      'emailLabel': 'メールアドレス',
      'passwordLabel': 'パスワード',
      'confirmPasswordLabel': 'パスワード確認',
      'displayNameLabel': '氏名',
      'signInButton': 'ログイン',
      'signUpButton': 'アカウントを作成',
      'forgotPassword': 'パスワードをお忘れですか？',
      'sendResetLink': 'リセットメールを送信',
      'resetPasswordSent': 'パスワード再設定メールを送信しました。',
      'noAccountPrompt': 'アカウントをお持ちでない方はこちら',
      'haveAccountPrompt': 'すでにアカウントをお持ちの方はこちら',
      'languageLabel': '言語',
      'languageSectionLabel': 'アプリの言語を選択',
      'languageEnglish': '英語',
      'languageJapanese': '日本語',
      'dashboardTab': 'ダッシュボード',
      'invoicesTab': '請求書',
      'settingsTab': '設定',
      'welcomeBack': '{name}さん、おかえりなさい',
      'planStatusFree': 'フリープラン',
      'planStatusPremium': 'プレミアムプラン利用中',
      'subscriptionTitle': 'サブスクリプション',
      'subscriptionDescription':
          'Crisp経由でアップグレードすると、無制限の請求書とプレミアムテンプレートが利用できます。',
      'planFreeBody': '現在はフリープランをご利用中です。必要になったらいつでもアップグレードしてください。',
      'planPremiumBody': 'プレミアム特典をご利用いただきありがとうございます！',
      'firebaseBanner': 'Firebase認証が設定されていません。FIREBASE_API_KEY を設定してください。',
      'subscribeCrisp': 'Crispで購読',
      'manageSubscription': 'サブスクリプションを管理',
      'cancelSubscription': 'サブスクリプションを解約',
      'monthlyPrice': '月額料金',
      'planPriceLabel': '月額600円',
      'planPriceLabelLocalized': '{price}/月',
      'planBenefits': '特典',
      'planBenefitsBody': '無制限の請求書、プレミアムテンプレート、自動リマインダー。',
      'quickActions': 'クイックアクション',
      'createInvoiceAction': '請求書を作成',
      'viewInvoicesAction': '請求書一覧',
      'totalInvoices': '請求書総数',
      'outstanding': '未回収',
      'paid': '入金済み',
      'averageInvoice': '平均請求額',
      'recentInvoices': '最近の請求書',
      'invoicesEmptyTitle': '最初の請求書を作成しましょう',
      'invoicesEmptyBody': 'クライアント向けの請求書や領収書をすぐに生成できます。',
      'newInvoice': '新しい請求書',
      'editInvoice': '請求書を編集',
      'invoiceFormTitle': '請求書の詳細',
      'clientLabel': 'クライアント名',
      'projectLabel': '案件名',
      'descriptionLabel': '内容',
      'amountLabel': '金額',
      'invoiceNumberLabel': '請求書番号',
      'issueDateLabel': '発行日',
      'dueDateLabel': '支払期日',
      'notesLabel': 'メモ',
      'statusLabel': 'ステータス',
      'saveButton': '保存',
      'cancelButton': 'キャンセル',
      'deleteButton': '削除',
      'downloadPdf': 'PDFをダウンロード',
      'searchInvoices': '請求書を検索',
      'filterAll': 'すべて',
      'status_draft': '下書き',
      'status_sent': '送信済み',
      'status_paid': '入金済み',
      'status_overdue': '期限超過',
      'profileTitle': 'プロフィール',
      'profileDialogTitle': 'プロフィールを更新',
      'profileNameLabel': '氏名',
      'profileCompanyLabel': '会社名',
      'profileAddressLabel': '住所',
      'profilePhoneLabel': '電話番号',
      'profileTaxIdLabel': '税番号',
      'editProfile': 'プロフィールを編集',
      'profileUpdated': 'プロフィールを更新しました',
      'invoiceSaved': '請求書を保存しました',
      'invoiceDeleted': '請求書を削除しました',
      'pdfReady': 'PDFファイルをダウンロードできます。',
      'errorUnknown': '問題が発生しました。再度お試しください。',
      'firebaseMissing': 'Firebaseの設定が必要です。FIREBASE_API_KEYを設定してください。',
      'validationRequired': '必須項目です',
      'validationEmail': '有効なメールアドレスを入力してください',
      'validationPasswordLength': 'パスワードは6文字以上で入力してください',
      'validationPasswordMatch': 'パスワードが一致しません',
      'validationAmount': '正しい金額を入力してください',
      'signOut': 'サインアウト',
      'confirmSignOut': 'サインアウトしますか？',
      'confirm': '確認',
    }
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _lookup(String key) {
    final languageValues = _localizedValues[locale.languageCode] ??
        _localizedValues[AppLocalizations.supportedLocales.first.languageCode]!;
    return languageValues[key] ?? key;
  }

  String text(String key) => _lookup(key);

  String textWithReplacement(String key, Map<String, String> values) {
    var result = _lookup(key);
    values.forEach((placeholder, replacement) {
      result = result.replaceAll('{$placeholder}', replacement);
    });
    return result;
  }

  String invoiceStatusLabel(InvoiceStatus status) => _lookup('status_${status.name}');

  NumberFormat currencyFormat(String currencyCode, String symbol) =>
      NumberFormat.currency(locale: locale.toLanguageTag(), name: currencyCode, symbol: symbol);

  DateFormat get dateFormat => DateFormat.yMMMd(locale.toLanguageTag());

  DateFormat get longDateFormat => DateFormat.yMMMMd(locale.toLanguageTag());
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.toLanguageTag();
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
