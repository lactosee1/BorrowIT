
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'hyesisoe';
  static const String uploadPreset = 'borrowit_equipment';

  static Future<String> uploadEquipmentImage(
      Uint8List imageBytes,
      String fileName,
      ) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
          '$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final result =
      jsonDecode(responseBody) as Map<String, dynamic>;

      return result['secure_url'] as String;
    }

    throw Exception('Image upload failed: $responseBody');
  }
}
