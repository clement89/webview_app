import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:http/http.dart' as http;

class APIHandler {
  Future getVersionInfo(
      {Function successCallback, Function errorCallback}) async {
    print('**** getUserInfo');

    try {
      try {
        var url = Uri.parse('https://api.stayhopper.com/admin/v2/app-version');
        var response = await http.get(url);
        if (response.statusCode == 200) {
          var jsonResponse = convert.jsonDecode(response.body);
          print('Response: $jsonResponse.');
          return jsonResponse;
        } else {
          print('Request failed with status: ${response.statusCode}.');
        }
      } catch (e) {
        print('error 1234 - $e');
        return '{}';
      }
    } on SocketException {
      errorCallback('No internet connection');
    }
  }
}
