import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({super.key});

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessController;
  late final TextEditingController _ownerController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _postalController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _businessController = TextEditingController(text: state.businessName);
    _ownerController = TextEditingController(text: state.ownerName);
    _emailController = TextEditingController(text: state.email);
    _phoneController = TextEditingController(text: state.phoneNumber);
    _postalController = TextEditingController(text: state.postalCode);
    _addressController = TextEditingController(text: state.address);
  }

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _postalController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.profileDialogTitle, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            l10n.profileDialogSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessController,
                  decoration: InputDecoration(labelText: l10n.businessNameLabel),
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerController,
                  decoration: InputDecoration(labelText: l10n.ownerLabel),
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.emailLabel, hintText: 'you@example.com'),
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: l10n.phoneLabel, hintText: '03-1234-5678'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postalController,
                  decoration: InputDecoration(labelText: l10n.postalCodeLabel, hintText: '123-4567'),
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: l10n.addressLabel),
                  maxLines: 2,
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.saveChanges),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final state = context.read<AppState>();
    state.updateBusinessProfile(
      newBusinessName: _businessController.text.trim(),
      newOwnerName: _ownerController.text.trim(),
      newEmail: _emailController.text.trim(),
      newPhoneNumber: _phoneController.text.trim(),
      newPostalCode: _postalController.text.trim(),
      newAddress: _addressController.text.trim(),
    );

    Navigator.of(context).pop(true);
  }
}
