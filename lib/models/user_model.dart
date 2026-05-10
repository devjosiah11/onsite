class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? studentIdNumber;
  final String institutionId;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.institutionId,
    this.studentIdNumber,
    this.isActive = true,
  });

  String get firstName => fullName.split(' ').first;

  bool get isStudent => role == 'STUDENT';
  bool get isLecturer => role == 'LECTURER';
  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'STUDENT',
      institutionId: json['institutionId'] as String? ?? json['institution_id'] as String? ?? '',
      studentIdNumber: json['studentIdNumber'] as String? ?? json['student_id_number'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role,
        'institutionId': institutionId,
        'studentIdNumber': studentIdNumber,
        'isActive': isActive,
      };
}
