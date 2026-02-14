class SponsorModel {
  final String? id;
  final String competitionId;
  final String competitionName;
  final int numberOfStudents;
  final String sponsorName;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String cellPhone;
  final String? whatsapp;
  final String email;
  final String? paymentMode;
  final double? amount;
  final String? paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SponsorModel({
    this.id,
    required this.competitionId,
    required this.competitionName,
    required this.numberOfStudents,
    required this.sponsorName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.cellPhone,
    this.whatsapp,
    required this.email,
    this.paymentMode,
    this.amount,
    this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) {
    return SponsorModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      competitionId: json['competitionId']?.toString() ??
          json['competition_id']?.toString() ??
          '',
      competitionName: json['competitionName']?.toString() ??
          json['competition_name']?.toString() ??
          '',
      numberOfStudents: json['numberOfStudents'] ??
          json['number_of_students'] ??
          0,
      sponsorName: json['sponsorName']?.toString() ??
          json['sponsor_name']?.toString() ??
          '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      cellPhone: json['cellPhone']?.toString() ??
          json['cell_phone']?.toString() ??
          '',
      whatsapp: json['whatsapp']?.toString(),
      email: json['email']?.toString() ?? '',
      paymentMode: json['paymentMode']?.toString() ??
          json['payment_mode']?.toString(),
      amount: json['amount'] != null
          ? (json['amount'] is num
              ? json['amount'].toDouble()
              : double.tryParse(json['amount'].toString()) ?? 0.0)
          : null,
      paymentStatus: json['paymentStatus']?.toString() ??
          json['payment_status']?.toString(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : json['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
              : null)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : json['updatedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
              : null)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    return {
      if (id != null && includeMetadata) 'id': id,
      'competitionId': competitionId,
      'competitionName': competitionName,
      'numberOfStudents': numberOfStudents,
      'sponsorName': sponsorName,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'cellPhone': cellPhone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      'email': email,
      if (paymentMode != null) 'paymentMode': paymentMode,
      if (amount != null) 'amount': amount,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (includeMetadata && createdAt != null)
        'createdAt': createdAt!.toIso8601String(),
      if (includeMetadata && updatedAt != null)
        'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  SponsorModel copyWith({
    String? id,
    String? competitionId,
    String? competitionName,
    int? numberOfStudents,
    String? sponsorName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? cellPhone,
    String? whatsapp,
    String? email,
    String? paymentMode,
    double? amount,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SponsorModel(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      competitionName: competitionName ?? this.competitionName,
      numberOfStudents: numberOfStudents ?? this.numberOfStudents,
      sponsorName: sponsorName ?? this.sponsorName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      cellPhone: cellPhone ?? this.cellPhone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      paymentMode: paymentMode ?? this.paymentMode,
      amount: amount ?? this.amount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

