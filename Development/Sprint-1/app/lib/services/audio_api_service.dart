import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/logger.dart';
import '../constants/app_config.dart';
import 'dart:html' as html show window, Blob, Url, FileReader;
import 'package:http_parser/http_parser.dart';

class AudioApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Helper method to fetch blob URL and convert to bytes (web only)
  /// Returns a map with 'bytes' and 'mimeType'
  static Future<Map<String, dynamic>> _fetchBlobAsBytes(String blobUrl) async {
    if (!kIsWeb) {
      throw UnsupportedError('Blob URLs are only supported on web');
    }

    // Fetch the blob using XHR
    final response = await html.window.fetch(blobUrl);
    final blob = await response.blob();

    // Get the MIME type from the blob
    final mimeType = blob.type;
    Logger.log('🌐 API Service: Blob MIME type: $mimeType');

    // Convert blob to bytes
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoadEnd.first;

    // FileReader.result is already a Uint8List in Dart's web implementation
    final result = reader.result as Uint8List;

    return {
      'bytes': result,
      'mimeType': mimeType,
    };
  }

  /// Process audio bytes (for web) and extract locations
  /// Returns a map with 'source' and 'destination' or null on error
  static Future<Map<String, dynamic>?> processAudioBytes(Uint8List audioBytes, String filename) async {
    try {
      Logger.log('🌐 API Service: Starting audio processing from bytes');
      Logger.log('🌐 API Service: Audio size: ${audioBytes.length} bytes');

      final uri = Uri.parse('$baseUrl/api/audio/process');
      Logger.log('🌐 API Service: Request URL: $uri');

      final request = http.MultipartRequest('POST', uri);
      Logger.log('🌐 API Service: Created multipart request');

      // Add the audio file from bytes
      Logger.log('🌐 API Service: Adding audio bytes to request...');
      final audioFile = http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: filename,
      );
      request.files.add(audioFile);
      Logger.log('🌐 API Service: Audio file added. Size: ${audioFile.length} bytes');

      // Send the request
      Logger.log('🌐 API Service: Sending request to backend...');
      final streamedResponse = await request.send();
      Logger.log('🌐 API Service: Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      Logger.log('🌐 API Service: Response body: ${response.body}');

      if (response.statusCode == 200) {
        Logger.log('🌐 API Service: Status 200 - Parsing JSON...');
        final jsonData = json.decode(response.body);
        Logger.log('🌐 API Service: Parsed JSON: $jsonData');

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final locations = jsonData['data']['locations'];
          Logger.log('🌐 API Service: ✅ Locations extracted successfully!');
          Logger.log('🌐 API Service: Source: ${locations['source']}');
          Logger.log('🌐 API Service: Destination: ${locations['destination']}');

          return {
            'source': locations['source'] ?? '',
            'destination': locations['destination'] ?? '',
            'original_text': locations['original_text'] ?? '',
          };
        } else {
          Logger.error('🌐 API Service: ❌ JSON structure unexpected: success=${jsonData['success']}, data=${jsonData['data']}');
        }
      } else {
        Logger.error('🌐 API Service: ❌ Non-200 status code: ${response.statusCode}');
        Logger.error('🌐 API Service: Response body: ${response.body}');
      }

      return null;
    } catch (e, stackTrace) {
      Logger.error('🌐 API Service: 💥 ERROR: $e');
      Logger.error('🌐 API Service: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Process audio file and extract locations
  /// Returns a map with 'source' and 'destination' or null on error
  static Future<Map<String, dynamic>?> processAudio(String audioFilePath) async {
    try {
      Logger.log('🌐 API Service: Starting audio processing');
      Logger.log('🌐 API Service: File path: $audioFilePath');

      final uri = Uri.parse('$baseUrl/api/audio/process');
      Logger.log('🌐 API Service: Request URL: $uri');

      final request = http.MultipartRequest('POST', uri);
      Logger.log('🌐 API Service: Created multipart request');

      // Add the audio file
      Logger.log('🌐 API Service: Adding audio file to request...');

      http.MultipartFile audioFile;

      if (kIsWeb && audioFilePath.startsWith('blob:')) {
        // On web, fetch the blob and convert to bytes
        Logger.log('🌐 API Service: Fetching blob URL...');
        final blobData = await _fetchBlobAsBytes(audioFilePath);
        final bytes = blobData['bytes'] as Uint8List;
        final mimeType = blobData['mimeType'] as String;

        Logger.log('🌐 API Service: Blob fetched. Size: ${bytes.length} bytes');
        Logger.log('🌐 API Service: Blob MIME type: $mimeType');

        // Parse MIME type (e.g., "audio/wav" -> MediaType('audio', 'wav'))
        final mimeTypeParts = mimeType.split('/');
        final type = mimeTypeParts.length > 0 ? mimeTypeParts[0] : 'audio';
        final subtype = mimeTypeParts.length > 1 ? mimeTypeParts[1] : 'wav';

        // Get file extension from MIME type
        final extension = subtype == 'webm' ? 'webm' : subtype == 'mpeg' ? 'mp3' : subtype;

        audioFile = http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'recording.$extension',
          contentType: MediaType(type, subtype),
        );
      } else {
        // On mobile/desktop, use fromPath
        audioFile = await http.MultipartFile.fromPath(
          'audio',
          audioFilePath,
        );
      }

      request.files.add(audioFile);
      Logger.log('🌐 API Service: Audio file added. Size: ${audioFile.length} bytes');

      // Send the request
      Logger.log('🌐 API Service: Sending request to backend...');
      final streamedResponse = await request.send();
      Logger.log('🌐 API Service: Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      Logger.log('🌐 API Service: Response body: ${response.body}');

      if (response.statusCode == 200) {
        Logger.log('🌐 API Service: Status 200 - Parsing JSON...');
        final jsonData = json.decode(response.body);
        Logger.log('🌐 API Service: Parsed JSON: $jsonData');

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final locations = jsonData['data']['locations'];
          Logger.log('🌐 API Service: ✅ Locations extracted successfully!');
          Logger.log('🌐 API Service: Source: ${locations['source']}');
          Logger.log('🌐 API Service: Destination: ${locations['destination']}');

          return {
            'source': locations['source'] ?? '',
            'destination': locations['destination'] ?? '',
            'original_text': locations['original_text'] ?? '',
          };
        } else {
          Logger.error('🌐 API Service: ❌ JSON structure unexpected: success=${jsonData['success']}, data=${jsonData['data']}');
        }
      } else {
        Logger.error('🌐 API Service: ❌ Non-200 status code: ${response.statusCode}');
        Logger.error('🌐 API Service: Response body: ${response.body}');
      }

      return null;
    } catch (e, stackTrace) {
      Logger.error('🌐 API Service: 💥 ERROR: $e');
      Logger.error('🌐 API Service: Stack trace: $stackTrace');
      return null;
    }
  }
}
