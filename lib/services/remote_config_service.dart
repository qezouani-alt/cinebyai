import 'dart:convert';
import 'dart:io';

/// Retrieves the remote feature flag used to control the special button.
///
/// Requests fail closed: an unavailable, malformed, or incomplete response
/// never enables the button.
class RemoteConfigService {
  static const String remoteConfigUrl =
      'https://gist.githubusercontent.com/ELQEZOUANI/c1736f5d913a28bc8ab21b2e26e7a068/raw/config.json';
  static const Duration _timeout = Duration(seconds: 5);

  static Future<bool> shouldShowSpecialButton() async {
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      // A Gist Raw response can be cached briefly by a CDN. Adding this query
      // parameter keeps an edited flag from being delayed by a cached response.
      final uri = Uri.parse(remoteConfigUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final request = await client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        _debugLog('Request failed with HTTP ${response.statusCode}.');
        return false;
      }

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);
      final data = jsonDecode(body);
      final showButton =
          data is Map<String, dynamic> && data['show_special_button'] == true;
      _debugLog('Received show_special_button: $showButton.');
      return showButton;
    } catch (error) {
      _debugLog('Request failed: $error');
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static void _debugLog(String message) {
    assert(() {
      // ignore: avoid_print
      print('RemoteConfig: $message');
      return true;
    }());
  }
}
