import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S2SMFG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B), // slate-800
          primary: const Color(0xFF0F172A),    // slate-900
          secondary: const Color(0xFF3B82F6),  // blue-500
        ),
        useMaterial3: true,
      ),
      home: const MainWebViewScreen(),
    );
  }
}

class MainWebViewScreen extends StatefulWidget {
  const MainWebViewScreen({super.key});

  @override
  State<MainWebViewScreen> createState() => _MainWebViewScreenState();
}

class _MainWebViewScreenState extends State<MainWebViewScreen> {
  late final WebViewController _webViewController;
  String _vpsUrl = 'https://s2smfg.madawikri.co.id/manufacturing/inject';
  bool _isLoading = true;
  double _loadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInitWebView();
  }

  /// Request camera (and microphone) permission at the Android OS level,
  /// then initialise the WebView. This must happen before web content can
  /// call getUserMedia() and the WebView-level onPermissionRequest fires.
  Future<void> _requestPermissionsAndInitWebView() async {
    // Request camera + microphone together so the user sees a single prompt.
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final camGranted = statuses[Permission.camera]?.isGranted ?? false;

    if (!camGranted) {
      // Camera was denied. Init WebView anyway but show a warning.
      _initWebView();
      if (mounted) {
        _showSnackbar(
          'Izin kamera ditolak. Scan QR mungkin tidak berfungsi.',
          Colors.orange,
        );
      }
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    _webViewController = WebViewController(
      onPermissionRequest: (WebViewPermissionRequest request) {
        // Automatically grant WebView-level (JS getUserMedia) permission
        // for camera, microphone, etc.
        request.grant();
      },
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _showSnackbar('Gagal memuat halaman: ${error.description}', Colors.red);
          },
        ),
      )
      ..addJavaScriptChannel(
        'AndroidPrintChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final Map<String, dynamic> payload = jsonDecode(message.message);
            final String printerIp = payload['ip'];
            final String zplData = payload['data'];

            _sendToPrinter(printerIp, zplData);
          } catch (e) {
            _showSnackbar('Gagal mengurai payload cetak: $e', Colors.red);
          }
        },
      )
      ..loadRequest(Uri.parse(_vpsUrl));
  }

  Future<void> _sendToPrinter(String ip, String zplData) async {
    try {
      _showSnackbar('Menghubungkan ke printer $ip...', Colors.blue);
      
      // Buka TCP socket ke port 9100 dengan timeout 3 detik
      final Socket socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 3));
      
      // Kirim perintah cetak raw DP/ZPL
      socket.write(zplData);
      await socket.flush();
      await socket.close();

      _showSnackbar('Cetak berhasil dikirim ke $ip!', Colors.green);
    } catch (e) {
      _showSnackbar('Koneksi gagal ke printer $ip: $e', Colors.red);
    }
  }

  void _showSnackbar(String text, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSettingsDialog() {
    final textController = TextEditingController(text: _vpsUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pengaturan Alamat Web (VPS)'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Domain/IP VPS',
              hintText: 'https://s2smfg.madawikri.co.id/manufacturing/inject',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = textController.text.trim();
                if (url.isNotEmpty) {
                  setState(() {
                    _vpsUrl = url;
                  });
                  _webViewController.loadRequest(Uri.parse(_vpsUrl));
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan & Muat Ulang'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'S2SMFG',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _webViewController.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(
                  value: _loadProgress > 0 ? _loadProgress : null,
                  backgroundColor: const Color(0xFF1E293B),
                  color: Colors.blue,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
