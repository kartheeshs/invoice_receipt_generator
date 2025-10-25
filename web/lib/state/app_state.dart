import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/invoice.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/crisp_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';

class AccessDeniedException implements Exception {
  const AccessDeniedException(this.reasonKey);

  final String reasonKey;

  @override
  String toString() => 'AccessDeniedException(reasonKey: $reasonKey)';
}

class ManagedAccount {
  const ManagedAccount({
    required this.id,
    required this.displayName,
    required this.email,
    this.isPremium = false,
    this.role = 'user',
    this.plan = 'Free',
    this.subscriptionSince,
  });

  final String id;
  final String displayName;
  final String email;
  final bool isPremium;
  final String role;
  final String plan;
  final DateTime? subscriptionSince;

  bool get hasAdminRole => role.toLowerCase() == 'admin';

  factory ManagedAccount.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'];
    final fallbackRole = (json['isAdmin'] as bool? ?? false) ? 'admin' : 'user';
    final resolvedRole = rawRole is String && rawRole.isNotEmpty ? rawRole : fallbackRole;
    final normalizedRole = resolvedRole.toLowerCase();
    return ManagedAccount(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
      role: normalizedRole == 'member' ? 'user' : normalizedRole,
      plan: json['plan'] as String? ?? 'Free',
      subscriptionSince: json['subscriptionSince'] is String && (json['subscriptionSince'] as String).isNotEmpty
          ? DateTime.tryParse(json['subscriptionSince'] as String)
          : null,
    );
  }

  ManagedAccount copyWith({
    String? id,
    String? displayName,
    String? email,
    bool? isPremium,
    String? role,
    String? plan,
    DateTime? subscriptionSince,
    bool clearSubscriptionSince = false,
  }) {
    return ManagedAccount(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      subscriptionSince: clearSubscriptionSince ? null : (subscriptionSince ?? this.subscriptionSince),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'isPremium': isPremium,
      'role': role,
      'plan': plan,
      if (subscriptionSince != null) 'subscriptionSince': subscriptionSince!.toIso8601String(),
    };
  }
}

class AppState extends ChangeNotifier {
  AppState({
    required AppConfig config,
    FirebaseAuthService? authService,
    PdfService? pdfService,
    CrispService? crispService,
    FirestoreService? firestoreService,
  })  : _config = config,
        _authService = authService ?? FirebaseAuthService(apiKey: config.firebaseApiKey),
        _pdfService = pdfService ?? PdfService(),
        _crispService = crispService ?? CrispService(config.crispSubscriptionUrl),
        _firestoreService = firestoreService ??
            FirestoreService(projectId: config.firebaseProjectId, apiKey: config.firebaseApiKey),
        _adminEmails = config.adminEmails.map((email) => email.toLowerCase()).toList() {
    _guestProfile = UserProfile(
      displayName: 'Guest',
      email: '',
      companyName: 'Freelance Studio',
      tagline: 'Global creative partner',
      address: '1-2-3 Shibuya, Tokyo, Japan',
      phone: '+81 3-1234-5678',
      taxId: 'TAX-0001',
      logoUrl: 'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?auto=format&fit=crop&w=160&q=80',
      currencyCode: config.currencyCode,
      currencySymbol: config.currencySymbol,
    );
    _profile = _guestProfile;
    _seedAccounts();
    _invoices.addAll(_seedInvoices());
  }

  final AppConfig _config;
  final FirebaseAuthService _authService;
  final PdfService _pdfService;
  final CrispService _crispService;
  final FirestoreService _firestoreService;
  final List<Invoice> _invoices = [];
  final List<ManagedAccount> _accounts = [];
  final List<String> _activityLog = [];
  final List<String> _adminEmails;

  final Uuid _uuid = const Uuid();

  late final UserProfile _guestProfile;
  AuthUser? _user;
  AuthUser? _adminUser;
  late UserProfile _profile;
  Invoice? _selectedInvoice;
  Locale _locale = const Locale('en');
  bool _isLocaleChanging = false;
  bool _isLoading = false;
  bool _isAdminLoading = false;
  bool _isPremium = false;
  String? _errorMessage;
  String? _adminErrorMessage;
  String? _adminErrorKey;

  Locale get locale => _locale;
  bool get isLocaleChanging => _isLocaleChanging;
  AuthUser? get user => _user;
  AuthUser? get adminUser => _adminUser;
  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAdminLoading => _isAdminLoading;
  bool get isPremium => _isPremium;
  bool get isAdmin {
    if (_adminUser != null) {
      return true;
    }
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      return false;
    }
    final account = _accountForEmail(email);
    return account?.hasAdminRole ?? false;
  }

  String? get errorMessage => _errorMessage;
  String? get adminErrorMessage => _adminErrorMessage;
  String? get adminErrorKey => _adminErrorKey;
  bool get hasFirebase => _config.hasFirebase;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user == null;

  UnmodifiableListView<Invoice> get invoices => UnmodifiableListView(_invoices);
  Invoice? get selectedInvoice => _selectedInvoice;
  UnmodifiableListView<ManagedAccount> get accounts => UnmodifiableListView(_accounts);
  UnmodifiableListView<String> get activityLog => UnmodifiableListView(_activityLog);

  List<InvoiceTemplate> get availableTemplates =>
      isGuest ? const [InvoiceTemplate.waveBlue, InvoiceTemplate.japaneseBusiness] : InvoiceTemplate.values;

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

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale || _isLocaleChanging) return;
    _isLocaleChanging = true;
    notifyListeners();
    try {
      await initializeDateFormatting(locale.toLanguageTag());
      _locale = locale;
      _persistState();
    } finally {
      _isLocaleChanging = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runAsync(() async {
      final user = await _authService.signIn(email: email, password: password);
      final role = await _loadRoleForUser(user);
      final refreshed = await _authService.refreshUser(user);
      _user = refreshed;
      if (_user == null) {
        return;
      }

      await _loadRemoteStateForUser(_user!);
      _ensureAccountFor(_user!, role: role);
      final account = _accountForEmail(_user!.email);
      if (account != null) {
        _isPremium = account.isPremium;
        if (account.displayName.isNotEmpty) {
          _profile = _profile.copyWith(displayName: account.displayName);
        }
      }

      _profile = _profile.copyWith(
        email: _user!.email,
        displayName: _user!.displayName ?? _profile.displayName,
      );
      _persistState();
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
      if (_user != null) {
        _ensureAccountFor(_user!, role: 'user');
        _assignDisplayName(_user!.email, displayName);
        final account = _accountForEmail(_user!.email);
        if (account != null) {
          _isPremium = account.isPremium;
        }
      }
      _profile = _profile.copyWith(displayName: displayName, email: email);
      _persistState();
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
    if (_user != null) {
      _persistState();
    }
    _user = null;
    _isPremium = false;
    _selectedInvoice = null;
    _profile = _guestProfile;
    notifyListeners();
  }

  Future<void> adminSignIn({required String email, required String password}) async {
    await _runAdminAsync(() async {
      final user = await _authService.signIn(email: email, password: password);
      final role = await _loadRoleForUser(user);
      if ((role ?? '').toLowerCase() != 'admin') {
        throw const AccessDeniedException('adminAccessDenied');
      }
      final refreshed = await _authService.refreshUser(user);
      _adminUser = refreshed;
      _ensureAccountFor(refreshed, role: role);
      _log('Admin ${refreshed.email} signed in');
      _persistState();
    });
  }

  void adminSignOut() {
    if (_adminUser == null) return;
    _adminUser = null;
    _persistState();
    notifyListeners();
  }

  void clearAdminError() {
    if (_adminErrorMessage == null && _adminErrorKey == null) {
      return;
    }
    _adminErrorMessage = null;
    _adminErrorKey = null;
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
      _assignDisplayName(_user!.email, profile.displayName);
    }
    _persistState();
    notifyListeners();
  }

  Invoice prepareInvoice([Invoice? existing]) {
    final invoice = existing ??
        Invoice.create(
          id: _uuid.v4(),
          currencyCode: _profile.currencyCode,
          currencySymbol: _profile.currencySymbol,
          template: availableTemplates.first,
        ).copyWith(logoUrl: _profile.logoUrl.isEmpty ? null : _profile.logoUrl);
    return invoice;
  }

  void saveInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((element) => element.id == invoice.id);
    final now = DateTime.now();
    if (index >= 0) {
      final previous = _invoices[index];
      var updated = invoice.copyWith(revisions: previous.revisions);
      if (_isPremium) {
        final revision = InvoiceRevision(
          id: _uuid.v4(),
          timestamp: now,
          editor: _profile.displayName.isNotEmpty ? _profile.displayName : 'You',
          summary: _summarizeInvoiceChanges(previous, invoice),
        );
        updated = invoice.addRevision(revision);
      }
      _invoices[index] = updated.recalculateTotals();
      _selectedInvoice = updated;
    } else {
      var created = invoice.recalculateTotals();
      if (_isPremium) {
        created = created.addRevision(InvoiceRevision(
          id: _uuid.v4(),
          timestamp: now,
          editor: _profile.displayName.isNotEmpty ? _profile.displayName : 'You',
          summary: 'Invoice created',
        ));
      }
      _invoices.add(created);
      _selectedInvoice = created;
    }
    notifyListeners();
    _persistState();
  }

  void deleteInvoice(String id) {
    _invoices.removeWhere((invoice) => invoice.id == id);
    if (_selectedInvoice?.id == id) {
      _selectedInvoice = null;
    }
    notifyListeners();
    _persistState();
  }

  void selectInvoice(Invoice? invoice) {
    _selectedInvoice = invoice;
    notifyListeners();
    _persistState();
  }

  Future<void> downloadInvoicePdf(Invoice invoice) async {
    if (isGuest) {
      throw const AccessDeniedException('downloadRequiresAccount');
    }
    await _pdfService.downloadInvoice(invoice: invoice, profile: _profile, locale: _locale);
  }

  void openSubscription() {
    _crispService.openSubscription();
  }

  void markPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    final account = _accountForEmail(_user?.email ?? '');
    if (account != null) {
      _updateAccount(account.copyWith(isPremium: value));
    }
    notifyListeners();
    _persistState();
  }

  void toggleAccountPremium(String accountId, bool value) {
    final index = _accounts.indexWhere((account) => account.id == accountId);
    if (index == -1) return;
    final account = _accounts[index].copyWith(
      isPremium: value,
      plan: value ? 'Pro' : 'Free',
      subscriptionSince: value ? (_accounts[index].subscriptionSince ?? DateTime.now()) : null,
      clearSubscriptionSince: !value,
    );
    _accounts[index] = account;
    _log('${account.displayName} premium status set to ${value ? 'enabled' : 'disabled'}');
    if (_user != null && account.email.toLowerCase() == _user!.email.toLowerCase()) {
      _isPremium = value;
    }
    notifyListeners();
    _persistState();
  }

  void toggleAccountAdmin(String accountId, bool value) {
    final index = _accounts.indexWhere((account) => account.id == accountId);
    if (index == -1) return;
    final account = _accounts[index].copyWith(role: value ? 'admin' : 'user');
    _accounts[index] = account;
    _log('${account.displayName} admin rights ${value ? 'granted' : 'revoked'}');
    notifyListeners();
    _persistState();
  }

  void removeAccount(String accountId) {
    final index = _accounts.indexWhere((account) => account.id == accountId);
    if (index == -1) return;
    final account = _accounts.removeAt(index);
    _log('Removed account for ${account.displayName}');
    notifyListeners();
    _persistState();
  }

  double get planPrice => _config.monthlyPlanPrice;

  void _persistState() {
    final currentUser = _user;
    if (currentUser == null || !_firestoreService.canQuery) {
      return;
    }

    final payload = _buildStateSnapshot();

    () async {
      try {
        await _firestoreService.saveUserState(
          uid: currentUser.uid,
          idToken: currentUser.idToken,
          data: payload,
        );
      } catch (_) {
        // Ignore persistence errors so they don't block the UI.
      }
    }();
  }

  Map<String, dynamic> _buildStateSnapshot() {
    return {
      'profile': _profile.toJson(),
      'isPremium': _isPremium,
      'invoices': _invoices.map((invoice) => invoice.toJson()).toList(),
      'accounts': _accounts.map((account) => account.toJson()).toList(),
      'activityLog': _activityLog,
      'locale': _locale.toLanguageTag(),
      'selectedInvoiceId': _selectedInvoice?.id,
    };
  }

  Future<void> _loadRemoteStateForUser(AuthUser user) async {
    if (!_firestoreService.canQuery) {
      return;
    }

    try {
      final snapshot = await _firestoreService.fetchUserState(
        uid: user.uid,
        idToken: user.idToken,
      );
      if (snapshot == null || snapshot.isEmpty) {
        return;
      }
      _applySnapshot(snapshot);
    } catch (_) {
      // Ignore fetch errors to keep authentication responsive.
    }
  }

  void _applySnapshot(Map<String, dynamic> decoded) {
    final localeTag = decoded['locale'] as String?;
    if (localeTag != null && localeTag.isNotEmpty) {
      _locale = _localeFromTag(localeTag);
    }

    final profileData = decoded['profile'];
    if (profileData is Map) {
      _profile = UserProfile.fromJson(Map<String, dynamic>.from(profileData));
    }

    final accountsData = decoded['accounts'];
    if (accountsData is List) {
      _accounts.clear();
      for (final item in accountsData) {
        if (item is Map) {
          _accounts.add(ManagedAccount.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    for (var i = 0; i < _accounts.length; i++) {
      final email = _accounts[i].email.toLowerCase();
      if (_adminEmails.contains(email) && !_accounts[i].hasAdminRole) {
        _accounts[i] = _accounts[i].copyWith(role: 'admin');
      }
    }

    final invoicesData = decoded['invoices'];
    if (invoicesData is List) {
      _invoices.clear();
      for (final item in invoicesData) {
        if (item is Map) {
          _invoices.add(Invoice.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final activityData = decoded['activityLog'];
    if (activityData is List) {
      _activityLog.clear();
      for (final entry in activityData) {
        if (entry is String) {
          _activityLog.add(entry);
        }
      }
    }

    _isPremium = decoded['isPremium'] as bool? ?? _isPremium;

    final selectedId = decoded['selectedInvoiceId'] as String?;
    if (selectedId != null && selectedId.isNotEmpty) {
      Invoice? match;
      for (final invoice in _invoices) {
        if (invoice.id == selectedId) {
          match = invoice;
          break;
        }
      }
      _selectedInvoice = match;
    } else {
      _selectedInvoice = null;
    }

  }

  Locale _localeFromTag(String tag) {
    final subtags = tag.split('-').where((part) => part.isNotEmpty).toList();
    if (subtags.isEmpty) {
      return const Locale('en');
    }
    final languageCode = subtags[0];
    String? scriptCode;
    String? countryCode;
    if (subtags.length == 2) {
      countryCode = subtags[1];
    } else if (subtags.length >= 3) {
      scriptCode = subtags[1];
      countryCode = subtags[2];
    }
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode?.isEmpty ?? true ? null : scriptCode,
      countryCode: countryCode?.isEmpty ?? true ? null : countryCode,
    );
  }

  List<Invoice> _seedInvoices() {
    final now = DateTime.now();

    final executiveItems = [
      InvoiceLineItem(
        id: _uuid.v4(),
        description: 'Brand strategy intensive',
        quantity: 1,
        unitPrice: 55000,
      ),
      InvoiceLineItem(
        id: _uuid.v4(),
        description: 'Visual identity exploration',
        quantity: 1,
        unitPrice: 42000,
      ),
      InvoiceLineItem(
        id: _uuid.v4(),
        description: 'Collateral production support',
        quantity: 1,
        unitPrice: 28000,
      ),
    ];

    final japaneseItems = [
      InvoiceLineItem(
        id: _uuid.v4(),
        description: 'モバイルアプリUIデザイン',
        quantity: 1,
        unitPrice: 68000,
      ),
      InvoiceLineItem(
        id: _uuid.v4(),
        description: 'ユーザビリティテストセッション（3回）',
        quantity: 3,
        unitPrice: 10000,
      ),
    ];

    final monochromeInvoice = Invoice(
      id: _uuid.v4(),
      number: '#INV-1001',
      clientName: 'Shibuya Design Co.',
      projectName: 'Brand identity refresh',
      description: 'Brand strategy and identity redesign services.',
      amount: 0,
      currencyCode: _profile.currencyCode,
      currencySymbol: _profile.currencySymbol,
      issueDate: now.subtract(const Duration(days: 12)),
      dueDate: now.add(const Duration(days: 18)),
      status: InvoiceStatus.sent,
      template: InvoiceTemplate.monochromeAccent,
      document: InvoiceDocument.defaults(InvoiceTemplate.monochromeAccent),
      lineItems: executiveItems,
      notes: 'Payable within 30 days via bank transfer.',
      logoUrl: _guestProfile.logoUrl,
    ).recalculateTotals();

    final japaneseInvoice = Invoice(
      id: _uuid.v4(),
      number: '#INV-1002',
      clientName: 'Osaka Startup Studio',
      projectName: 'モバイルアプリプロトタイプ',
      description: 'Clickable mobile prototype and user testing sessions.',
      amount: 0,
      currencyCode: _profile.currencyCode,
      currencySymbol: _profile.currencySymbol,
      issueDate: now.subtract(const Duration(days: 35)),
      dueDate: now.subtract(const Duration(days: 5)),
      status: InvoiceStatus.paid,
      template: InvoiceTemplate.japaneseBusiness,
      document: InvoiceDocument.defaults(InvoiceTemplate.japaneseBusiness),
      lineItems: japaneseItems,
      notes: 'お取引ありがとうございます。',
      logoUrl: _guestProfile.logoUrl,
    ).recalculateTotals();

    return [monochromeInvoice, japaneseInvoice];
  }

  void _seedAccounts() {
    _accounts.addAll([
      ManagedAccount(
        id: _uuid.v4(),
        displayName: 'Haruto Sato',
        email: 'haruto@example.com',
        isPremium: true,
        role: _adminEmails.contains('haruto@example.com') ? 'admin' : 'user',
        plan: 'Pro',
        subscriptionSince: DateTime.now().subtract(const Duration(days: 280)),
      ),
      ManagedAccount(
        id: _uuid.v4(),
        displayName: 'Aiko Tanaka',
        email: 'aiko@example.com',
        isPremium: false,
        role: _adminEmails.contains('aiko@example.com') ? 'admin' : 'user',
        plan: 'Free',
        subscriptionSince: null,
      ),
      ManagedAccount(
        id: _uuid.v4(),
        displayName: 'Liam Chen',
        email: 'liam@example.com',
        isPremium: true,
        role: _adminEmails.contains('liam@example.com') ? 'admin' : 'user',
        plan: 'Pro',
        subscriptionSince: DateTime.now().subtract(const Duration(days: 120)),
      ),
    ]);
  }

  void _ensureAccountFor(AuthUser user, {String? role}) {
    final email = user.email.toLowerCase();
    final index = _accounts.indexWhere((account) => account.email.toLowerCase() == email);
    final normalizedRole = role != null && role.isNotEmpty ? role.toLowerCase() : null;
    if (index == -1) {
      final fallbackRole = normalizedRole ?? (_adminEmails.contains(email) ? 'admin' : 'user');
      _accounts.add(ManagedAccount(
        id: user.uid.isNotEmpty ? user.uid : _uuid.v4(),
        displayName: user.displayName ?? user.email.split('@').first,
        email: user.email,
        isPremium: false,
        role: fallbackRole,
        plan: 'Free',
        subscriptionSince: null,
      ));
      return;
    }

    var updated = _accounts[index];
    if (user.uid.isNotEmpty && updated.id != user.uid) {
      updated = updated.copyWith(id: user.uid);
    }
    if (normalizedRole != null && updated.role != normalizedRole) {
      updated = updated.copyWith(role: normalizedRole);
    }
    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty && updated.displayName != displayName) {
      updated = updated.copyWith(displayName: displayName);
    }
    if (updated != _accounts[index]) {
      _accounts[index] = updated;
    }
  }

  ManagedAccount? _accountForEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    final lower = email.toLowerCase();
    for (final account in _accounts) {
      if (account.email.toLowerCase() == lower) {
        return account;
      }
    }
    return null;
  }

  void _assignDisplayName(String email, String displayName) {
    final index = _accounts.indexWhere((account) => account.email.toLowerCase() == email.toLowerCase());
    if (index == -1) return;
    _accounts[index] = _accounts[index].copyWith(displayName: displayName);
  }

  void _updateAccount(ManagedAccount account) {
    final index = _accounts.indexWhere((element) => element.id == account.id);
    if (index == -1) return;
    _accounts[index] = account;
  }

  Future<String?> _loadRoleForUser(AuthUser user) async {
    if (!_firestoreService.canQuery) {
      return null;
    }
    try {
      return await _firestoreService.fetchUserRole(uid: user.uid, idToken: user.idToken);
    } catch (_) {
      return null;
    }
  }

  String _summarizeInvoiceChanges(Invoice previous, Invoice next) {
    final changes = <String>[];
    if (previous.template != next.template) {
      changes.add('Template');
    }
    if (previous.status != next.status) {
      changes.add('Status');
    }
    if (previous.amount != next.amount) {
      changes.add('Amount');
    }
    if (previous.dueDate != next.dueDate) {
      changes.add('Due date');
    }
    if (previous.lineItems.length != next.lineItems.length) {
      changes.add('Line items');
    }
    if (previous.logoUrl != next.logoUrl) {
      changes.add('Logo');
    }
    if (changes.isEmpty) {
      changes.add('Layout updated');
    }
    return changes.join(', ');
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _activityLog.insert(0, '[$timestamp] $message');
    if (_activityLog.length > 50) {
      _activityLog.removeLast();
    }
    _persistState();
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

  Future<void> _runAdminAsync(Future<void> Function() action) async {
    _isAdminLoading = true;
    _adminErrorMessage = null;
    _adminErrorKey = null;
    notifyListeners();
    try {
      await action();
    } on AccessDeniedException catch (error) {
      _adminErrorKey = error.reasonKey;
    } on FirebaseAuthException catch (error) {
      _adminErrorMessage = error.message;
    } catch (error) {
      _adminErrorMessage = error.toString();
    } finally {
      _isAdminLoading = false;
      notifyListeners();
    }
  }
}
