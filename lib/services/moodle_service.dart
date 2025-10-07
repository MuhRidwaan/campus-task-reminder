import 'dart:convert';
import 'package:http/http.dart' as http;

class MoodleService {
  static const String _baseUrl = 'https://elearning.uai.ac.id';

  // Fungsi untuk login dan mendapatkan token
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final loginUrl = Uri.parse('$_baseUrl/login/token.php');

    final response = await http.post(loginUrl, body: {
      'username': username,
      'password': password,
      'service': 'moodle_mobile_app',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        // Jika login berhasil, ambil juga user ID
        final siteInfo = await getSiteInfo(data['token']);
        return {
          'token': data['token'],
          'userid': siteInfo['userid'],
        };
      } else {
        throw Exception(data['error'] ?? 'Token tidak ditemukan');
      }
    } else {
      throw Exception('Gagal terhubung ke server');
    }
  }

  // Fungsi untuk mendapatkan informasi user, terutama user ID
  static Future<Map<String, dynamic>> getSiteInfo(String token) async {
    final siteInfoUrl = Uri.parse(
        '$_baseUrl/webservice/rest/server.php?wstoken=$token&wsfunction=core_webservice_get_site_info&moodlewsrestformat=json');
    final response = await http.get(siteInfoUrl);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mendapatkan info user');
    }
  }

  // Fungsi untuk mengambil event kalender (tugas)
  static Future<List<dynamic>> getCalendarEvents(String token) async {
    final eventsUrl = Uri.parse(
        '$_baseUrl/webservice/rest/server.php?wstoken=$token&wsfunction=core_calendar_get_calendar_events&moodlewsrestformat=json');
    final response = await http.get(eventsUrl);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['events'] ?? [];
    } else {
      throw Exception('Gagal mengambil data kalender');
    }
  }

  // Fungsi untuk mengambil daftar mata kuliah
  static Future<List<dynamic>> getUserCourses(String token, int userid) async {
    final coursesUrl = Uri.parse(
        '$_baseUrl/webservice/rest/server.php?wstoken=$token&wsfunction=core_enrol_get_users_courses&userid=$userid&moodlewsrestformat=json');
    final response = await http.get(coursesUrl);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) ?? [];
    } else {
      throw Exception('Gagal mengambil daftar mata kuliah');
    }
  }
}
