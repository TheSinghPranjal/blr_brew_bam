import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/category_model.dart';

class CategoryRepository {
  static const _base =
      'https://5nysoztmt8.execute-api.us-west-1.amazonaws.com/default';

  static const _headers = {'Content-Type': 'application/json'};

  // ── Fetch all categories ───────────────────────────────────────────
  Future<List<ApiCategory>> fetchCategories() async {
    final uri = Uri.parse('$_base/fetchCategories');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('fetchCategories failed ${response.statusCode}: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Add a new category ─────────────────────────────────────────────
  Future<ApiCategory> addCategory(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base/addCategory');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('addCategory failed ${response.statusCode}: ${response.body}');
    }

    // Some APIs return the created object; fall back to the request body
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json.containsKey('category_id')) {
        return ApiCategory.fromJson(json);
      }
    } catch (_) {}

    // Construct from what we sent (optimistic)
    return ApiCategory.fromJson({...body});
  }

  // ── Edit a category (placeholder endpoint) ─────────────────────────
  Future<void> updateCategory(String id, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base/updateCategory');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({...body, 'category_id': id}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('updateCategory failed ${response.statusCode}: ${response.body}');
    }
  }
}
