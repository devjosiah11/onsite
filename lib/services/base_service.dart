import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'app_exceptions.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class BaseService {
  static const int TIME_OUT_DURATION = 90;

  Map? headers = {
    // 'content-type': 'application/json',
    'Accept': 'application/json',
  };
  static String? _token;

  static Future<void> getToken() async {
    final _storage = GetStorage();
    _token = _storage.read("access_token");
  }

  static Map<String, String> _getHeaders() {
    return {
      'content-type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Returns the current headers including authentication token
  static Future<Map<String, String>> getRequestHeaders() async {
    await getToken();
    return _getHeaders();
  }

  // Payload helper - returns a copy of the payload map
  Map<String, dynamic> _preparePayload(dynamic payloadObj) {
    return Map<String, dynamic>.from(payloadObj);
  }

  Future<dynamic> get(
    String baseUrl,
    String api, {
    Map<String, dynamic>? filters,
  }) async {
    await getToken();

    // Build query parameters correctly (only if filters provided)
    Uri uri = Uri.parse(baseUrl + api);
    if (filters != null && filters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: filters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    print("Final GET request URL: $uri");

    try {
      var response = await http
          .get(uri, headers: _getHeaders())
          .timeout(Duration(seconds: TIME_OUT_DURATION));

      print("main service file response is:  ${response.body}");
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
        'API not responded in time',
        uri.toString(),
      );
    }
  }

  // POST
  Future<dynamic> post(String baseUrl, String api, dynamic payloadObj) async {
    await getToken();
    var uri = Uri.parse(baseUrl + api);
    var payload = json.encode(_preparePayload(payloadObj));

    // Print the final URL
    print("Final POST request URL: ${uri.toString()}");
    print("POST payload: $payload");

    try {
      var response = await http
          .post(uri, headers: _getHeaders(), body: payload)
          .timeout(Duration(seconds: TIME_OUT_DURATION));
      print("POST response [${response.statusCode}]: ${response.body}");
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
        'API not responded in time',
        uri.toString(),
      );
    }
  }

  Future<dynamic> put(String baseUrl, String api, dynamic payloadObj) async {
    await getToken();
    var uri = Uri.parse(baseUrl + api);

    var payload = json.encode(_preparePayload(payloadObj));

    // Debugging output
    print("Final PUT request URL: ${uri.toString()}");
    print("Headers: ${_getHeaders()}");
    print("PUT payload: $payload");

    try {
      var response = await http
          .put(uri, headers: _getHeaders(), body: payload)
          .timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
        'API not responded in time',
        uri.toString(),
      );
    }
  }

  Future<dynamic> patch(String baseUrl, String api, dynamic payloadObj) async {
    await getToken();
    var uri = Uri.parse(baseUrl + api);

    var payload = json.encode(_preparePayload(payloadObj));

    // Debugging output
    print("Final PATCH request URL: ${uri.toString()}");
    print("Headers: ${_getHeaders()}");
    print("PATCH payload: $payload");

    try {
      var response = await http
          .patch(uri, headers: _getHeaders(), body: payload)
          .timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
        'API not responded in time',
        uri.toString(),
      );
    }
  }

  //DELETE
  Future<dynamic> delete(String baseUrl, String api, dynamic payloadObj) async {
    await getToken();
    var uri = Uri.parse(baseUrl + api);
    var payload = json.encode(payloadObj);

    // Print the final URL
    print("Final DELETE request URL: ${uri.toString()}");
    print("DELETE payload: $payload");

    try {
      var response = await http
          .delete(
            uri,
            headers: <String, String>{
              'content-type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: payload,
          )
          .timeout(const Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
        'API not responded in time',
        uri.toString(),
      );
    }
  } //OTHER

  dynamic _processResponse(http.Response response) {
    print(response.body);
    switch (response.statusCode) {
      case 200:
        return utf8.decode(response.bodyBytes);
      case 201:
        return utf8.decode(response.bodyBytes);
      case 204:
        return null;
      case 400:
        throw BadRequestException(
          response.body,
          response.request!.url.toString(),
        );
      case 401:
        _handleUnauthorized();
        throw UnAuthorizedException(
          response.body,
          response.request!.url.toString(),
        );
      case 403:
        throw UnAuthorizedException(
          response.body,
          response.request!.url.toString(),
        );
      case 404:
        throw FetchDataException(
          response.body,
          response.request!.url.toString(),
        );
      case 409:
        throw BadRequestException(
          response.body,
          response.request!.url.toString(),
        );
      case 422:
        throw BadRequestException(
          response.body,
          response.request!.url.toString(),
        );
      case 429:
        throw BadRequestException(
          response.body,
          response.request!.url.toString(),
        );
      case 500:
      default:
        throw FetchDataException(
          'Error occurred with code : ${response.statusCode}',
          response.request!.url.toString(),
        );
    }
  }

  void _handleUnauthorized() {
    print("Unauthorized access detected. Clearing session.");
    try {
      GetStorage().remove('access_token');
      GetStorage().remove('user');
      GetStorage().remove('user_role');
      Get.offAllNamed('/login');
    } catch (e) {
      print("Error during global logout: $e");
    }
  }
}
