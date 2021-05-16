import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:webview_app/pages/page_not_found.dart';
import 'package:webview_app/providers/home_provider.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Completer<WebViewController> _controller =
        Completer<WebViewController>();
    final _homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _homeProvider.checkConnectivity();
    _homeProvider.checkForceUpdate(callBack: () {
      _showMyDialog(context);
    });

    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        print('reloading account page - ');

        return WillPopScope(
          child: Scaffold(
            body: !provider.isConnected
                ? PageNotFound()
                : SafeArea(
                    child: ModalProgressHUD(
                      inAsyncCall: provider.isLoading,
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
                              print(
                                  "WebView is loading (progress : $progress%)");
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
                              provider.setLoading(false);
                            },
                            onWebResourceError: (WebResourceError error) {
                              print(
                                  'Error loading page - ${error.description}');
                              provider.setLoading(false);
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

  double getNumber(double input, {int precision = 2}) => double.parse(
      '$input'.substring(0, '$input'.indexOf('.') + precision + 1));

  Future<void> _showMyDialog(BuildContext context) async {
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
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
