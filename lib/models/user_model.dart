class UserModel {
  final int id;
  final String name;
  final String email;
  final int idInstansi;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.idInstansi,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      idInstansi: json['id_instansi'],
    );
  }
}