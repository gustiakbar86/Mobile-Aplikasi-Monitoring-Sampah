class ApiEndpoints {
  // ✅ BENAR — sesuai URL login yang Anda berikan
  static const String baseUrl = "https://gusti-edo.org/api/v1";

  static const String loginUser  = "$baseUrl/login"; // login user
  static const String loginAdmin = "$baseUrl/login-admin"; 
  static const String laporSampah   = "$baseUrl/lapor-sampah";
  static const String jadwalPetugas = "$baseUrl/jadwal";
}