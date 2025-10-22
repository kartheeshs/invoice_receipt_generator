import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../l10n/app_localizations.dart';

class ProfileFormDialog extends StatefulWidget {
  const ProfileFormDialog({
    super.key,
    required this.profile,
    required this.onSubmit,
  });

  final UserProfile profile;
  final ValueChanged<UserProfile> onSubmit;

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _taxController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _companyController = TextEditingController(text: widget.profile.companyName);
    _addressController = TextEditingController(text: widget.profile.address);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _taxController = TextEditingController(text: widget.profile.taxId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.text('profileDialogTitle')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.text('profileNameLabel')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.text('validationRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(labelText: l10n.text('profileCompanyLabel')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: l10n.text('profileAddressLabel')),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l10n.text('profilePhoneLabel')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxController,
                decoration: InputDecoration(labelText: l10n.text('profileTaxIdLabel')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.text('cancelButton')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            widget.onSubmit(
              widget.profile.copyWith(
                displayName: _nameController.text.trim(),
                companyName: _companyController.text.trim(),
                address: _addressController.text.trim(),
                phone: _phoneController.text.trim(),
                taxId: _taxController.text.trim(),
              ),
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.text('saveButton')),
        ),
      ],
    );
  }
}
