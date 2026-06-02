class ApiEndpoints {
  // ✅ BENAR — sesuai URL login yang Anda berikan
  static const String baseUrl = "https://gusti-edo.org/api/v1";

  static const String loginUser  = "$baseUrl/login"; // login user
  static const String loginAdmin = "$baseUrl/login-admin"; 
  static const String sampahTerkelola = "$baseUrl/sampah-terkelola"; // data sampah terkelola
  static const String sampahDiserahkan = "$baseUrl/sampah-diserahkan"; // data sampah diserahkan
}