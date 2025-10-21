import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_language.dart';
import '../models/invoice.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _invoices = _createSampleInvoices();
    if (_invoices.isNotEmpty) {
      _selectedInvoice = _invoices.first;
    }
  }

  final _uuid = const Uuid();

  late List<Invoice> _invoices;
  Invoice? _selectedInvoice;

  bool _isPremium = false;
  String? _subscriptionProvider;
  String? _subscriptionPlanName;
  AppLanguage _language = AppLanguage.japanese;
  int monthlyDownloadLimit = 3;
  int monthlyDownloadsUsed = 1;

  String businessName = '和式デザイン合同会社';
  String ownerName = '山田 太郎';
  String email = 'hello@example.jp';
  String phoneNumber = '03-1234-5678';
  String postalCode = '150-0002';
  String address = '東京都渋谷区渋谷1-2-3 さくらビル5F';

  bool autoNumberingEnabled = true;
  bool showJapaneseEra = false;
  bool sendReminderEmails = true;
  double defaultTaxRate = 0.1;

  List<Invoice> get invoices => List.unmodifiable(_invoices);

  Invoice? get selectedInvoice => _selectedInvoice;

  bool get isPremium => _isPremium;

  String? get subscriptionProvider => _subscriptionProvider;

  String? get subscriptionPlanName => _subscriptionPlanName;

  AppLanguage get language => _language;

  Locale get locale => _language.locale;

  bool get hasDownloadQuota => isPremium || monthlyDownloadsUsed < monthlyDownloadLimit;

  double get totalBilled => _sumFor((invoice) => invoice.status == InvoiceStatus.paid);

  double get outstandingAmount =>
      _sumFor((invoice) => invoice.status == InvoiceStatus.sent);

  double get overdueAmount => _sumFor((invoice) => invoice.isOverdue);

  double get draftTotal => _sumFor((invoice) => invoice.status == InvoiceStatus.draft);

  int get activeClients =>
      _invoices.map((invoice) => invoice.clientName).toSet().length;

  int get invoicesDueThisWeek {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return _invoices
        .where(
          (invoice) =>
              invoice.status != InvoiceStatus.paid &&
              invoice.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
              invoice.dueDate.isBefore(end),
        )
        .length;
  }

  double _sumFor(bool Function(Invoice invoice) test) {
    return _invoices
        .where(test)
        .fold<double>(0, (previousValue, invoice) => previousValue + invoice.total);
  }

  void selectInvoice(Invoice? invoice) {
    _selectedInvoice = invoice;
    notifyListeners();
  }

  void saveInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((element) => element.id == invoice.id);
    if (index == -1) {
      _invoices = [..._invoices, invoice];
    } else {
      final updated = [..._invoices];
      updated[index] = invoice;
      _invoices = updated;
    }
    _selectedInvoice = invoice;
    notifyListeners();
  }

  void deleteInvoice(String id) {
    _invoices = _invoices.where((invoice) => invoice.id != id).toList();
    if (_selectedInvoice?.id == id) {
      _selectedInvoice = _invoices.isNotEmpty ? _invoices.first : null;
    }
    notifyListeners();
  }

  void markAsPremium({String provider = 'manual', String? planName}) {
    _isPremium = true;
    monthlyDownloadLimit = 999;
    _subscriptionProvider = provider;
    _subscriptionPlanName = planName;
    notifyListeners();
  }

  void downgradeToFreePlan() {
    _isPremium = false;
    monthlyDownloadLimit = 3;
    _subscriptionProvider = null;
    _subscriptionPlanName = null;
    if (monthlyDownloadsUsed > monthlyDownloadLimit) {
      monthlyDownloadsUsed = monthlyDownloadLimit;
    }
    notifyListeners();
  }

  bool recordInvoiceDownload() {
    if (_isPremium) {
      return true;
    }
    if (monthlyDownloadsUsed >= monthlyDownloadLimit) {
      return false;
    }
    monthlyDownloadsUsed += 1;
    notifyListeners();
    return true;
  }

  void updateBusinessProfile({
    required String newBusinessName,
    required String newOwnerName,
    required String newEmail,
    required String newPhoneNumber,
    required String newPostalCode,
    required String newAddress,
  }) {
    businessName = newBusinessName.trim();
    ownerName = newOwnerName.trim();
    email = newEmail.trim();
    phoneNumber = newPhoneNumber.trim();
    postalCode = newPostalCode.trim();
    address = newAddress.trim();
    notifyListeners();
  }

  void updateLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }

  void updateAutoNumbering(bool value) {
    autoNumberingEnabled = value;
    notifyListeners();
  }

  void updateJapaneseEraDisplay(bool value) {
    showJapaneseEra = value;
    notifyListeners();
  }

  void updateReminderEmails(bool value) {
    sendReminderEmails = value;
    notifyListeners();
  }

  void updateDefaultTaxRate(double value) {
    defaultTaxRate = value;
    notifyListeners();
  }

  String createInvoiceId() => _uuid.v4();

  String generateInvoiceNumber() {
    if (!autoNumberingEnabled) {
      return '';
    }
    final now = DateTime.now();
    final monthKey = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final monthlyCount = _invoices
            .where((invoice) => invoice.number.startsWith('INV-$monthKey'))
            .length +
        1;
    return 'INV-$monthKey-${monthlyCount.toString().padLeft(3, '0')}';
  }

  List<Invoice> _createSampleInvoices() {
    final now = DateTime.now();
    final invoices = <Invoice>[
      Invoice(
        id: _uuid.v4(),
        number: 'INV-202405-001',
        clientName: '株式会社さくらテック',
        projectName: 'コーポレートサイト改修',
        issueDate: now.subtract(const Duration(days: 25)),
        dueDate: now.subtract(const Duration(days: 8)),
        status: InvoiceStatus.paid,
        taxRate: 0.1,
        billingEmail: 'accounting@sakura-tech.jp',
        downloadCount: 4,
        notes: '銀行振込のご対応ありがとうございました。',
        items: const [
          InvoiceItem(
            id: 'item-1',
            description: 'デザインリニューアル一式',
            quantity: 1,
            unitPrice: 350000,
          ),
          InvoiceItem(
            id: 'item-2',
            description: 'CMS テンプレート調整',
            quantity: 1,
            unitPrice: 120000,
          ),
        ],
      ),
      Invoice(
        id: _uuid.v4(),
        number: 'INV-202405-002',
        clientName: 'GREEN株式会社',
        projectName: 'ブランド撮影ディレクション',
        issueDate: now.subtract(const Duration(days: 12)),
        dueDate: now.add(const Duration(days: 5)),
        status: InvoiceStatus.sent,
        taxRate: 0.1,
        billingEmail: 'finance@green.co.jp',
        downloadCount: 2,
        notes: '請求書受領後、10営業日以内でのご入金をお願いいたします。',
        items: const [
          InvoiceItem(
            id: 'item-3',
            description: '撮影ディレクション費',
            quantity: 1,
            unitPrice: 180000,
          ),
          InvoiceItem(
            id: 'item-4',
            description: 'スタジオ手配・ロケハン',
            quantity: 1,
            unitPrice: 65000,
          ),
          InvoiceItem(
            id: 'item-5',
            description: '交通費・諸経費',
            quantity: 1,
            unitPrice: 15000,
          ),
        ],
      ),
      Invoice(
        id: _uuid.v4(),
        number: 'INV-202405-003',
        clientName: 'Hikari Apps',
        projectName: 'UI コンポーネント設計',
        issueDate: now.subtract(const Duration(days: 20)),
        dueDate: now.subtract(const Duration(days: 2)),
        status: InvoiceStatus.overdue,
        taxRate: 0.1,
        billingEmail: 'keiri@hikariapps.com',
        downloadCount: 1,
        notes: 'お支払期限を過ぎております。ご確認をお願いいたします。',
        items: const [
          InvoiceItem(
            id: 'item-6',
            description: 'UI デザイン制作',
            quantity: 1,
            unitPrice: 220000,
          ),
          InvoiceItem(
            id: 'item-7',
            description: 'デザインシステム設計ワークショップ',
            quantity: 1,
            unitPrice: 80000,
          ),
        ],
      ),
      Invoice(
        id: _uuid.v4(),
        number: 'INV-202405-004',
        clientName: '株式会社ミライ',
        projectName: 'ランディングページ制作',
        issueDate: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 20)),
        status: InvoiceStatus.draft,
        taxRate: 0.1,
        billingEmail: 'info@mirai.co.jp',
        notes: '原稿確定後に正式請求予定。',
        items: const [
          InvoiceItem(
            id: 'item-8',
            description: 'ディレクション費',
            quantity: 1,
            unitPrice: 60000,
          ),
          InvoiceItem(
            id: 'item-9',
            description: 'デザイン制作費',
            quantity: 1,
            unitPrice: 140000,
          ),
          InvoiceItem(
            id: 'item-10',
            description: 'コーディング費',
            quantity: 1,
            unitPrice: 90000,
          ),
        ],
      ),
    ];

    return invoices;
  }
}
