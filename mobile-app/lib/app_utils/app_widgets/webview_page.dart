import 'package:flutter/material.dart';
import 'package:moi/app_utils/app_global/app_bar_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

/// Allowed hosts for in-app WebView navigation (HTTPS only).
const Set<String> _allowedWebViewHosts = {
  'moikanakku.com',
  'www.moikanakku.com',
  'floatwalktiruppur.in',
  'www.floatwalktiruppur.in',
};

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({super.key, required this.url, this.title = 'வலைத்தளம்'});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _blocked = false;

  bool _isAllowedUrl(String url) {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return false;
    }
    if (uri.scheme != 'https') return false;
    if (uri.userInfo.isNotEmpty) return false;
    final host = uri.host.toLowerCase();
    return _allowedWebViewHosts.contains(host) ||
        _allowedWebViewHosts.any((h) => host.endsWith('.$h'));
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    // JS off by default for safety; enable only for allowlisted HTTPS pages.
    _controller.setJavaScriptMode(JavaScriptMode.disabled);
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (_isAllowedUrl(request.url)) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onPageStarted: (_) {
          if (mounted) {
            setState(() => _isLoading = true);
          }
        },
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
    if (_isAllowedUrl(widget.url)) {
      _controller.loadRequest(Uri.parse(widget.url));
    } else {
      _blocked = true;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.title,
        action: [
          if (!_blocked)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                size: 22,
                strokeWidth: 1.8,
              ),
              onPressed: () {
                _controller.reload();
              },
            ),
        ],
      ),
      body: _blocked
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This page cannot be opened in the app.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
