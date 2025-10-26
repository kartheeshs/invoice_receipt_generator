import 'package:uuid/uuid.dart';

enum InvoiceStatus { draft, sent, paid, overdue }

enum InvoiceTemplate {
  waveBlue,
  corporateSlate,
  outlineLedger,
  monochromeAccent,
  emeraldStripe,
  serviceSummary,
  japaneseBusiness,
}

const Uuid _uuid = Uuid();

class InvoiceLineItem {
  const InvoiceLineItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  factory InvoiceLineItem.empty() {
    return InvoiceLineItem(
      id: _uuid.v4(),
      description: 'Service description',
      quantity: 1,
      unitPrice: 0,
    );
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] as String? ?? _uuid.v4(),
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final String? notes;

  double get total => quantity * unitPrice;

  InvoiceLineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    String? notes,
  }) {
    return InvoiceLineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      if (notes != null) 'notes': notes,
    };
  }
}

enum InvoiceSectionType {
  header,
  billing,
  project,
  lineItems,
  totals,
  notes,
  terms,
  advertisement,
  japaneseSummary,
  footer,
  custom,
}

enum InvoiceElementKind {
  text,
  multiline,
  amount,
  date,
  status,
  tagline,
  badge,
  custom,
}

enum InvoiceFieldBinding {
  invoiceTitle,
  invoiceNumber,
  projectName,
  clientName,
  clientAddress,
  clientCompany,
  description,
  notes,
  amountDue,
  dueDate,
  issueDate,
  status,
  companyName,
  companyAddress,
  companyPhone,
  companyTaxId,
  companyTagline,
  bankDetails,
  advertisementHeadline,
  advertisementBody,
  advertisementCta,
  footerNote,
  logoUrl,
  custom,
}

class InvoiceElement {
  const InvoiceElement({
    required this.id,
    required this.kind,
    required this.binding,
    this.labelKey,
    this.value = '',
    this.placeholder = '',
    this.metadata = const {},
  });

  factory InvoiceElement.fromJson(Map<String, dynamic> json) {
    InvoiceElementKind _kindFromString(String? value) {
      return InvoiceElementKind.values.firstWhere(
        (element) => element.name == value,
        orElse: () => InvoiceElementKind.custom,
      );
    }

    InvoiceFieldBinding _bindingFromString(String? value) {
      return InvoiceFieldBinding.values.firstWhere(
        (binding) => binding.name == value,
        orElse: () => InvoiceFieldBinding.custom,
      );
    }

    return InvoiceElement(
      id: json['id'] as String? ?? _uuid.v4(),
      kind: _kindFromString(json['kind'] as String?),
      binding: _bindingFromString(json['binding'] as String?),
      labelKey: json['labelKey'] as String?,
      value: json['value'] as String? ?? '',
      placeholder: json['placeholder'] as String? ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  final String id;
  final InvoiceElementKind kind;
  final InvoiceFieldBinding binding;
  final String? labelKey;
  final String value;
  final String placeholder;
  final Map<String, dynamic> metadata;

  InvoiceElement copyWith({
    InvoiceElementKind? kind,
    InvoiceFieldBinding? binding,
    String? labelKey,
    String? value,
    String? placeholder,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceElement(
      id: id,
      kind: kind ?? this.kind,
      binding: binding ?? this.binding,
      labelKey: labelKey ?? this.labelKey,
      value: value ?? this.value,
      placeholder: placeholder ?? this.placeholder,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'binding': binding.name,
      if (labelKey != null) 'labelKey': labelKey,
      'value': value,
      'placeholder': placeholder,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

class InvoiceSection {
  const InvoiceSection({
    required this.id,
    required this.type,
    this.titleKey,
    this.elements = const [],
    this.metadata = const {},
    this.isRemovable = false,
    this.supportsLineItems = false,
    this.supportsLogo = false,
  });

  factory InvoiceSection.fromJson(Map<String, dynamic> json) {
    InvoiceSectionType _typeFromString(String? value) {
      return InvoiceSectionType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => InvoiceSectionType.custom,
      );
    }

    final elementsData = json['elements'];
    final List<InvoiceElement> elements = [];
    if (elementsData is List) {
      for (final item in elementsData) {
        if (item is Map) {
          elements.add(InvoiceElement.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return InvoiceSection(
      id: json['id'] as String? ?? _uuid.v4(),
      type: _typeFromString(json['type'] as String?),
      titleKey: json['titleKey'] as String?,
      elements: elements,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      isRemovable: json['isRemovable'] as bool? ?? false,
      supportsLineItems: json['supportsLineItems'] as bool? ?? false,
      supportsLogo: json['supportsLogo'] as bool? ?? false,
    );
  }

  final String id;
  final InvoiceSectionType type;
  final String? titleKey;
  final List<InvoiceElement> elements;
  final Map<String, dynamic> metadata;
  final bool isRemovable;
  final bool supportsLineItems;
  final bool supportsLogo;

  InvoiceSection copyWith({
    String? id,
    InvoiceSectionType? type,
    String? titleKey,
    List<InvoiceElement>? elements,
    Map<String, dynamic>? metadata,
    bool? isRemovable,
    bool? supportsLineItems,
    bool? supportsLogo,
  }) {
    return InvoiceSection(
      id: id ?? this.id,
      type: type ?? this.type,
      titleKey: titleKey ?? this.titleKey,
      elements: elements ?? this.elements,
      metadata: metadata ?? this.metadata,
      isRemovable: isRemovable ?? this.isRemovable,
      supportsLineItems: supportsLineItems ?? this.supportsLineItems,
      supportsLogo: supportsLogo ?? this.supportsLogo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      if (titleKey != null) 'titleKey': titleKey,
      if (elements.isNotEmpty) 'elements': elements.map((element) => element.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
      'isRemovable': isRemovable,
      'supportsLineItems': supportsLineItems,
      'supportsLogo': supportsLogo,
    };
  }
}

class InvoiceDocument {
  const InvoiceDocument({required this.sections});

  factory InvoiceDocument.defaults(InvoiceTemplate template) {
    switch (template) {
      case InvoiceTemplate.japaneseBusiness:
        return InvoiceDocument(sections: _japaneseBusinessSections());
      case InvoiceTemplate.monochromeAccent:
        return InvoiceDocument(sections: _monochromeAccentSections());
      case InvoiceTemplate.corporateSlate:
        return InvoiceDocument(sections: _corporateSlateSections());
      case InvoiceTemplate.outlineLedger:
        return InvoiceDocument(sections: _outlineLedgerSections());
      case InvoiceTemplate.emeraldStripe:
        return InvoiceDocument(sections: _emeraldStripeSections());
      case InvoiceTemplate.serviceSummary:
        return InvoiceDocument(sections: _serviceSummarySections());
      case InvoiceTemplate.waveBlue:
      default:
        return InvoiceDocument(sections: _waveBlueSections());
    }
  }

  factory InvoiceDocument.fromJson(Map<String, dynamic> json) {
    final sectionsData = json['sections'];
    final List<InvoiceSection> sections = [];
    if (sectionsData is List) {
      for (final item in sectionsData) {
        if (item is Map) {
          sections.add(InvoiceSection.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return InvoiceDocument(sections: sections);
  }

  final List<InvoiceSection> sections;

  InvoiceDocument copyWith({List<InvoiceSection>? sections}) {
    return InvoiceDocument(sections: sections ?? this.sections);
  }

  InvoiceDocument updateElement(String elementId, InvoiceElement Function(InvoiceElement element) update) {
    final updatedSections = sections
        .map(
          (section) => section.elements.any((element) => element.id == elementId)
              ? section.copyWith(
                  elements: section.elements
                      .map((element) => element.id == elementId ? update(element) : element)
                      .toList(),
                )
              : section,
        )
        .toList();
    return copyWith(sections: updatedSections);
  }

  InvoiceDocument replaceSection(InvoiceSection replacement) {
    final updated = sections
        .map((section) => section.id == replacement.id ? replacement : section)
        .toList();
    return copyWith(sections: updated);
  }

  InvoiceDocument insertSection(InvoiceSection section, {int? index}) {
    final updated = [...sections];
    if (index != null && index >= 0 && index <= updated.length) {
      updated.insert(index, section);
    } else {
      updated.add(section);
    }
    return copyWith(sections: updated);
  }

  InvoiceDocument removeSection(String sectionId) {
    return copyWith(sections: sections.where((section) => section.id != sectionId).toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }

  static InvoiceSection templateForAddition(InvoiceSectionType type) {
    switch (type) {
      case InvoiceSectionType.notes:
        return InvoiceSection(
          id: _uuid.v4(),
          type: InvoiceSectionType.notes,
          titleKey: 'sectionNotesTitle',
          isRemovable: true,
          elements: [
            InvoiceElement(
              id: _uuid.v4(),
              kind: InvoiceElementKind.multiline,
              binding: InvoiceFieldBinding.notes,
              labelKey: 'notesLabel',
              placeholder: 'Add project notes or personalized message',
            ),
          ],
        );
      case InvoiceSectionType.terms:
        return InvoiceSection(
          id: _uuid.v4(),
          type: InvoiceSectionType.terms,
          titleKey: 'sectionTermsTitle',
          isRemovable: true,
          elements: [
            InvoiceElement(
              id: _uuid.v4(),
              kind: InvoiceElementKind.multiline,
              binding: InvoiceFieldBinding.footerNote,
              labelKey: 'termsLabel',
              placeholder: 'List payment terms, late fees, or delivery notes',
            ),
          ],
        );
      case InvoiceSectionType.advertisement:
        return InvoiceSection(
          id: _uuid.v4(),
          type: InvoiceSectionType.advertisement,
          titleKey: 'sectionAdTitle',
          isRemovable: true,
          elements: [
            InvoiceElement(
              id: _uuid.v4(),
              kind: InvoiceElementKind.text,
              binding: InvoiceFieldBinding.advertisementHeadline,
              labelKey: 'adHeadlineLabel',
              placeholder: 'Promote an add-on service or seasonal offer',
            ),
            InvoiceElement(
              id: _uuid.v4(),
              kind: InvoiceElementKind.multiline,
              binding: InvoiceFieldBinding.advertisementBody,
              labelKey: 'adBodyLabel',
              placeholder: 'Explain the value of your promotion in a sentence or two.',
            ),
            InvoiceElement(
              id: _uuid.v4(),
              kind: InvoiceElementKind.badge,
              binding: InvoiceFieldBinding.advertisementCta,
              labelKey: 'adCtaLabel',
              placeholder: 'Add call-to-action (e.g. “Book strategy call”)',
            ),
          ],
        );
      case InvoiceSectionType.custom:
      default:
        return InvoiceSection(
          id: _uuid.v4(),
          type: InvoiceSectionType.custom,
          titleKey: 'sectionCustomTitle',
          isRemovable: true,
          elements: [
            InvoiceElement(
              id: _uuid.v4(),
              kind: InvoiceElementKind.multiline,
              binding: InvoiceFieldBinding.custom,
              placeholder: 'Add additional information or instructions for your client.',
            ),
          ],
        );
    }
  }

  static List<InvoiceSection> _waveBlueSections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'spotlight'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.tagline,
            binding: InvoiceFieldBinding.companyTagline,
            labelKey: 'companyTaglineLabel',
            placeholder: 'Creative studio tagline',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceTitle,
            labelKey: 'invoiceTitleLabel',
            placeholder: 'Invoice',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: '#2024-001',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.status,
            binding: InvoiceFieldBinding.status,
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.billing,
        titleKey: 'billingDetailsTitle',
        metadata: const {'layout': 'spotlightGrid'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientName,
            labelKey: 'billToLabel',
            placeholder: 'Client name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: 'Client address and contact details',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Your company name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.companyAddress,
            placeholder: 'Company address and contact details',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.projectName,
            labelKey: 'projectLabel',
            placeholder: 'Project or engagement name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        titleKey: 'lineItemsTitle',
        supportsLineItems: true,
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'summaryPill'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.notes,
        metadata: const {'layout': 'thankYou'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.notes,
            placeholder: 'Add project notes or special instructions for your client.',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.terms,
        titleKey: 'sectionTermsTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.bankDetails,
            placeholder: 'Provide bank details or payment instructions.',
          ),
        ],
      ),
    ];
  }

  static List<InvoiceSection> _emeraldStripeSections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'emerald'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Ad4tech Material LLC',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.tagline,
            binding: InvoiceFieldBinding.companyTagline,
            placeholder: 'Engineering • Maintenance • Service',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: 'INV-005',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.status,
            binding: InvoiceFieldBinding.status,
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.project,
        metadata: const {'layout': 'pill'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.projectName,
            labelKey: 'projectLabel',
            placeholder: 'Site maintenance and repair',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.billing,
        titleKey: 'billingDetailsTitle',
        metadata: const {'layout': 'dualCard'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientCompany,
            labelKey: 'billToCompanyLabel',
            placeholder: 'Green Materials LLC',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientName,
            labelKey: 'billToContactLabel',
            placeholder: 'John Doe',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: 'Client address details',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Ad4tech Material LLC',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.companyAddress,
            placeholder: 'Company address and contact',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        titleKey: 'lineItemsTitle',
        supportsLineItems: true,
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'badge'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.terms,
        titleKey: 'sectionTermsTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.bankDetails,
            placeholder: 'Include bank transfer information and payment schedule.',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.notes,
        titleKey: 'sectionNotesTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.notes,
            placeholder: 'Add optional remarks, approvals, or signatures.',
          ),
        ],
      ),
    ];
  }

  static List<InvoiceSection> _corporateSlateSections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'pillar'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceTitle,
            labelKey: 'invoiceTitleLabel',
            placeholder: 'Invoice',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: 'INV-203',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.billing,
        titleKey: 'billingDetailsTitle',
        metadata: const {'layout': 'sidebarLedger'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientCompany,
            labelKey: 'billToCompanyLabel',
            placeholder: 'Client Information',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: 'Client address, email, phone',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Your Information',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.companyAddress,
            placeholder: 'Company address, email, phone',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        titleKey: 'lineItemsTitle',
        supportsLineItems: true,
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'table'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.notes,
        titleKey: 'sectionNotesTitle',
        metadata: const {'layout': 'remarks'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.notes,
            placeholder: 'Add payment remarks or instructions.',
          ),
        ],
      ),
    ];
  }

  static List<InvoiceSection> _monochromeAccentSections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'monochrome'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Your Company',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.tagline,
            binding: InvoiceFieldBinding.companyTagline,
            placeholder: 'Professional Services',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: 'INV-001',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.status,
            binding: InvoiceFieldBinding.status,
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.project,
        metadata: const {'layout': 'badge'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.projectName,
            labelKey: 'projectLabel',
            placeholder: 'Consulting engagement overview',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.billing,
        metadata: const {'layout': 'tallColumns'},
        titleKey: 'billingDetailsTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientCompany,
            labelKey: 'billToCompanyLabel',
            placeholder: 'Client organisation',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientName,
            labelKey: 'billToContactLabel',
            placeholder: 'Primary contact',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: 'Office address and contact info',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.companyAddress,
            placeholder: 'Your office address and contact info',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        supportsLineItems: true,
        titleKey: 'lineItemsTitle',
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'sidePanel'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.terms,
        titleKey: 'sectionTermsTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.bankDetails,
            placeholder: 'Wire transfer instructions, SWIFT / ABA codes, and payment window.',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.advertisement,
        titleKey: 'sectionAdTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.advertisementHeadline,
            placeholder: 'Extend your advisory program with quarterly workshops',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.advertisementBody,
            placeholder: 'Offer a packaged add-on directly from your invoice.',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.badge,
            binding: InvoiceFieldBinding.advertisementCta,
            placeholder: 'Schedule planning call',
          ),
        ],
        isRemovable: true,
      ),
    ];
  }

  static List<InvoiceSection> _outlineLedgerSections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'banner'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceTitle,
            labelKey: 'invoiceTitleLabel',
            placeholder: 'Invoice',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: 'No. 2024-001',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.billing,
        titleKey: 'billingDetailsTitle',
        metadata: const {'layout': 'ledger'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientName,
            labelKey: 'billToLabel',
            placeholder: 'Client name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: 'Client address and contact',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Company name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.companyAddress,
            placeholder: 'Company address and contact',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        titleKey: 'lineItemsTitle',
        supportsLineItems: true,
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'underline'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.notes,
        titleKey: 'sectionNotesTitle',
        metadata: const {'layout': 'notesBox'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.notes,
            placeholder: 'Write notes, discounts, or special instructions.',
          ),
        ],
      ),
    ];
  }

  static List<InvoiceSection> _serviceSummarySections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'service'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
            placeholder: 'Service Provider',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: 'Invoice #1058',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.billing,
        metadata: const {'layout': 'cardGrid'},
        titleKey: 'billingDetailsTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientName,
            labelKey: 'billToLabel',
            placeholder: 'Recipient name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: 'Recipient address and contact',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.projectName,
            labelKey: 'projectLabel',
            placeholder: 'For services rendered',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        titleKey: 'lineItemsTitle',
        supportsLineItems: true,
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'stacked'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.notes,
        titleKey: 'sectionNotesTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.notes,
            placeholder: 'Add summary, tax notes, or thank-you message.',
          ),
        ],
      ),
    ];
  }

  static List<InvoiceSection> _japaneseBusinessSections() {
    return [
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.header,
        metadata: const {'layout': 'japanese'},
        supportsLogo: true,
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceTitle,
            labelKey: 'japaneseTitleLabel',
            placeholder: '請求書 / INVOICE',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.invoiceNumber,
            labelKey: 'invoiceNumberLabel',
            placeholder: 'No. 0001',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.issueDate,
            labelKey: 'issueDateLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.japaneseSummary,
        metadata: const {'layout': 'summaryTable'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientCompany,
            labelKey: 'japaneseBillToCompanyLabel',
            placeholder: '御中 / Client company name',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.clientAddress,
            placeholder: '〒 Postal code, prefecture, ward, building',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.clientName,
            labelKey: 'japaneseBillToContactLabel',
            placeholder: '担当者名',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.date,
            binding: InvoiceFieldBinding.dueDate,
            labelKey: 'dueDateLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.lineItems,
        supportsLineItems: true,
        metadata: const {'layout': 'japanese'},
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.totals,
        metadata: const {'layout': 'japaneseTotals'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.amount,
            binding: InvoiceFieldBinding.amountDue,
            labelKey: 'amountDueLabel',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.footer,
        metadata: const {'layout': 'japaneseFooter'},
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyName,
            labelKey: 'companyNameLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.companyAddress,
            placeholder: '〒 Postal code, prefecture, ward, building',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyPhone,
            labelKey: 'phoneLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.text,
            binding: InvoiceFieldBinding.companyTaxId,
            labelKey: 'taxIdLabel',
          ),
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.bankDetails,
            labelKey: 'bankDetailsLabel',
            placeholder: '銀行名 / 支店名 / 口座種別 / 口座番号',
          ),
        ],
      ),
      InvoiceSection(
        id: _uuid.v4(),
        type: InvoiceSectionType.notes,
        titleKey: 'sectionNotesTitle',
        elements: [
          InvoiceElement(
            id: _uuid.v4(),
            kind: InvoiceElementKind.multiline,
            binding: InvoiceFieldBinding.notes,
            placeholder: '備考欄に必要事項を入力してください。',
          ),
        ],
      ),
    ];
  }
}

class InvoiceRevision {
  const InvoiceRevision({
    required this.id,
    required this.timestamp,
    required this.editor,
    required this.summary,
  });

  factory InvoiceRevision.fromJson(Map<String, dynamic> json) {
    return InvoiceRevision(
      id: json['id'] as String? ?? _uuid.v4(),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      editor: json['editor'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  final String id;
  final DateTime timestamp;
  final String editor;
  final String summary;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'editor': editor,
      'summary': summary,
    };
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.projectName,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.template,
    required this.document,
    required this.lineItems,
    this.notes = '',
    this.logoUrl,
    this.revisions = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    InvoiceStatus _statusFromString(String? value) {
      return InvoiceStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => InvoiceStatus.draft,
      );
    }

    InvoiceTemplate _templateFromString(String? value) {
      return InvoiceTemplate.values.firstWhere(
        (template) => template.name == value,
        orElse: () => InvoiceTemplate.waveBlue,
      );
    }

    final lineItemsData = json['lineItems'];
    final List<InvoiceLineItem> lineItems = [];
    if (lineItemsData is List) {
      for (final item in lineItemsData) {
        if (item is Map) {
          lineItems.add(InvoiceLineItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final revisionsData = json['revisions'];
    final List<InvoiceRevision> revisions = [];
    if (revisionsData is List) {
      for (final item in revisionsData) {
        if (item is Map) {
          revisions.add(InvoiceRevision.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final documentData = json['document'];
    final document = documentData is Map<String, dynamic>
        ? InvoiceDocument.fromJson(documentData)
        : InvoiceDocument.defaults(_templateFromString(json['template'] as String?));

    final invoice = Invoice(
      id: json['id'] as String? ?? _uuid.v4(),
      number: json['number'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currencyCode'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? '',
      issueDate: DateTime.tryParse(json['issueDate'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      status: _statusFromString(json['status'] as String?),
      template: _templateFromString(json['template'] as String?),
      document: document,
      lineItems: lineItems,
      notes: json['notes'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      revisions: revisions,
    );

    return invoice.copyWith(amount: invoice.amount).recalculateTotals();
  }

  factory Invoice.create({
    required String id,
    required String currencyCode,
    required String currencySymbol,
    InvoiceTemplate template = InvoiceTemplate.waveBlue,
  }) {
    final now = DateTime.now();
    return Invoice(
      id: id,
      number: '#${now.year}${now.month.toString().padLeft(2, '0')}$id',
      clientName: '',
      projectName: '',
      description: '',
      amount: 0,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      status: InvoiceStatus.draft,
      template: template,
      document: InvoiceDocument.defaults(template),
      lineItems: [InvoiceLineItem.empty()],
    );
  }

  Invoice copyWith({
    String? id,
    String? number,
    String? clientName,
    String? projectName,
    String? description,
    double? amount,
    String? currencyCode,
    String? currencySymbol,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    InvoiceTemplate? template,
    InvoiceDocument? document,
    List<InvoiceLineItem>? lineItems,
    String? notes,
    String? logoUrl,
    List<InvoiceRevision>? revisions,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      template: template ?? this.template,
      document: document ?? this.document,
      lineItems: lineItems ?? this.lineItems,
      notes: notes ?? this.notes,
      logoUrl: logoUrl ?? this.logoUrl,
      revisions: revisions ?? this.revisions,
    );
  }

  final String id;
  final String number;
  final String clientName;
  final String projectName;
  final String description;
  final double amount;
  final String currencyCode;
  final String currencySymbol;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final InvoiceTemplate template;
  final InvoiceDocument document;
  final List<InvoiceLineItem> lineItems;
  final String notes;
  final String? logoUrl;
  final List<InvoiceRevision> revisions;

  bool get isOverdue => status == InvoiceStatus.overdue;

  Invoice recalculateTotals() {
    final total = lineItems.fold<double>(0, (value, item) => value + item.total);
    return copyWith(amount: double.parse(total.toStringAsFixed(2)));
  }

  Invoice updateLineItems(List<InvoiceLineItem> items) {
    return copyWith(lineItems: items).recalculateTotals();
  }

  Invoice updateDocument(InvoiceDocument document) {
    return copyWith(document: document);
  }

  Invoice addRevision(InvoiceRevision revision) {
    return copyWith(revisions: [revision, ...revisions]);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'clientName': clientName,
      'projectName': projectName,
      'description': description,
      'amount': amount,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'template': template.name,
      'document': document.toJson(),
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'notes': notes,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (revisions.isNotEmpty) 'revisions': revisions.map((revision) => revision.toJson()).toList(),
    };
  }
}

extension InvoiceTemplateMetadata on InvoiceTemplate {
  String get labelKey {
    switch (this) {
      case InvoiceTemplate.waveBlue:
        return 'templateWaveBlue';
      case InvoiceTemplate.corporateSlate:
        return 'templateCorporateSlate';
      case InvoiceTemplate.outlineLedger:
        return 'templateOutlineLedger';
      case InvoiceTemplate.monochromeAccent:
        return 'templateMonochromeAccent';
      case InvoiceTemplate.emeraldStripe:
        return 'templateEmeraldStripe';
      case InvoiceTemplate.serviceSummary:
        return 'templateServiceSummary';
      case InvoiceTemplate.japaneseBusiness:
        return 'templateJapaneseBusiness';
    }
  }

  String get blurbKey {
    switch (this) {
      case InvoiceTemplate.waveBlue:
        return 'templateWaveBlueBlurb';
      case InvoiceTemplate.corporateSlate:
        return 'templateCorporateSlateBlurb';
      case InvoiceTemplate.outlineLedger:
        return 'templateOutlineLedgerBlurb';
      case InvoiceTemplate.monochromeAccent:
        return 'templateMonochromeAccentBlurb';
      case InvoiceTemplate.emeraldStripe:
        return 'templateEmeraldStripeBlurb';
      case InvoiceTemplate.serviceSummary:
        return 'templateServiceSummaryBlurb';
      case InvoiceTemplate.japaneseBusiness:
        return 'templateJapaneseBusinessBlurb';
    }
  }

  bool get isJapanese => this == InvoiceTemplate.japaneseBusiness;
}
