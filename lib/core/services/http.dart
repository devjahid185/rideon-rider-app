import 'dart:async';
import 'dart:convert';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../../app/route_settings.dart';
import '../../presentation/cubits/logout_cubit.dart';
import '../../presentation/screens/Auth/login_screen.dart';
import '../utils/common_widget.dart';
import 'config.dart';
import 'data_store.dart';

bool connectionLost = false;
String latitudeGlobal = '';
String longitudeGlobal = '';
bool shouldLogout = false;

Future<void> _ensureBearerMatchesCurrentUser() async {
  final bearerUserToken =
      (box.get("bearerUserToken") ?? "").toString();
  if (bearerToken.isNotEmpty && bearerUserToken != token) {
    bearerToken = "";
    await box.delete("bearerToken");
    await box.delete("bearerUserToken");
  }
}

Future<dynamic> httpPost(path, data, {required BuildContext context}) async {
  try {
    String apiBaseUrl = Config.baseUrl;
    var url = apiBaseUrl + path;
    await _ensureBearerMatchesCurrentUser();
    if (bearerToken.isEmpty) {
      bearerToken = await generateToken() ?? "";
    }
    var headers = {
      'Content-Type': 'application/json',
      'x-auth-token': token,
      "Authorization": "Bearer $bearerToken",
    };

    data['module_id'] = "2";
    data['user_type'] = "user";
    if ((data['latitude'] == null || data['latitude'].toString().isEmpty) &&
        latitudeGlobal.isNotEmpty) {
      data['latitude'] = latitudeGlobal;
    }
    if ((data['longitude'] == null || data['longitude'].toString().isEmpty) &&
        longitudeGlobal.isNotEmpty) {
      data['longitude'] = longitudeGlobal;
    }

    data['token'] = token;

    if (path.toString() == Config.socialLogin) {
      debugPrint(
          "[HTTP][POST] socialLogin request | url=$url | hasBearer=${bearerToken.isNotEmpty} | hasUserToken=${token.isNotEmpty}");
      debugPrint(
          "[HTTP][POST] socialLogin payload keys=${data.keys.toList()}");
    }

    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    final rawBody = const Utf8Codec().decode(response.bodyBytes);
    dynamic responseData;
    try {
      responseData = json.decode(rawBody);
    } catch (_) {
      if (path.toString() == Config.socialLogin) {
        debugPrint(
            "[HTTP][POST] socialLogin non-JSON response | code=${response.statusCode} | body=${rawBody.length > 500 ? rawBody.substring(0, 500) : rawBody}");
      }
      responseData = {
        "status": response.statusCode,
        "error": "Invalid server response format",
        "raw_body": rawBody,
      };
    }

    if (path.toString() == Config.socialLogin) {
      debugPrint(
          "[HTTP][POST] socialLogin response | code=${response.statusCode} | parsedStatus=${responseData is Map ? responseData["status"] : null}");
    }

    if (response.statusCode == 498) {
      final newToken = await generateToken();
      if (newToken != null) {
        bearerToken = newToken;
        headers["Authorization"] = "Bearer $newToken";
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(data),
        );
        final retryRawBody = const Utf8Codec().decode(response.bodyBytes);
        try {
          responseData = json.decode(retryRawBody);
        } catch (_) {
          responseData = {
            "status": response.statusCode,
            "error": "Invalid server response format",
            "raw_body": retryRawBody,
          };
        }
      } else {
        return {"error": "Token regeneration failed"};
      }
    }

    if (response.statusCode == 419) {
      showErrorToastMessage("Session expired. Please log in again.");
      Future.delayed(const Duration(seconds: 1), () {
        clearData(navigatorKey.currentContext!);
        goToWithClear(const LoginScreen());
      });
    }

    return responseData;
  } catch (err) {
    if (path.toString() == Config.socialLogin) {
      debugPrint("[HTTP][POST] socialLogin exception: $err");
    }
    return {"error": "Something went wrong", "exception": err.toString()};
  }
}

Future<dynamic> httpGet(String path, Map<String, dynamic> data,
    {required BuildContext context}) async {
  dynamic responsegetData;
  try {
    String apiBaseUrl = Config.baseUrl;
    var url = apiBaseUrl + path;

    await _ensureBearerMatchesCurrentUser();
    if (bearerToken.isEmpty) {
      bearerToken = await generateToken() ?? "";
    }
    var headers = {
      'Content-Type': 'application/json',
      'x-auth-token': token,
      'Authorization': "Bearer $bearerToken",
    };
    data['module_id'] = "2";
    data['user_type'] = "user";
    if ((data['latitude'] == null || data['latitude'].toString().isEmpty) &&
        latitudeGlobal.isNotEmpty) {
      data['latitude'] = latitudeGlobal;
    }
    if ((data['longitude'] == null || data['longitude'].toString().isEmpty) &&
        longitudeGlobal.isNotEmpty) {
      data['longitude'] = longitudeGlobal;
    }

    data['time_zone'] = "";
    String queryString = Uri(
        queryParameters:
            data.map((key, value) => MapEntry(key, value.toString()))).query;
    var fullUrl = "$url?$queryString";
    final isSliderPath = path.toString() == Config.sliders;
    final isFoodPath = path.toString().startsWith('food/');
    if (isSliderPath) {
      debugPrint(
          "[HTTP][GET] sliders request | url=$fullUrl | hasBearer=${bearerToken.isNotEmpty} | hasUserToken=${token.isNotEmpty}");
    }
    if (isFoodPath) {
      debugPrint(
          "[HTTP][GET][FOOD] request | url=$fullUrl | hasBearer=${bearerToken.isNotEmpty} | hasUserToken=${token.isNotEmpty}");
    }

    var response = await http
        .get(Uri.parse(fullUrl), headers: headers)
        .timeout(const Duration(seconds: 15)); // Timeout after 15 seconds

    final rawBody = const Utf8Codec().decode(response.bodyBytes);
    if (isFoodPath) {
      debugPrint(
          "[HTTP][GET][FOOD] response | code=${response.statusCode} | body=${rawBody.length > 700 ? rawBody.substring(0, 700) : rawBody}");
    }
    dynamic decodedBody;
    try {
      decodedBody = json.decode(rawBody);
    } catch (_) {
      if (isSliderPath) {
        debugPrint(
            "[HTTP][GET] sliders non-JSON response | code=${response.statusCode} | contentType=${response.headers['content-type'] ?? ''} | body=${rawBody.length > 600 ? rawBody.substring(0, 600) : rawBody}");
      }
      decodedBody = {
        "status": response.statusCode,
        "error": "Invalid server response format",
        "raw_body": rawBody,
      };
    }

    if (response.statusCode == 200) {
      responsegetData = decodedBody;
      if (isSliderPath) {
        debugPrint(
            "[HTTP][GET] sliders response | code=200 | parsedStatus=${responsegetData is Map ? responsegetData['status'] : null}");
      }
    } else if (response.statusCode == 498) {
      final newToken = await generateToken();
      if (newToken != null) {
        bearerToken = newToken;
        headers['Authorization'] = "Bearer $bearerToken";
        response = await http.get(Uri.parse(fullUrl), headers: headers);
        final retryRawBody = const Utf8Codec().decode(response.bodyBytes);
        try {
          responsegetData = json.decode(retryRawBody);
        } catch (_) {
          responsegetData = {
            "status": response.statusCode,
            "error": "Invalid server response format",
            "raw_body": retryRawBody,
          };
        }
      } else {
        showErrorToastMessage("Token regeneration failed.");
        return {"error": "Token regeneration failed"};
      }
    } else {
      responsegetData = decodedBody;
      if (isSliderPath) {
        debugPrint(
            "[HTTP][GET] sliders response non-200 | code=${response.statusCode} | parsedStatus=${responsegetData is Map ? responsegetData['status'] : null}");
      }

      if (response.statusCode == 419) {
        showErrorToastMessage("Session expired. Please log in again.");
        Future.delayed(const Duration(seconds: 1), () {
          clearData(navigatorKey.currentContext!);
          goToWithClear(const LoginScreen());
        });
      }
    }
  } on TimeoutException {
    responsegetData = {'error': "Request timed out. Please try again."};
  } catch (e) {
    if (path.toString() == Config.sliders) {
      debugPrint("[HTTP][GET] sliders exception: $e");
    }
    responsegetData = {'error': "Something went wrong. Please try again."};
  }
  return responsegetData;
}

Future<String?>? _tokenFuture;
Future<String?> generateToken() async {
  if (_tokenFuture != null) {
    return _tokenFuture;
  }

  final completer = Completer<String?>();
  _tokenFuture = completer.future;

  try {
    const String url = '${Config.baseUrlForBearer}${Config.generateToken}';
    const Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    Map<String, dynamic> body = {
      "secret": Config.secretKey,
      "user_token": token
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final token = data['data']["token"].toString();
      bearerToken = token;

      box.put("bearerToken", token);
      box.put("bearerUserToken", body["user_token"] ?? "");
      completer.complete(token);
    } else if (response.statusCode == 419) {
      showErrorToastMessage("Session expired. Please log in again.");
      Future.delayed(const Duration(seconds: 1), () {
        clearData(navigatorKey.currentContext!);
        goToWithClear(const LoginScreen());
      });
    } else {
      completer.complete(null);
    }
  } catch (e) {
    completer.complete(null);
  } finally {
    _tokenFuture = null;
  }

  return await completer.future;
}
