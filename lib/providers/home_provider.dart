import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info/package_info.dart';
import 'package:webview_app/services/api_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeProvider extends ChangeNotifier {
  APIHandler _apiHandler = APIHandler();
  bool isConnected = true;
  bool isLoading = true;

  void checkConnectivity() {
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        print('not connected to internet');
        isConnected = false;
      } else {
        isConnected = true;
      }
      notifyListeners();
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void checkForceUpdate({Function callBack}) async {
    try {
      Map<String, dynamic> response = await _apiHandler.getVersionInfo();
      Map<String, dynamic> data = response['data'];
      Map<String, dynamic> platformData = data['ios'];

      if (Platform.isIOS) {
        platformData = data['ios'];
      } else {
        platformData = data['android'];
      }

      bool forceUpdate = platformData['forceUpdate'];
      if (forceUpdate) {
        String newVersion = platformData['buildVersion'];
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        currentVersion =
            currentVersion.substring(0, '$currentVersion'.indexOf('.') + 1 + 1);
        print('currentVersion -- >> $currentVersion');
        print('newVersion -- >> $newVersion');

        if (double.parse(currentVersion) < double.parse(newVersion)) {
          callBack();
        }
      }
    } catch (e) {
      print('Error - $e');
    }
  }
}
