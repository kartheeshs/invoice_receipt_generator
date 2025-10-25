class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.companyName,
    required this.tagline,
    required this.address,
    required this.phone,
    required this.taxId,
    required this.logoUrl,
    required this.currencyCode,
    required this.currencySymbol,
  });

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? companyName,
    String? tagline,
    String? address,
    String? phone,
    String? taxId,
    String? logoUrl,
    String? currencyCode,
    String? currencySymbol,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      taxId: taxId ?? this.taxId,
      logoUrl: logoUrl ?? this.logoUrl,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  final String displayName;
  final String email;
  final String companyName;
  final String tagline;
  final String address;
  final String phone;
  final String taxId;
  final String logoUrl;
  final String currencyCode;
  final String currencySymbol;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'companyName': companyName,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'taxId': taxId,
      'logoUrl': logoUrl,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }
}
