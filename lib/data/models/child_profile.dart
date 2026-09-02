class ChildProfile {
  final String id;
  final String userId;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String? allergyNotes;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChildProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.allergyNotes,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt
  });

  // JSON 파싱 함수
  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    birthDate: DateTime.parse(json['birth_date'] as String),
    gender: json['gender'] as String? ?? 'unspecified',
    allergyNotes: json['allergy_notes'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  // JSON 변환 함수
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'birth_date': '${birthDate.year}'
      '-${birthDate.month.toString().padLeft(2, '0')}'
      '-${birthDate.day.toString().padLeft(2, '0')}',
    'gender': gender,
    if (allergyNotes != null) 'allergy_notes': allergyNotes,
    if (avatarUrl != null) 'avatar_url': avatarUrl
  };

  // 복사 함수
  ChildProfile copyWith({
    String? name,
    DateTime? birthDate,
    String? gender,
    String? allergyNotes,
    String? avatarUrl
  }) => ChildProfile(
    id: id, userId: userId,
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    allergyNotes: allergyNotes ?? this.allergyNotes,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt
  );
}