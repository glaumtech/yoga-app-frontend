/// Global prize-winner certificate branding (server PDF / Thymeleaf).
/// Field names match the planned Spring DTO (`camelCase`).
class CertificateTemplateModel {
  final int? id;
  final int? branchId;
  final String templateGender;
  final bool isActive;
  final bool deleted;
  final bool isDefault;
  final String subtitle;
  final String organizedByLine;
  final String organizerAssociationLine;
  final String coordinatedIntro;
  final String coordinatedName;
  final String signatureLabel1;
  final String signatureLabel2;
  final String signatureLabel3;
  final String signatureLabel4;
  final String footerText;

  final String subjectPronounMale;
  final String subjectPronounFemale;
  final String subjectPronounOther;
  final String subjectPronounDefault;

  final String possessivePronounMale;
  final String possessivePronounFemale;
  final String possessivePronounOther;
  final String possessivePronounDefault;

  final bool includeStageInWinLine;
  final bool showDedicatedStageLine;
  final String stageLinePrefix;

  /// Preset key understood by the server (e.g. DEFAULT, GRADIENT_GOLD, CUSTOM_IMAGE).
  final String backgroundPreset;
  final String backgroundImageUrl;
  final String accentColorHex;
  final String logoImageUrl;

  /// Editor UI: display name for this template (creation screen).
  final String templateName;

  /// e.g. prize_winner, participation, bonafide, custom
  final String certificateType;

  /// Main body: plain text or HTML from the template designer (server-defined).
  final String templateBody;

  const CertificateTemplateModel({
    this.id,
    this.branchId,
    this.templateGender = 'MALE',
    this.isActive = true,
    this.deleted = false,
    this.isDefault = false,
    this.subtitle = '',
    this.organizedByLine = '',
    this.organizerAssociationLine = '',
    this.coordinatedIntro = '',
    this.coordinatedName = '',
    this.signatureLabel1 = '',
    this.signatureLabel2 = '',
    this.signatureLabel3 = '',
    this.signatureLabel4 = '',
    this.footerText = '',
    this.subjectPronounMale = '',
    this.subjectPronounFemale = '',
    this.subjectPronounOther = '',
    this.subjectPronounDefault = '',
    this.possessivePronounMale = '',
    this.possessivePronounFemale = '',
    this.possessivePronounOther = '',
    this.possessivePronounDefault = '',
    this.includeStageInWinLine = true,
    this.showDedicatedStageLine = false,
    this.stageLinePrefix = '',
    this.backgroundPreset = 'DEFAULT',
    this.backgroundImageUrl = '',
    this.accentColorHex = '',
    this.logoImageUrl = '',
    this.templateName = '',
    this.certificateType = 'prize_winner',
    this.templateBody = '',
  });

  CertificateTemplateModel copyWith({
    int? id,
    int? branchId,
    String? templateGender,
    bool? isActive,
    bool? deleted,
    bool? isDefault,
    String? subtitle,
    String? organizedByLine,
    String? organizerAssociationLine,
    String? coordinatedIntro,
    String? coordinatedName,
    String? signatureLabel1,
    String? signatureLabel2,
    String? signatureLabel3,
    String? signatureLabel4,
    String? footerText,
    String? subjectPronounMale,
    String? subjectPronounFemale,
    String? subjectPronounOther,
    String? subjectPronounDefault,
    String? possessivePronounMale,
    String? possessivePronounFemale,
    String? possessivePronounOther,
    String? possessivePronounDefault,
    bool? includeStageInWinLine,
    bool? showDedicatedStageLine,
    String? stageLinePrefix,
    String? backgroundPreset,
    String? backgroundImageUrl,
    String? accentColorHex,
    String? logoImageUrl,
    String? templateName,
    String? certificateType,
    String? templateBody,
  }) {
    return CertificateTemplateModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      templateGender: templateGender ?? this.templateGender,
      isActive: isActive ?? this.isActive,
      deleted: deleted ?? this.deleted,
      isDefault: isDefault ?? this.isDefault,
      subtitle: subtitle ?? this.subtitle,
      organizedByLine: organizedByLine ?? this.organizedByLine,
      organizerAssociationLine:
          organizerAssociationLine ?? this.organizerAssociationLine,
      coordinatedIntro: coordinatedIntro ?? this.coordinatedIntro,
      coordinatedName: coordinatedName ?? this.coordinatedName,
      signatureLabel1: signatureLabel1 ?? this.signatureLabel1,
      signatureLabel2: signatureLabel2 ?? this.signatureLabel2,
      signatureLabel3: signatureLabel3 ?? this.signatureLabel3,
      signatureLabel4: signatureLabel4 ?? this.signatureLabel4,
      footerText: footerText ?? this.footerText,
      subjectPronounMale: subjectPronounMale ?? this.subjectPronounMale,
      subjectPronounFemale: subjectPronounFemale ?? this.subjectPronounFemale,
      subjectPronounOther: subjectPronounOther ?? this.subjectPronounOther,
      subjectPronounDefault:
          subjectPronounDefault ?? this.subjectPronounDefault,
      possessivePronounMale:
          possessivePronounMale ?? this.possessivePronounMale,
      possessivePronounFemale:
          possessivePronounFemale ?? this.possessivePronounFemale,
      possessivePronounOther:
          possessivePronounOther ?? this.possessivePronounOther,
      possessivePronounDefault:
          possessivePronounDefault ?? this.possessivePronounDefault,
      includeStageInWinLine:
          includeStageInWinLine ?? this.includeStageInWinLine,
      showDedicatedStageLine:
          showDedicatedStageLine ?? this.showDedicatedStageLine,
      stageLinePrefix: stageLinePrefix ?? this.stageLinePrefix,
      backgroundPreset: backgroundPreset ?? this.backgroundPreset,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
      templateName: templateName ?? this.templateName,
      certificateType: certificateType ?? this.certificateType,
      templateBody: templateBody ?? this.templateBody,
    );
  }

  factory CertificateTemplateModel.fromJson(Map<String, dynamic> json) {
    bool readBool(dynamic v, bool fallback) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
      return fallback;
    }

    String readStr(String key) => json[key]?.toString() ?? '';

    return CertificateTemplateModel(
      id: (json['id'] as num?)?.toInt(),
      branchId: (json['branchId'] as num?)?.toInt(),
      templateGender: readStr('templateGender').isEmpty
          ? 'MALE'
          : readStr('templateGender').toUpperCase(),
      isActive: readBool(json['isActive'], true),
      deleted: readBool(json['isDeleted'] ?? json['deleted'], false),
      isDefault: readBool(json['defaultTemplate'] ?? json['isDefault'], false),
      subtitle: readStr('subtitle'),
      organizedByLine: readStr('organizedByLine'),
      organizerAssociationLine: readStr('organizerAssociationLine'),
      coordinatedIntro: readStr('coordinatedIntro'),
      coordinatedName: readStr('coordinatedName'),
      signatureLabel1: readStr('signatureLabel1'),
      signatureLabel2: readStr('signatureLabel2'),
      signatureLabel3: readStr('signatureLabel3'),
      signatureLabel4: readStr('signatureLabel4'),
      footerText: readStr('footerText'),
      subjectPronounMale: readStr('subjectPronounMale'),
      subjectPronounFemale: readStr('subjectPronounFemale'),
      subjectPronounOther: readStr('subjectPronounOther'),
      subjectPronounDefault: readStr('subjectPronounDefault'),
      possessivePronounMale: readStr('possessivePronounMale'),
      possessivePronounFemale: readStr('possessivePronounFemale'),
      possessivePronounOther: readStr('possessivePronounOther'),
      possessivePronounDefault: readStr('possessivePronounDefault'),
      includeStageInWinLine: readBool(json['includeStageInWinLine'], true),
      showDedicatedStageLine: readBool(json['showDedicatedStageLine'], false),
      stageLinePrefix: readStr('stageLinePrefix'),
      backgroundPreset: readStr('backgroundPreset').isEmpty
          ? 'DEFAULT'
          : readStr('backgroundPreset'),
      backgroundImageUrl: readStr('backgroundImageUrl'),
      accentColorHex: readStr('accentColorHex'),
      logoImageUrl: readStr('logoImageUrl'),
      templateName: readStr('templateName'),
      certificateType: readStr('certificateType').isEmpty
          ? 'prize_winner'
          : readStr('certificateType'),
      templateBody: readStr('templateBody'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'isActive': isActive,
      'isDeleted': deleted,
      'defaultTemplate': isDefault,
      'templateName': templateName,
      'templateBody': templateBody,
    };
  }
}
