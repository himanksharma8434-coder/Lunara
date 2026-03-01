// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  try {
    print('Testing connection to Supabase...');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final request = await client.getUrl(
        Uri.parse('https://iiftktwprnrtojbhscbw.supabase.co/auth/v1/health'));
    final response = await request.close();
    print('Status: ${response.statusCode}');
    print('Connection successful!');
  } catch (e) {
    print('Error: $e');
  }
}
