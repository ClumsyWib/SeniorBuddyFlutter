import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ------------------------------------------------------------------------
/// FILE: api_service.dart
/// PURPOSE: This is the "Bridge" between the Flutter App (Phone) and the Django Server.
/// Whenever the app needs to save data (like a new appointment) or get data (like a profile),
/// it calls a function in this file. This file then sends an "HTTP Request" over the internet
/// to the Django backend.
///
/// KEY CONCEPTS TO EXPLAIN IN EXAM:
/// 1. SharedPreferences: Used to securely save the "auth_token" locally on the device so the user stays logged in.
/// 2. async/await: Network requests take time. 'await' tells the app to pause and wait for the server's reply before continuing.
/// 3. JSON: The format used to send and receive data. 'jsonEncode' converts Dart objects to text, 'jsonDecode' converts text to Dart objects.
/// ------------------------------------------------------------------------

class ApiService {
  // CHANGE THIS based on your setup:
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://centrically-arumlike-olen.ngrok-free.dev/api',
  );

  // For real device: 'http://YOUR_IP:8000/api'

  // Get stored authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save authentication token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Save user ID
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  // Get user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Save senior ID (for senior mode)
  Future<void> saveSeniorId(int seniorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('senior_id', seniorId);
  }

  // Get senior ID
  Future<int?> getSeniorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('senior_id');
  }

  // Remove all stored data
  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('senior_id');
    await prefs.remove('is_senior_mode');
    await prefs.remove('senior_name');
  }

  // Get headers with authentication
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }


  // ==================== AUTHENTICATION ====================

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    required String phoneNumber,
  }) async {
    try {
      final url = '$baseUrl/auth/register/';
      print('🔵 Registering: $username at URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password,
          'first_name': firstName,
          'last_name': lastName,
          'user_type': userType,
          'phone_number': phoneNumber,
        }),
      );

      print('Response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        await saveUserId(data['user']['id']);
        print('🟢 Registration successful!');
        return {'success': true, 'data': data};
      } else {
        dynamic error;
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          error = 'Server returned non-JSON response (Status ${response.statusCode}). Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}';
        }
        print('🔴 Registration failed: $error');
        return {'success': false, 'error': error};
      }
    } catch (e) {
      print('🔴 Registration error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      print('🔵 Logging in: $username');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);

        String userType = data['user_type'] ?? '';

        return {
          'success': true,
          'token': data['token'],
          'role_handled_properly': true,
        };
      } else {
        print('🔴 Login failed');
        return {'success': false, 'error': 'Invalid credentials'};
      }
    } catch (e) {
      print('🔴 Login error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await getHeaders();
      await http.post(
        Uri.parse('$baseUrl/auth/logout/'),
        headers: headers,
      );
      await clearStorage();
      print('🟢 Logout successful');
      return {'success': true};
    } catch (e) {
      await clearStorage();
      return {'success': true};
    }
  }


  // ==================== USER ====================

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update current user profile. Pass only fields you want to change.
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (zipCode != null) body['zip_code'] = zipCode;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (emergencyContactName != null) body['emergency_contact_name'] = emergencyContactName;
      if (emergencyContactPhone != null) body['emergency_contact_phone'] = emergencyContactPhone;
      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      final err = response.body.isNotEmpty ? jsonDecode(response.body) : {'detail': 'Update failed'};
      return {'success': false, 'error': err};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update caretaker-specific profile data
  Future<Map<String, dynamic>> updateCaretakerProfile(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/caretakers/me/'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update volunteer-specific profile data
  Future<Map<String, dynamic>> updateVolunteerProfile(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/volunteers/me/'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update senior-specific profile data with optional photo.
  /// Usually called by the family member managing the senior.
  Future<Map<String, dynamic>> updateSeniorProfile(int id, Map<String, dynamic> data, {dynamic photoFile}) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'No token'};

      if (photoFile != null) {
        // Use MultipartRequest for photo upload
        var request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/seniors/$id/update/'));
        request.headers['Authorization'] = 'Token $token';
        
        // Add text fields
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add photo
        if (photoFile is String) {
          request.files.add(await http.MultipartFile.fromPath('photo', photoFile));
        } else if (photoFile is File) {
          request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(response.body)};
        } else {
          return {'success': false, 'error': 'Update failed: ${response.statusCode} - ${response.body}'};
        }
      } else {
        // Regular JSON request
        final headers = await getHeaders();
        final response = await http.patch(
          Uri.parse('$baseUrl/seniors/$id/update/'),
          headers: headers,
          body: jsonEncode(data),
        );
        if (response.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }
        return {'success': false, 'error': jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Get senior's own profile (for logged-in Senior)
  Future<Map<String, dynamic>> getSeniorProfileMe() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/senior/me/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfilePicture(String filePath) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'No token'};

      var request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/users/me/'));
      request.headers['Authorization'] = 'Token $token';
      request.files.add(await http.MultipartFile.fromPath('profile_picture', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Upload failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> removeProfilePicture() async {
    try {
      final headers = await getHeaders();
      final body = {'profile_picture': null};
      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Failed to remove photo'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== SENIOR PROFILES (For Family & Caretakers) ====================

  Future<Map<String, dynamic>> getSeniors() async {
    return await getList('seniors/');
  }

  Future<Map<String, dynamic>> getSeniorProfile(int seniorId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/seniors/$seniorId/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load senior profile'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCaretakerProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/caretakers/me/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load caretaker profile'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getVolunteerProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/volunteers/me/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load volunteer profile'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Connect a senior device using a 6-digit pair code.
  /// Also saves the auth_token returned from the server.
  Future<Map<String, dynamic>> connectSenior(String pairCode) async {
    try {
      print('🔵 Connecting senior with code: $pairCode');
      final response = await http.post(
        Uri.parse('$baseUrl/connect-senior/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pair_code': pairCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save connection details locally
        await saveToken(data['token']);
        await saveSeniorId(data['senior_id']);
        await setSeniorMode(true);
        await saveConnectedSeniorName(data['senior_name']);

        print('🟢 Senior connected successfully!');
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Connection failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Local Storage Helpers for Senior Mode
  Future<void> setSeniorMode(bool isSenior) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_senior_mode', isSenior);
  }

  Future<bool> isSeniorMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_senior_mode') ?? false;
  }

  Future<void> saveConnectedSeniorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('senior_name', name);
  }

  Future<String?> getConnectedSeniorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('senior_name');
  }

  Future<Map<String, dynamic>> createSenior({
    required String name,
    required int age,
    String? gender,
    String? medicalConditions,
    String? allergies,
    String? mobilityStatus,
    String? careLevel,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'name': name,
        'age': age,
        if (gender != null) 'gender': gender,
        if (medicalConditions != null) 'medical_conditions': medicalConditions,
        if (allergies != null) 'allergies': allergies,
        if (mobilityStatus != null) 'mobility_status': mobilityStatus,
        if (careLevel != null) 'care_level': careLevel,
      };

      print('🔵 POST /api/seniors/ - Body: ${jsonEncode(body)}');
      final response = await http.post(
        Uri.parse('$baseUrl/seniors/'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('🔵 POST /api/seniors/ - Status: ${response.statusCode}');
      print('🔵 POST /api/seniors/ - Response: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }

      dynamic errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (_) {
        errorData = response.body;
      }
      return {'success': false, 'error': errorData};
    } catch (e) {
      print('🔴 POST /api/seniors/ - Error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== CARE ASSIGNMENTS ====================

  Future<Map<String, dynamic>> getCareAssignments() async {
    return await getList('care-assignments/');
  }

  Future<Map<String, dynamic>> createCareAssignment({
    required int seniorId,
    required int caretakerId,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'senior': seniorId,
        'caretaker': caretakerId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/care-assignments/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAvailableCaretakers() async {
    return await getList('caretakers/available/');
  }



  // ==================== APPOINTMENTS ====================

  /// Parses API response as list. Handles both { results: [] } and raw list from Django.
  static List<dynamic> parseListResponse(dynamic data) {
    if (data == null) return [];
    if (data is List) return List<dynamic>.from(data);
    if (data is Map && data.containsKey('results')) return List<dynamic>.from(data['results'] as List);
    return [];
  }

  /// Generic GET for any Django API endpoint. Returns parsed list (handles pagination results).
  Future<Map<String, dynamic>> getList(String path) async {
    try {
      final urlStr = path.startsWith('http') ? path : '$baseUrl/$path';
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(urlStr), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': parseListResponse(data), 'raw': data};
      }
      return {'success': false, 'error': 'Failed to get data'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== CARE ASSIGNMENT ====================

  Future<Map<String, dynamic>> getCaretakerProfiles() async {
    return getList('caretakers/');
  }

  Future<Map<String, dynamic>> assignCaretaker({
    required int seniorId,
    required int caretakerId,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/care-assignments/'),
        headers: headers,
        body: jsonEncode({
          'senior': seniorId,
          'caretaker': caretakerId,
          'start_date': DateTime.now().toLocal().toIso8601String().split('T')[0],
          'is_active': true,
        }),
      );
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAppointments({int? seniorId}) async {
    try {
      print('🔵 Fetching appointments...');
      final headers = await getHeaders();
      String url = '$baseUrl/appointments/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = parseListResponse(data);
        print('🟢 Got ${list.length} appointments');
        return {'success': true, 'data': list};
      } else {
        return {'success': false, 'error': 'Failed to get appointments'};
      }
    } catch (e) {
      print('🔴 Error getting appointments: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUpcomingAppointments({int? seniorId}) async {
    try {
      print('🔵 Fetching upcoming appointments...');
      final headers = await getHeaders();
      String url = '$baseUrl/appointments/upcoming/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🟢 Status: ${response.statusCode} Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = parseListResponse(data);
        print('🟢 Parsed ${list.length} upcoming appointments');
        return {'success': true, 'data': list};
      } else {
        return {'success': false, 'error': 'Failed to get appointments'};
      }
    } catch (e) {
      print('🔴 Error getting upcoming appointments: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> createAppointment({
    required int seniorId,
    required String title,
    required String appointmentType,
    required String appointmentDate,
    required String appointmentTime,
    required String location,
    String? doctorName,
    String? description,
  }) async {
    try {
      print('🔵 Creating appointment...');
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/'),
        headers: headers,
        body: jsonEncode({
          'senior': seniorId,
          'title': title,
          'appointment_type': appointmentType,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'location': location,
          if (doctorName != null && doctorName.isNotEmpty) 'doctor_name': doctorName,
          if (description != null && description.isNotEmpty) 'description': description,
          'duration_minutes': 30,
          'status': 'scheduled',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('🟢 Appointment created!');
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        print('🔴 Failed to create: $error');
        return {'success': false, 'error': error};
      }
    } catch (e) {
      print('🔴 Error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update appointment (date, time, title, etc.). Pass only fields to change.
  Future<Map<String, dynamic>> updateAppointment(int id, {
    String? title,
    String? appointmentType,
    String? appointmentDate,
    String? appointmentTime,
    String? location,
    String? doctorName,
    String? description,
    int? durationMinutes,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (appointmentType != null) body['appointment_type'] = appointmentType;
      if (appointmentDate != null) body['appointment_date'] = appointmentDate;
      if (appointmentTime != null) body['appointment_time'] = appointmentTime;
      if (location != null) body['location'] = location;
      if (doctorName != null) body['doctor_name'] = doctorName;
      if (description != null) body['description'] = description;
      if (durationMinutes != null) body['duration_minutes'] = durationMinutes;
      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$id/'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final err = response.body.isNotEmpty ? jsonDecode(response.body) : {'detail': 'Update failed'};
      return {'success': false, 'error': err};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Set appointment status: 'scheduled' | 'completed' | 'cancelled'
  Future<Map<String, dynamic>> updateAppointmentStatus(int id, String status) async {
    try {
      final headers = await getHeaders();
      String endpoint = '';
      if (status == 'completed') endpoint = 'complete';
      else if (status == 'cancelled') endpoint = 'cancel';
      else if (status == 'confirmed') endpoint = 'confirm';

      if (endpoint.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$baseUrl/appointments/$id/$endpoint/'),
          headers: headers,
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }
        final err = response.body.isNotEmpty ? jsonDecode(response.body) : {'detail': 'Action failed'};
        return {'success': false, 'error': err};
      }

      // Fallback for other arbitrary status updates
      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$id/'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final err = response.body.isNotEmpty ? jsonDecode(response.body) : {'detail': 'Update failed'};
      return {'success': false, 'error': err};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== MEDICINES ====================

  Future<Map<String, dynamic>> getMedicines({int? seniorId}) async {
    try {
      print('🔵 Fetching medicines...');
      final headers = await getHeaders();
      String url = '$baseUrl/medicines/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = parseListResponse(data);
        print('🟢 Got ${list.length} medicines');
        return {'success': true, 'data': list};
      } else {
        return {'success': false, 'error': 'Failed to get medicines'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getActiveMedicines({int? seniorId}) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/medicines/active/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get medicines'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Add a medicine (if Django API supports POST on medicines).
  Future<Map<String, dynamic>> createMedicine({
    required int seniorId,
    required String medicineName,
    required String dosage,
    String? frequency,
    String? timeOfDay,
    String? instructions,
    String? startDate,
    String? endDate,
    bool isActive = true,
  }) async {
    try {
      print('🔵 Creating medicine...');
      print('   Senior ID: $seniorId');
      print('   Medicine: $medicineName');
      print('   Dosage: $dosage');

      final headers = await getHeaders();
      final body = {
        'senior': seniorId,  // This is the key - must match Django model
        'medicine_name': medicineName,
        'dosage': dosage,
        'is_active': isActive,
        // Ensure frequency and start_date are sent since Django requires them
        'frequency': (frequency != null && frequency.isNotEmpty) ? frequency : 'daily',
      };

      if (timeOfDay != null && timeOfDay.isNotEmpty) {
        body['time_of_day'] = timeOfDay;
      }
      if (instructions != null && instructions.isNotEmpty) {
        body['instructions'] = instructions;
      }

      if (startDate != null && startDate.isNotEmpty) {
        body['start_date'] = startDate;
      } else {
        final now = DateTime.now();
        body['start_date'] = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }
      if (endDate != null && endDate.isNotEmpty) {
        body['end_date'] = endDate;
      }

      print('📤 Sending to: $baseUrl/medicines/');
      print('📦 Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/medicines/'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('🟢 Medicine created successfully!');
        return {'success': true, 'data': jsonDecode(response.body)};
      }

      final err = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'detail': 'Failed to add medicine'};
      print('🔴 Error: $err');
      return {'success': false, 'error': err};

    } catch (e) {
      print('🔴 Exception: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== EMERGENCY / CONTACTS (dynamic from Django) ====================

  /// Fetch emergency contacts from Django. Use any endpoint you register (e.g. emergency-contacts/, contacts/).
  Future<Map<String, dynamic>> getEmergencyContacts({int? seniorId}) async {
    String url = 'emergency-contacts/';
    if (seniorId != null) url += '?senior=$seniorId';
    final result = await getList(url);
    if (result['success'] == true) return result;
    return {'success': false, 'error': 'Failed to load custom contacts'};
  }

  Future<Map<String, dynamic>> createEmergencyContact({
    required String name,
    required String relationship,
    required String phone,
    int? seniorId,
    String? email,
    bool isPrimary = false,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'is_primary': isPrimary,
        'senior': seniorId,
      };
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/emergency-contacts/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== CARETAKER ====================

  Future<Map<String, dynamic>> getMyCaretaker({int? seniorId}) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/care-assignments/my_caretaker/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {'success': false, 'error': err['error'] ?? 'Failed to load caretaker'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== EMERGENCY ALERTS ====================

  Future<Map<String, dynamic>> createEmergencyAlert({
    required int seniorId,
    required String alertType,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      print('🔵 Creating emergency alert...');
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/emergency-alerts/'),
        headers: headers,
        body: jsonEncode({
          'senior': seniorId,
          'alert_type': alertType,
          if (location != null) 'location': location,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('🟢 Alert created!');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to create alert'};
      }
    } catch (e) {
      print('🔴 Error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }


  // ==================== VOLUNTEER TASKS ====================

  Future<Map<String, dynamic>> getTasks() async {
    try {
      print('🔵 Fetching tasks...');
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = parseListResponse(data);
        print('🟢 Got ${list.length} tasks');
        return {'success': true, 'data': list};
      } else {
        return {'success': false, 'error': 'Failed to get tasks'};
      }
    } catch (e) {
      print('🔴 Error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyTasks() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/my_tasks/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get tasks'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> acceptTask(int taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/accept/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to accept task'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeTask(int taskId, String notes) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/complete/'),
        headers: headers,
        body: jsonEncode({'notes': notes}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to complete task'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== NEW VOLUNTEER SYSTEM ====================

  // Help Requests
  Future<Map<String, dynamic>> getHelpRequests({String? status}) async {
    String url = 'help-requests/';
    if (status != null) url += '?status=$status';
    return await getList(url);
  }

  Future<Map<String, dynamic>> getMyHelpRequests() async {
    return await getList('help-requests/my_requests/');
  }

  Future<Map<String, dynamic>> createHelpRequest({
    required int seniorId,
    required String title,
    required String description,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/help-requests/'),
        headers: headers,
        body: jsonEncode({
          'senior': seniorId,
          'title': title,
          'description': description,
        }),
      );
      if (response.statusCode == 201) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> acceptHelpRequest(int id) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/help-requests/$id/accept/'), headers: headers);
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeHelpRequest(int id) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/help-requests/$id/complete/'), headers: headers);
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyHelpRequest(int id) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/help-requests/$id/verify/'), headers: headers);
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Volunteer Emergency
  Future<Map<String, dynamic>> getVolunteerEmergencies({String? status}) async {
    String url = 'emergency/';
    if (status != null) url += '?status=$status';
    return await getList(url);
  }

  Future<Map<String, dynamic>> triggerVolunteerEmergency(int? seniorId) async {
    try {
      final headers = await getHeaders();
      final body = seniorId != null ? jsonEncode({'senior': seniorId}) : jsonEncode({});
      final response = await http.post(Uri.parse('$baseUrl/emergency/'), headers: headers, body: body);
      if (response.statusCode == 201) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> acceptVolunteerEmergency(int id) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/emergency/$id/accept/'), headers: headers);
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Chat
  Future<Map<String, dynamic>> sendMessage(int receiverId, String message) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/messages/send/'),
        headers: headers,
        body: jsonEncode({'receiver': receiverId, 'message': message}),
      );
      if (response.statusCode == 201) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getConversation(int userId) async {
    try {
      final headers = await getHeaders();
      print('🔵 Fetching conversation with user $userId...');
      final response = await http.get(Uri.parse('$baseUrl/messages/$userId/'), headers: headers);
      print('🟢 Conversation Response (Status ${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': 'Failed to load messages (Status ${response.statusCode})'};
    } catch (e) {
      print('🔴 Connection error fetching conversation: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Rating
  Future<Map<String, dynamic>> giveRating(int volunteerId, int rating, String feedback, {int? helpRequestId, int? seniorId}) async {
    try {
      final headers = await getHeaders();
      final body = {
        'volunteer': volunteerId,
        'rating': rating,
        'feedback': feedback,
        if (helpRequestId != null) 'help_request': helpRequestId,
        if (seniorId != null) 'senior': seniorId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/rating/give_rating/'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getVolunteerDashboard() async {
    try {
      final headers = await getHeaders();
      print('🔵 Fetching volunteer dashboard...');
      final response = await http.get(Uri.parse('$baseUrl/volunteer/dashboard/'), headers: headers);
      print('🟢 Dashboard Response (Status ${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      return {'success': false, 'error': 'Failed to load dashboard (Status ${response.statusCode})'};
    } catch (e) {
      print('🔴 Connection error fetching dashboard: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }


  // ==================== DASHBOARD STATS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔵 Fetching dashboard stats...');
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🟢 Got stats: $data');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get stats'};
      }
    } catch (e) {
      print('🔴 Error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }


  // ==================== NOTIFICATIONS ====================

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': parseListResponse(data)};
      } else {
        return {'success': false, 'error': 'Failed to get notifications'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get notifications'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/mark_read/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to mark as read'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
  // ==================== DOCTORS ====================

  Future<Map<String, dynamic>> getDoctors({int? seniorId}) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/doctors/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': parseListResponse(data)};
      } else {
        return {'success': false, 'error': 'Failed to get doctors'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> createDoctor({
    required int seniorId,
    required String name,
    String? specialty,
    String? phone,
    String? email,
    String? clinicAddress,
    String? notes,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'senior': seniorId,
        'name': name,
        'specialty': specialty ?? '',
        'phone': phone ?? '',
        'email': email ?? '',
        'clinic_address': clinicAddress ?? '',
        'notes': notes ?? '',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/doctors/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== HEALTH RECORDS ====================

  Future<Map<String, dynamic>> getHealthRecords({int? seniorId}) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/health-records/';
      if (seniorId != null) url += '?senior=$seniorId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': parseListResponse(data)};
      } else {
        return {'success': false, 'error': 'Failed to get health records'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> createHealthRecord({
    required int seniorId,
    required String bloodPressure,
    int? heartRate,
    double? temperature,
    int? bloodSugar,
    double? weight,
    int? oxygenLevel,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'senior': seniorId,
        'blood_pressure': bloodPressure,
        if (heartRate != null) 'heart_rate': heartRate,
        if (temperature != null) 'temperature': temperature,
        if (bloodSugar != null) 'blood_sugar': bloodSugar,
        if (weight != null) 'weight': weight,
        if (oxygenLevel != null) 'oxygen_level': oxygenLevel,
        'record_date': DateTime.now().toIso8601String().split('T')[0],
        'record_time': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health-records/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== DAILY ACTIVITIES (For Caretakers & Family) ====================

  Future<Map<String, dynamic>> getDailyActivities(int seniorId) async {
    return await getList('daily-activities/?senior_id=$seniorId');
  }

  Future<Map<String, dynamic>> createDailyActivity({
    required int seniorId,
    required String activityType,
    required String notes,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        'senior': seniorId,
        'activity_type': activityType,
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/daily-activities/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== 🔥 FIXED: REGENERATE PAIR CODE ====================

  Future<Map<String, dynamic>> regeneratePairCode(
      int seniorId, String password) async {
    try {
      print('🔵 Regenerating pair code for senior ID: $seniorId');

      final headers = await getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/seniors/$seniorId/regenerate_pair_code/'),
        headers: headers,
        body: jsonEncode({
          'password': password,
        }),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'pair_code': data['pair_code']?.toString() ?? '',
        };
      } else {
        dynamic error;
        try {
          error = jsonDecode(response.body);
        } catch (_) {
          error = response.body;
        }

        return {
          'success': false,
          'error': error['error'] ?? 'Failed to regenerate code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  // ==================== ALIAS HELPERS ====================

  Future<Map<String, dynamic>> getVolunteerTasks() => getTasks();

  // ==================== USER TYPE STORAGE ====================

  Future<void> saveUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', userType);
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
}

