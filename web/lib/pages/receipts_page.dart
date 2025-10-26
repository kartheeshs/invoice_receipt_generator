import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/receipt.dart';
import '../state/app_state.dart';
import '../widgets/receipt_editor.dart';

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({
    super.key,
    required this.onDownloadReceipt,
    required this.onRequestSignIn,
  });

  final Future<void> Function(Receipt) onDownloadReceipt;
  final Future<void> Function() onRequestSignIn;

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final selectedReceipt = appState.selectedReceipt;
    final filteredReceipts = appState.receipts.where((receipt) {
      if (query.isEmpty) return true;
      return receipt.clientName.toLowerCase().contains(query) ||
          receipt.number.toLowerCase().contains(query) ||
          receipt.paymentReference.toLowerCase().contains(query);
    }).toList();

    final content = selectedReceipt == null
        ? _buildLibraryView(
            context: context,
            appState: appState,
            receipts: filteredReceipts,
          )
        : _buildEditorView(
            context: context,
            appState: appState,
            receipt: selectedReceipt,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.4),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: content,
      ),
    );
  }

  Widget _buildLibraryView({
    required BuildContext context,
    required AppState appState,
    required List<Receipt> receipts,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currencyFormat =
        l10n.currencyFormat(appState.profile.currencyCode, appState.profile.currencySymbol);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.text('receiptsTab'), style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(l10n.text('receiptEditorSubtitle'), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _startNewReceipt(appState),
              icon: const Icon(Icons.add),
              label: Text(l10n.text('newReceipt')),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                hintText: l10n.text('searchReceiptsPlaceholder'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: receipts.isEmpty
              ? _buildEmptyState(theme, l10n)
              : ListView.separated(
                  itemCount: receipts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    final fallbackNumber = receipt.number.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0');
                    final safeLength = receipt.clientName.isEmpty
                        ? 0
                        : receipt.clientName.length >= 2
                            ? 2
                            : 1;
                    final initials = receipt.clientName.isNotEmpty
                        ? receipt.clientName.substring(0, safeLength).toUpperCase()
                        : fallbackNumber.substring(0, 2);
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        title: Text(receipt.clientName.isEmpty ? receipt.number : receipt.clientName),
                        subtitle: Text(
                          '${receipt.number} • ${l10n.dateFormat.format(receipt.issueDate)}',
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(receipt.total),
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: l10n.text('downloadButton'),
                                  onPressed: () => _downloadReceipt(context, appState, receipt),
                                  icon: const Icon(Icons.download),
                                ),
                                IconButton(
                                  tooltip: l10n.text('deleteButton'),
                                  onPressed: () => _deleteReceipt(context, appState, receipt),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _selectReceipt(appState, receipt),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          foregroundColor: theme.colorScheme.primary,
                          child: Text(initials),
                        ),
                        dense: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fact_check_outlined, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(l10n.text('receiptsEmptyTitle'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            l10n.text('receiptsEmptyBody'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditorView({
    required BuildContext context,
    required AppState appState,
    required Receipt receipt,
  }) {
    final isNewDraft = !appState.receipts.any((item) => item.id == receipt.id);

    return ReceiptEditor(
      key: ValueKey(receipt.id),
      receipt: receipt,
      profile: appState.profile,
      isNewDraft: isNewDraft,
      onSave: (updated) async => _saveReceipt(appState, updated),
      onDelete: isNewDraft ? null : (updated) async => _deleteReceipt(context, appState, updated),
      onDownload: (updated) async => widget.onDownloadReceipt(updated),
      onClose: () => _closeEditor(appState),
      onRequestSignIn: widget.onRequestSignIn,
    );
  }

  void _startNewReceipt(AppState appState) {
    final receipt = appState.prepareReceipt();
    appState.selectReceipt(receipt);
  }

  void _selectReceipt(AppState appState, Receipt receipt) {
    appState.selectReceipt(receipt);
  }

  Future<void> _saveReceipt(AppState appState, Receipt receipt) async {
    appState.saveReceipt(receipt);
  }

  Future<void> _deleteReceipt(BuildContext context, AppState appState, Receipt receipt) async {
    appState.deleteReceipt(receipt.id);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.text('receiptDeleted'))));
    }
  }

  void _closeEditor(AppState appState) {
    appState.selectReceipt(null);
  }

  Future<void> _downloadReceipt(BuildContext context, AppState appState, Receipt receipt) async {
    try {
      await widget.onDownloadReceipt(receipt);
    } on AccessDeniedException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.text(error.reasonKey))));
      }
      await widget.onRequestSignIn();
    }
  }
}
