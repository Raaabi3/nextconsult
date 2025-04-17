import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OutlookService with ChangeNotifier {
  final String serviceId = 'service_ieotd82';
  final String templateId = 'template_4b7fi3p';
  final String userId = 'rn2hN7qkQx90QqdGG';

  Future<bool> sendEmail({
    required String email,
    required String time,
    required int passcode,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': email,
          'time': time,
          'passcode': passcode.toString(),
        },
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Email to outlook sent successfully');
      return true;
    } else {
      print('❌ Email to outlook failed: ${response.body}');
      return false;
    }
  }
}
