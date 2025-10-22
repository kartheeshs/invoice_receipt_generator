class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.companyName,
    required this.address,
    required this.phone,
    required this.taxId,
    required this.currencyCode,
    required this.currencySymbol,
  });

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? companyName,
    String? address,
    String? phone,
    String? taxId,
    String? currencyCode,
    String? currencySymbol,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      taxId: taxId ?? this.taxId,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  final String displayName;
  final String email;
  final String companyName;
  final String address;
  final String phone;
  final String taxId;
  final String currencyCode;
  final String currencySymbol;
}
