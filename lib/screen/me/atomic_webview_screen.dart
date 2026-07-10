import 'package:atomic_webview/atomic_webview.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';

//WalletController walletController = Get.put(WalletController());

class AtomicWebViewScreen extends StatefulWidget {
  AtomicWebViewScreen({super.key, this.url = ''});

  final String? url;

  @override
  State<AtomicWebViewScreen> createState() => _AtomicWebViewScreenState();
}

class _AtomicWebViewScreenState extends State<AtomicWebViewScreen> {
  WebViewController webViewController = WebViewController();
  InAppWebViewController? webViewController1;
  final String callback_url = "http://127.0.0.1:8000";
  final String callback_url2 = "http://localhost/api/";

  bool isLoading = true;
  int progress = 0;
  String status = 'Loading...';

  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   var url = widget.url ?? '';

    //   Loggerr.log("Paystack URL in webview page: $url");

    //   webViewController.init(
    //     context: context,
    //     setState: setState,
    //     uri: Uri.parse(url),
    //   );
    // });
  }

  final GlobalKey webViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black45,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).canPop()
                ? Navigator.pop(context)
                : Navigator.of(context).pushNamed('/main_screen');
          },
          icon: Icon(Icons.chevron_left_rounded),
        ),
        title: Text(
          "Novelux",
          style: TextStyle(
            fontFamily: kFontFamily,
            fontWeight: FontWeight.w600,
            color: depperBlue,
            fontSize: 14,
          ),
        ),
      ),

      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(widget.url ?? '')),
            onWebViewCreated: (controller) {
              webViewController1 = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
                status = 'Loading ${url?.toString() ?? ''}';
              });
            },
            onProgressChanged: (controller, newProgress) {
              setState(() {
                progress = newProgress;
                status = 'Loading... $progress%';
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoading = false;
                progress = 100;
                status = 'Loaded ${url?.toString() ?? ''}';
              });

              if (url.toString().startsWith(callback_url) ||
                  url.toString().startsWith(callback_url2)) {
                // Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
                AppAlert.success('Wallet Funding Successful!!!');
              }
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                isLoading = false;
                status = 'Error loading page: $message';
              });
              // ScaffoldMessenger.of(
              //   context,
              // ).showSnackBar(SnackBar(content: Text('Load failed: $message')));
            },
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: progress / 100),
                    SizedBox(height: 12),
                    Text(status, style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    // return WebView(
    //   controller: webViewController,
    // );
  }
}
