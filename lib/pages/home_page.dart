import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:webview_app/pages/page_not_found.dart';
import 'package:webview_app/services/api_handler.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  var subscription;
  bool _isConnected = true;
  bool _isLoading = true;

  APIHandler _apiHandler = APIHandler();

  @override
  void initState() {
    super.initState();
    checkForceUpdate();

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        print('not connected to internet');
        setState(() {
          _isConnected = false;
        });
      } else {
        setState(() {
          _isConnected = true;
        });
      }
      // Got a new connectivity status!
    });
  }

  @override
  dispose() {
    super.dispose();
    subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return WillPopScope(
      child: Scaffold(
        body: !_isConnected
            ? PageNotFound()
            : SafeArea(
                child: ModalProgressHUD(
                  inAsyncCall: _isLoading,
                  child: Container(
                    color: Colors.white,
                    child: Builder(builder: (BuildContext context) {
                      return WebView(
                        initialUrl: 'https://www.stayhopper.com',
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated:
                            (WebViewController webViewController) {
                          _controller.complete(webViewController);
                        },
                        onProgress: (int progress) {
                          print("WebView is loading (progress : $progress%)");
                        },
                        javascriptChannels: <JavascriptChannel>{
                          _toasterJavascriptChannel(context),
                        },
                        navigationDelegate: (NavigationRequest request) {
                          print('allowing navigation to $request');
                          return NavigationDecision.navigate;
                        },
                        onPageStarted: (String url) {
                          print('Page started loading: $url');
                        },
                        onPageFinished: (String url) {
                          print('Page finished loading: $url');
                          setState(() {
                            _isLoading = false;
                          });
                        },
                        onWebResourceError: (WebResourceError error) {
                          print('Error loading page - ${error.description}');
                          setState(() {
                            _isLoading = false;
                          });
                        },
                        gestureNavigationEnabled: true,
                      );
                    }),
                  ),
                ),
              ),
      ),
      onWillPop: () async {
        WebViewController webViewController = await _controller.future;
        bool canNavigate = await webViewController.canGoBack();
        if (canNavigate) {
          webViewController.goBack();
          return false;
        } else {
          return true;
        }
      },
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  void checkForceUpdate() async {
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
          _showMyDialog();
        }
      }
    } catch (e) {
      print('Error - $e');
    }
  }

  double getNumber(double input, {int precision = 2}) => double.parse(
      '$input'.substring(0, '$input'.indexOf('.') + precision + 1));

  Future<void> _showMyDialog() async {
    String platform = '';
    if (Platform.isIOS) {
      platform = 'Apple Store';
    } else {
      platform = 'Play Store';
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Version Available'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'There is a newer version is available to download. Please update the app by visiting $platform.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('UPDATE'),
              onPressed: () {
                StoreRedirect.redirect(
                    androidAppId: "com.iroid.stayhopper",
                    iOSAppId: "1439901947");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
