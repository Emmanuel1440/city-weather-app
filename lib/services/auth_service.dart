import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://127.0.0.1:8000/api";

class AuthService {

  Future<bool> login(String email, String password) async {

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'email': email,
        'password': password
      }),
    );

    if(response.statusCode == 200){

      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        data['token'],
      );

      return true;
    }

    return false;
  }

  Future<bool> register(
      String name,
      String email,
      String password
      ) async {

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password
      }),
    );

    return response.statusCode == 201;
  }

  Future<String?> getToken() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future logout() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
  }
}