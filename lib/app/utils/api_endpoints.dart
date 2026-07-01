class ApiEndpoints {
  // API Utama
  static const String baseUrl = "https://gusti-edo.org/api/v1";

  static const String loginUser  = "$baseUrl/login"; // login user
  static const String loginAdmin = "$baseUrl/login-admin"; 
  static const String sampahTerkelola = "$baseUrl/sampah-terkelola"; // data sampah terkelola
  static const String sampahDiserahkan = "$baseUrl/sampah-diserahkan"; // data sampah diserahkan
  static const String masterData = "$baseUrl/master-data"; // data master (jenis sampah, lokasi, dll)
  static const String masterInstansi = "$baseUrl/master/instansi"; // data master instansi
  static const String petugas = "$baseUrl/petugas"; // data petugas
  static const String registerPetugas = "$baseUrl/register"; // endpoint untuk registrasi petugas
  // Master CRUD
  static const String masterLokasi = "$baseUrl/master/lokasi-asal";
  static const String masterJenis = "$baseUrl/master/jenis";
  static const String masterTujuan = "$baseUrl/master/tujuan-sampah";
}