class AdminModel {

  final int id;
  final String namaAdmin;
  final String emailAdmin;
  final String roleAdmin;

  AdminModel({
    required this.id,
    required this.namaAdmin,
    required this.emailAdmin,
    required this.roleAdmin,
  });

  factory AdminModel.fromJson(
      Map<String, dynamic> json) {

    return AdminModel(
      id: json['id'],
      namaAdmin: json['nama_admin'],
      emailAdmin: json['email_admin'],
      roleAdmin: json['role_admin'],
    );
  }
}