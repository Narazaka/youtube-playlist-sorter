import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

class Auth {
  static Future<Map<String, String>> getAuthInfo() async {
    final file = File('auth.json');
    final contents = await file.readAsString();
    final json = jsonDecode(contents);
    return {
      'api_key': json['api_key'],
      'client_id': json['client_id'],
      'client_secret': json['client_secret'],
      'redirect_uri': json['redirect_uri'],
    };
  }

  static GoogleSignIn? _googleSignIn;

  static Future<GoogleSignIn> getGoogleSignIn(BuildContext context) async {
    if (_googleSignIn == null) {
      final authInfo = await getAuthInfo();
      _googleSignIn = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: authInfo['client_id']!,
          clientSecret: authInfo['client_secret']!,
          scopes: [
            "https://www.googleapis.com/auth/youtube.readonly",
            "https://www.googleapis.com/auth/youtube",
            "https://www.googleapis.com/auth/youtube.force-ssl",
          ],
          redirectPort: 3000,
          retrieveAccessToken: () async {
            final file = File('token_cache.json');
            if (!await file.exists()) {
              return null;
            }
            final contents = await file.readAsString();
            final json = jsonDecode(contents);
            return json['access_token'];
          },
          saveAccessToken: (token) {
            final file = File('token_cache.json');
            return file.writeAsString(jsonEncode({'access_token': token}));
          },
          deleteAccessToken: () async {
            final file = File('token_cache.json');
            if (await file.exists()) {
              await file.delete();
            }
          },
        ),
      );
    }
    return _googleSignIn!;
  }

  static Future<GoogleSignInCredentials?> getCredentials(
      BuildContext context) async {
    return await (await getGoogleSignIn(context)).signIn();
  }

  static Future<AuthClient> authenticate(BuildContext context) async {
    var credentials = await getCredentials(context);
    if (credentials == null) {
      throw Exception('Sign in aborted by user');
    }
    return authenticatedClient(
        http.Client(),
        AccessCredentials(
            AccessToken(credentials.tokenType!, credentials.accessToken,
                DateTime.now().add(const Duration(seconds: 86400)).toUtc()),
            credentials.refreshToken,
            credentials.scopes,
            idToken: credentials.idToken));
  }
}
