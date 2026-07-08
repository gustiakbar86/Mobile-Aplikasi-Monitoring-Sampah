class ApiEndpoints {
  // API Utama
  static const String baseUrl = "https://gusti-edo.org/api/v1";

  static const String loginUser  = "$baseUrl/login"; // login user
  static const String loginAdmin = "$baseUrl/login-admin"; // login admin
  static const String sampahTerkelola = "$baseUrl/sampah-terkelola"; // data sampah terkelola
  static const String sampahDiserahkan = "$baseUrl/sampah-diserahkan"; // data sampah diserahkan
  static const String masterData = "$baseUrl/master-data"; // data master (jenis sampah, lokasi, dll)
  static const String petugas = "$baseUrl/petugas"; // data petugas
  static const String registerPetugas = "$baseUrl/register"; // endpoint untuk registrasi petugas

  //laporan pengunjung
  static const String laporanPengunjung = "$baseUrl/laporan-pengunjung";

  // Master CRUD
  static const String masterLokasi = "$baseUrl/master/lokasi-asal";
  static const String masterJenis = "$baseUrl/master/jenis";
  static const String masterTujuan = "$baseUrl/master/tujuan-sampah";
  static const String masterInstansi = "$baseUrl/master/instansi"; // data master instansi

  // Dokumen (Berkas) & Export Laporan
  static const String dokumen = "$baseUrl/dokumen"; // CRUD dokumen
  static const String exportLaporan = "$baseUrl/export-laporan"; // unduh laporan excel
}