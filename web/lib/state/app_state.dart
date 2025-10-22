import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/invoice.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/crisp_service.dart';
import '../services/pdf_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required AppConfig config,
    FirebaseAuthService? authService,
    PdfService? pdfService,
    CrispService? crispService,
  })  : _config = config,
        _authService = authService ?? FirebaseAuthService(apiKey: config.firebaseApiKey),
        _pdfService = pdfService ?? PdfService(),
        _crispService = crispService ?? CrispService(config.crispSubscriptionUrl) {
    _profile = UserProfile(
      displayName: 'Guest',
      email: '',
      companyName: 'Freelance Studio',
      address: '1-2-3 Shibuya, Tokyo, Japan',
      phone: '+81 3-1234-5678',
      taxId: 'TAX-0001',
      currencyCode: config.currencyCode,
      currencySymbol: config.currencySymbol,
    );
    _invoices.addAll(_seedInvoices());
  }

  final AppConfig _config;
  final FirebaseAuthService _authService;
  final PdfService _pdfService;
  final CrispService _crispService;
  final List<Invoice> _invoices = [];

  final Uuid _uuid = const Uuid();

  AuthUser? _user;
  UserProfile _profile = const UserProfile(
    displayName: 'Guest',
    email: '',
    companyName: 'Freelance Studio',
    address: '1-2-3 Shibuya, Tokyo, Japan',
    phone: '+81 3-1234-5678',
    taxId: 'TAX-0001',
    currencyCode: 'JPY',
    currencySymbol: '¥',
  );
  Invoice? _selectedInvoice;
  Locale _locale = const Locale('en');
  bool _isLoading = false;
  bool _isPremium = false;
  String? _errorMessage;

  Locale get locale => _locale;
  AuthUser? get user => _user;
  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  String? get errorMessage => _errorMessage;
  bool get hasFirebase => _config.hasFirebase;

  UnmodifiableListView<Invoice> get invoices => UnmodifiableListView(_invoices);
  Invoice? get selectedInvoice => _selectedInvoice;

  double get outstandingTotal => _invoices
      .where((invoice) => invoice.status != InvoiceStatus.paid)
      .fold(0, (total, invoice) => total + invoice.amount);

  double get paidTotal =>
      _invoices.where((invoice) => invoice.status == InvoiceStatus.paid).fold(0, (total, invoice) => total + invoice.amount);

  double get averageInvoice =>
      _invoices.isEmpty ? 0 : _invoices.map((invoice) => invoice.amount).reduce((a, b) => a + b) / _invoices.length;

  List<Invoice> get recentInvoices {
    final sorted = [..._invoices];
    sorted.sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return sorted.take(5).toList();
  }

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runAsync(() async {
      final user = await _authService.signIn(email: email, password: password);
      _user = await _authService.refreshUser(user);
      _profile = _profile.copyWith(email: _user!.email, displayName: _user!.displayName ?? _profile.displayName);
    });
  }

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _runAsync(() async {
      final user = await _authService.signUp(displayName: displayName, email: email, password: password);
      _user = user;
      _profile = _profile.copyWith(displayName: displayName, email: email);
    });
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email: email);
      _errorMessage = null;
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _user = null;
    _isPremium = false;
    _selectedInvoice = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void updateProfile(UserProfile profile) {
    _profile = profile;
    if (_user != null && profile.displayName.isNotEmpty) {
      _authService.updateProfile(idToken: _user!.idToken, displayName: profile.displayName);
    }
    notifyListeners();
  }

  Invoice prepareInvoice([Invoice? existing]) {
    return existing ??
        Invoice.create(
          id: _uuid.v4(),
          currencyCode: _profile.currencyCode,
          currencySymbol: _profile.currencySymbol,
        );
  }

  void saveInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((element) => element.id == invoice.id);
    if (index >= 0) {
      _invoices[index] = invoice;
    } else {
      _invoices.add(invoice);
    }
    _selectedInvoice = invoice;
    notifyListeners();
  }

  void deleteInvoice(String id) {
    _invoices.removeWhere((invoice) => invoice.id == id);
    if (_selectedInvoice?.id == id) {
      _selectedInvoice = null;
    }
    notifyListeners();
  }

  void selectInvoice(Invoice? invoice) {
    _selectedInvoice = invoice;
    notifyListeners();
  }

  Future<void> downloadInvoicePdf(Invoice invoice) async {
    await _pdfService.downloadInvoice(invoice: invoice, profile: _profile, locale: _locale);
  }

  void openSubscription() {
    _crispService.openSubscription();
  }

  void markPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    notifyListeners();
  }

  double get planPrice => _config.monthlyPlanPrice;

  List<Invoice> _seedInvoices() {
    final now = DateTime.now();
    return [
      Invoice(
        id: _uuid.v4(),
        number: '#INV-1001',
        clientName: 'Shibuya Design Co.',
        projectName: 'Brand identity refresh',
        description: 'Brand strategy and identity redesign services.',
        amount: 125000,
        currencyCode: _profile.currencyCode,
        currencySymbol: _profile.currencySymbol,
        issueDate: now.subtract(const Duration(days: 12)),
        dueDate: now.add(const Duration(days: 18)),
        status: InvoiceStatus.sent,
        notes: 'Payable within 30 days via bank transfer.',
      ),
      Invoice(
        id: _uuid.v4(),
        number: '#INV-1002',
        clientName: 'Osaka Startup Studio',
        projectName: 'Mobile app prototype',
        description: 'Clickable mobile prototype and user testing sessions.',
        amount: 98000,
        currencyCode: _profile.currencyCode,
        currencySymbol: _profile.currencySymbol,
        issueDate: now.subtract(const Duration(days: 35)),
        dueDate: now.subtract(const Duration(days: 5)),
        status: InvoiceStatus.paid,
        notes: 'Thank you for your business!',
      ),
    ];
  }

  Future<void> _runAsync(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
