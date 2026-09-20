import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'config.dart';
import 'data_store.dart';

bool connectionLost = false;
String latitudeGlobal = '';
String longitudeGlobal = '';
bool shouldLogout = false;

String _bodyPreview(String body, {int limit = 700}) {
  return body.length > limit ? body.substring(0, limit) : body;
}

void _logHttpFailure(
  String method,
  String url,
  int statusCode,
  String body, {
  Object? exception,
}) {
  debugPrint(
    "[HTTP][$method][FAIL] url=$url | code=$statusCode | hasUserToken=${token.isNotEmpty} | userTokenLength=${token.length} | hasBearer=${bearerToken.isNotEmpty} | bearerUserToken=${(box.get("bearerUserToken") ?? "").toString().isNotEmpty}",
  );
  if (body.isNotEmpty) {
    debugPrint("[HTTP][$method][FAIL] body=${_bodyPreview(body)}");
  }
  if (exception != null) {
    debugPrint("[HTTP][$method][FAIL] exception=$exception");
  }
}

Future<void> _repairStoredUserToken(String newUserToken) async {
  if (newUserToken.isEmpty || newUserToken == token) {
    return;
  }

  token = newUserToken;

  final rawUserData = box.get("UserData");
  if (rawUserData is! String || rawUserData.isEmpty) {
    return;
  }

  try {
    final decoded = json.decode(rawUserData);
    if (decoded is Map<String, dynamic> && decoded["data"] is Map) {
      final data = Map<String, dynamic>.from(decoded["data"] as Map);
      data["token"] = newUserToken;
      decoded["data"] = data;
      await box.put("UserData", jsonEncode(decoded));
      debugPrint("[HTTP][TOKEN] repaired stored app user token");
    }
  } catch (e) {
    debugPrint("[HTTP][TOKEN] failed to repair stored app user token: $e");
  }
}

Future<void> _ensureBearerMatchesCurrentUser() async {
  final bearerUserToken = (box.get("bearerUserToken") ?? "").toString();
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
        "[HTTP][POST] socialLogin request | url=$url | hasBearer=${bearerToken.isNotEmpty} | hasUserToken=${token.isNotEmpty}",
      );
      debugPrint("[HTTP][POST] socialLogin payload keys=${data.keys.toList()}");
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
          "[HTTP][POST] socialLogin non-JSON response | code=${response.statusCode} | body=${rawBody.length > 500 ? rawBody.substring(0, 500) : rawBody}",
        );
      }
      responseData = {
        "status": response.statusCode,
        "error": "Invalid server response format",
        "raw_body": rawBody,
      };
    }

    if (path.toString() == Config.socialLogin) {
      debugPrint(
        "[HTTP][POST] socialLogin response | code=${response.statusCode} | parsedStatus=${responseData is Map ? responseData["status"] : null}",
      );
    }

    if (response.statusCode >= 400 ||
        (responseData is Map &&
            (responseData["status"] == 419 ||
                responseData["ResponseCode"] == 419 ||
                responseData["message"].toString().toLowerCase().contains(
                  "token",
                )))) {
      _logHttpFailure("POST", url, response.statusCode, rawBody);
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
        return responseData is Map
            ? responseData
            : {"error": "Request failed. Please try again."};
      }
    }

    return responseData;
  } catch (err) {
    _logHttpFailure(
      "POST",
      Config.baseUrl + path.toString(),
      0,
      "",
      exception: err,
    );
    if (path.toString() == Config.socialLogin) {
      debugPrint("[HTTP][POST] socialLogin exception: $err");
    }
    return {"error": "Something went wrong", "exception": err.toString()};
  }
}

Future<dynamic> httpMultipartPost(
  String path,
  Map<String, String> fields, {
  required BuildContext context,
  required String fileField,
  required File file,
}) async {
  try {
    final url = Config.baseUrl + path;
    await _ensureBearerMatchesCurrentUser();
    if (bearerToken.isEmpty) {
      bearerToken = await generateToken() ?? "";
    }

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'Authorization': 'Bearer $bearerToken',
      'x-auth-token': token,
    });
    request.fields.addAll({
      ...fields,
      'module_id': '2',
      'user_type': 'user',
      'token': token,
      if (latitudeGlobal.isNotEmpty) 'latitude': latitudeGlobal,
      if (longitudeGlobal.isNotEmpty) 'longitude': longitudeGlobal,
    });
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 498) {
      final newToken = await generateToken();
      if (newToken != null) {
        bearerToken = newToken;
        final retryRequest = http.MultipartRequest('POST', Uri.parse(url));
        retryRequest.headers.addAll({
          'Authorization': 'Bearer $newToken',
          'x-auth-token': token,
        });
        retryRequest.fields.addAll(request.fields);
        retryRequest.files.add(
          await http.MultipartFile.fromPath(fileField, file.path),
        );
        streamedResponse = await retryRequest.send();
        response = await http.Response.fromStream(streamedResponse);
      }
    }

    final rawBody = const Utf8Codec().decode(response.bodyBytes);
    if (response.statusCode >= 400 || rawBody.toLowerCase().contains("token")) {
      _logHttpFailure("MULTIPART", url, response.statusCode, rawBody);
    }
    try {
      return json.decode(rawBody);
    } catch (_) {
      return {
        "status": response.statusCode,
        "error": "Invalid server response format",
        "raw_body": rawBody,
      };
    }
  } catch (err) {
    _logHttpFailure("MULTIPART", Config.baseUrl + path, 0, "", exception: err);
    return {"error": "Something went wrong", "exception": err.toString()};
  }
}

Future<dynamic> httpGet(
  String path,
  Map<String, dynamic> data, {
  required BuildContext context,
}) async {
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
      queryParameters: data.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    ).query;
    var fullUrl = "$url?$queryString";
    final isSliderPath = path.toString() == Config.sliders;
    final isFoodPath = path.toString().startsWith('food/');
    if (isSliderPath) {
      debugPrint(
        "[HTTP][GET] sliders request | url=$fullUrl | hasBearer=${bearerToken.isNotEmpty} | hasUserToken=${token.isNotEmpty}",
      );
    }
    if (isFoodPath) {
      debugPrint(
        "[HTTP][GET][FOOD] request | url=$fullUrl | hasBearer=${bearerToken.isNotEmpty} | hasUserToken=${token.isNotEmpty}",
      );
    }

    var response = await http
        .get(Uri.parse(fullUrl), headers: headers)
        .timeout(const Duration(seconds: 15)); // Timeout after 15 seconds

    final rawBody = const Utf8Codec().decode(response.bodyBytes);
    if (isFoodPath) {
      debugPrint(
        "[HTTP][GET][FOOD] response | code=${response.statusCode} | body=${rawBody.length > 700 ? rawBody.substring(0, 700) : rawBody}",
      );
    }
    dynamic decodedBody;
    try {
      decodedBody = json.decode(rawBody);
    } catch (_) {
      if (isSliderPath) {
        debugPrint(
          "[HTTP][GET] sliders non-JSON response | code=${response.statusCode} | contentType=${response.headers['content-type'] ?? ''} | body=${rawBody.length > 600 ? rawBody.substring(0, 600) : rawBody}",
        );
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
          "[HTTP][GET] sliders response | code=200 | parsedStatus=${responsegetData is Map ? responsegetData['status'] : null}",
        );
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
        return decodedBody is Map
            ? decodedBody
            : {"error": "Request failed. Please try again."};
      }
    } else {
      responsegetData = decodedBody;
      _logHttpFailure("GET", fullUrl, response.statusCode, rawBody);
      if (isSliderPath) {
        debugPrint(
          "[HTTP][GET] sliders response non-200 | code=${response.statusCode} | parsedStatus=${responsegetData is Map ? responsegetData['status'] : null}",
        );
      }

      // Keep the rider logged in even if the API session expires. The app will
      // keep local auth data and let the next request regenerate the bearer.
    }
  } on TimeoutException {
    _logHttpFailure("GET", Config.baseUrl + path, 0, "", exception: "timeout");
    responsegetData = {'error': "Request timed out. Please try again."};
  } catch (e) {
    _logHttpFailure("GET", Config.baseUrl + path, 0, "", exception: e);
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
    const Map<String, String> headers = {"Content-Type": "application/json"};

    Map<String, dynamic> body = {
      "secret": Config.secretKey,
      "user_token": token,
      if (loginModel?.data?.id != null) "user_id": loginModel!.data!.id,
      if ((loginModel?.data?.email ?? "").toString().isNotEmpty)
        "email": loginModel!.data!.email,
      if ((loginModel?.data?.phone ?? "").toString().isNotEmpty)
        "phone": loginModel!.data!.phone,
      if ((loginModel?.data?.phoneCountry ?? "").toString().isNotEmpty)
        "phone_country": loginModel!.data!.phoneCountry,
    };

    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    var data = json.decode(response.body);
    if (response.statusCode >= 400) {
      _logHttpFailure("TOKEN", url, response.statusCode, response.body);
    }
    var bearerUserToken = body["user_token"] ?? "";
    if (response.statusCode == 419 && token.isNotEmpty) {
      response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          "secret": Config.secretKey,
          if (loginModel?.data?.id != null) "user_id": loginModel!.data!.id,
          if ((loginModel?.data?.email ?? "").toString().isNotEmpty)
            "email": loginModel!.data!.email,
          if ((loginModel?.data?.phone ?? "").toString().isNotEmpty)
            "phone": loginModel!.data!.phone,
          if ((loginModel?.data?.phoneCountry ?? "").toString().isNotEmpty)
            "phone_country": loginModel!.data!.phoneCountry,
        }),
      );
      data = json.decode(response.body);
      bearerUserToken = "";
    }

    if (response.statusCode == 200) {
      final responsePayload = data['data'] is Map ? data['data'] as Map : {};
      final repairedUserToken = (responsePayload["app_user_token"] ?? "")
          .toString();
      if (repairedUserToken.isNotEmpty) {
        await _repairStoredUserToken(repairedUserToken);
        bearerUserToken = repairedUserToken;
      } else if (responsePayload["user_token_valid"] == false) {
        bearerUserToken = "";
      }

      final generatedBearerToken = responsePayload["token"].toString();
      bearerToken = generatedBearerToken;

      box.put("bearerToken", generatedBearerToken);
      box.put("bearerUserToken", bearerUserToken);
      completer.complete(generatedBearerToken);
    } else if (response.statusCode == 419) {
      completer.complete(null);
    } else {
      completer.complete(null);
    }
  } catch (e) {
    _logHttpFailure(
      "TOKEN",
      Config.baseUrlForBearer + Config.generateToken,
      0,
      "",
      exception: e,
    );
    completer.complete(null);
  } finally {
    _tokenFuture = null;
  }

  return await completer.future;
}
