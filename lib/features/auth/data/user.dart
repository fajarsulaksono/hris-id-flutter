/// Model pengguna terautentikasi (hasil `AuthUserResource` backend).
class User {
  const User({
    required this.id,
    required this.code,
    required this.fullName,
    required this.email,
    required this.username,
    this.companyId,
    this.companyName,
    this.departmentId,
    this.departmentName,
    this.jobLevelId,
    this.jobLevelName,
    this.jobTitleId,
    this.jobTitleName,
    this.roles = const [],
    this.abilities = const [],
    this.profilePhoto,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        companyId: json['company_id'] as String?,
        companyName: json['company_name'] as String?,
        departmentId: json['department_id'] as String?,
        departmentName: json['department_name'] as String?,
        jobLevelId: json['job_level_id'] as String?,
        jobLevelName: json['job_level_name'] as String?,
        jobTitleId: json['job_title_id'] as String?,
        jobTitleName: json['job_title_name'] as String?,
        roles: (json['roles'] as List?)?.cast<String>() ?? const [],
        abilities: (json['abilities'] as List?)?.cast<String>() ?? const [],
        profilePhoto: json['profile_photo'] as String?,
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String code;
  final String fullName;
  final String email;
  final String username;
  final String? companyId;
  final String? companyName;
  final String? departmentId;
  final String? departmentName;
  final String? jobLevelId;
  final String? jobLevelName;
  final String? jobTitleId;
  final String? jobTitleName;
  final List<String> roles;
  final List<String> abilities;
  final String? profilePhoto;
  final String? createdAt;

  /// Apakah user memiliki ability tertentu (mirror `Security::can` web).
  bool hasAbility(String ability) => abilities.contains(ability);
}