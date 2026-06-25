import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' show ImageFilter;
import 'package:webview_flutter/webview_flutter.dart';

// Local Imports
import 'models/verification_models.dart';
import 'services/api_service.dart';
import 'url_launcher_stub.dart' if (dart.library.js) 'url_launcher_web.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verivio - Lapisan Verifikasi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070514),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
          surface: const Color(0xFF131127),
          background: const Color(0xFF070514),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const MainResponsiveScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// CHAT MESSAGE DATA CLASS
// -----------------------------------------------------------------------------
class ChatMessage {
  final String text;
  final bool isUser;
  final String senderName;
  final Color senderColor;
  final String? senderLogo;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.senderName,
    required this.senderColor,
    this.senderLogo,
  });
}

// -----------------------------------------------------------------------------
// APP STATE (Simple ChangeNotifier for state management)
// -----------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Platforms mock data
  final List<Map<String, dynamic>> platforms = [
    {
      'name': 'ChatGPT',
      'url': 'chatgpt.com',
      'model': 'GPT-4o',
      'avatar': 'C',
      'avatarColor': const Color(0xFF10A37F),
      'bgColor': const Color(0xFFEAF3DE),
      'iconColor': const Color(0xFF3B6D11),
      'logo': 'assets/images/chatgpt.png',
      'answer': 'Ya, berbagai penelitian menunjukkan hubungan signifikan antara penggunaan media sosial berlebihan dengan penurunan kesehatan mental. Penggunaan lebih dari 3 jam per hari meningkatkan risiko depresi. Perempuan cenderung lebih rentan. Platform berbasis gambar seperti Instagram dinilai lebih berdampak negatif...'
    },
    {
      'name': 'Gemini',
      'url': 'gemini.google.com',
      'model': 'Gemini 2.5 Flash',
      'avatar': 'G',
      'avatarColor': const Color(0xFF1A73E8),
      'bgColor': const Color(0xFFE6F1FB),
      'iconColor': const Color(0xFF185FA5),
      'logo': 'assets/images/gemini.png',
      'answer': 'Berdasarkan data riset psikologis terkini, media sosial memiliki korelasi kuat dengan kecemasan dan gangguan tidur pada remaja. Algoritma pembandingan sosial (social comparison) memicu distorsi citra diri (body image issues), terutama pada kelompok umur 12-16 tahun...'
    },
    {
      'name': 'Claude',
      'url': 'claude.ai',
      'model': 'Claude 3.5 Sonnet',
      'avatar': 'C',
      'avatarColor': const Color(0xFFD97706),
      'bgColor': const Color(0xFFFAECE7),
      'iconColor': const Color(0xFF993C1D),
      'logo': 'assets/images/claude.png',
      'answer': 'Analisis komprehensif menunjukkan efek media sosial pada mental remaja bersifat multifaktorial. Meskipun memfasilitasi koneksi sosial, paparan konten terkurasi memicu sindrom FOMO (Fear Of Missing Out) dan mengganggu siklus tidur yang penting bagi perkembangan otak...'
    },
    {
      'name': 'DeepSeek',
      'url': 'deepseek.com',
      'model': 'DeepSeek-V3',
      'avatar': 'D',
      'avatarColor': const Color(0xFF0052CC),
      'bgColor': const Color(0xFFFBEAF0),
      'iconColor': const Color(0xFF993556),
      'logo': 'assets/images/deepseek.png',
      'answer': 'Menurut studi empiris terbaru, terdapat dampak negatif linear antara waktu layar (screen time) media sosial dengan kesejahteraan emosional remaja. Risiko utama meliputi paparan cyberbullying, fragmentasi atensi, serta berkurangnya interaksi tatap muka secara langsung...'
    }
  ];

  late Map<String, dynamic> _selectedPlatformData;
  bool _isVerifying = false;
  VerificationData? _verificationData;
  String? _errorMessage;

  // Simulator screens: 1 = Choose Platform, 2 = Chat Screen, 3 = Overlay Panel
  int _screenIndex = 1;
  
  // Overlay detailed view: 'menu', 'claims', 'papers', 'consensus', 'blindspot', 'citations'
  String _activeFeature = 'menu';
  
  // Citations Tab format: 'apa', 'mla', 'ieee'
  String _citationFormat = 'apa';

  // Dynamic Chat History
  List<ChatMessage> _chatMessages = [];
  bool _isAiTyping = false;

  AppState() {
    _selectedPlatformData = platforms[0]; // Default ChatGPT
    _resetChatToDefault();
  }

  // Getters
  Map<String, dynamic> get selectedPlatformData => _selectedPlatformData;
  bool get isVerifying => _isVerifying;
  VerificationData? get verificationData => _verificationData;
  String? get errorMessage => _errorMessage;
  int get screenIndex => _screenIndex;
  String get activeFeature => _activeFeature;
  String get citationFormat => _citationFormat;
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isAiTyping => _isAiTyping;

  void _resetChatToDefault() {
    _chatMessages = [
      ChatMessage(
        text: 'Apakah penggunaan media sosial berpengaruh negatif terhadap kesehatan mental remaja?',
        isUser: true,
        senderName: 'U',
        senderColor: const Color(0xFF6366F1),
      ),
      ChatMessage(
        text: _selectedPlatformData['answer'],
        isUser: false,
        senderName: _selectedPlatformData['avatar'],
        senderColor: _selectedPlatformData['avatarColor'],
        senderLogo: _selectedPlatformData['logo'],
      ),
    ];
  }

  void selectPlatform(String name) {
    _selectedPlatformData = platforms.firstWhere((p) => p['name'] == name);
    _resetChatToDefault();
    notifyListeners();
  }

  void setScreen(int index) {
    _screenIndex = index;
    if (index != 3) {
      _activeFeature = 'menu';
    }
    notifyListeners();
  }

  void setActiveFeature(String feature) {
    _activeFeature = feature;
    notifyListeners();
  }

  void setCitationFormat(String format) {
    _citationFormat = format;
    notifyListeners();
  }

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Tambah pesan user
    _chatMessages.add(ChatMessage(
      text: text,
      isUser: true,
      senderName: 'U',
      senderColor: const Color(0xFF6366F1),
    ));
    _isAiTyping = true;
    notifyListeners();

    try {
      // Ambil respon AI dinamis dari backend /chat
      final aiResponse = await _apiService.getAiResponse(text);
      _chatMessages.add(ChatMessage(
        text: aiResponse,
        isUser: false,
        senderName: _selectedPlatformData['avatar'],
        senderColor: _selectedPlatformData['avatarColor'],
        senderLogo: _selectedPlatformData['logo'],
      ));
    } catch (e) {
      _chatMessages.add(ChatMessage(
        text: 'Error: Gagal mendapatkan jawaban dari backend. Pastikan server lokal aktif. ($e)',
        isUser: false,
        senderName: 'System',
        senderColor: const Color(0xFFEF4444),
      ));
    } finally {
      _isAiTyping = false;
      notifyListeners();
    }
  }

  Future<void> triggerVerification() async {
    _isVerifying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cari jawaban AI paling baru di utas chat
      String answer = '';
      for (int i = _chatMessages.length - 1; i >= 0; i--) {
        if (!_chatMessages[i].isUser) {
          answer = _chatMessages[i].text;
          break;
        }
      }

      if (answer.isEmpty) {
        answer = _selectedPlatformData['answer'];
      }

      final data = await _apiService.verifyAnswer(answer);
      _verificationData = data;
      _screenIndex = 3; // Go to overlay panel
      _activeFeature = 'menu';
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _verificationData = null;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> triggerVerificationForText(String answer) async {
    _isVerifying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.verifyAnswer(answer);
      _verificationData = data;
      _screenIndex = 3; // Go to overlay panel
      _activeFeature = 'menu';
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _verificationData = null;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  void setVerifying(bool val) {
    _isVerifying = val;
    notifyListeners();
  }

  void reset() {
    _verificationData = null;
    _errorMessage = null;
    _screenIndex = 1;
    _activeFeature = 'menu';
    _resetChatToDefault();
    notifyListeners();
  }
}

// -----------------------------------------------------------------------------
// RESPONSIVE LAYOUT CONTAINER
// -----------------------------------------------------------------------------
class MainResponsiveScreen extends StatefulWidget {
  const MainResponsiveScreen({super.key});

  @override
  State<MainResponsiveScreen> createState() => _MainResponsiveScreenState();
}

class _MainResponsiveScreenState extends State<MainResponsiveScreen> {
  late AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState();
    _state.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050314),
              Color(0xFF0F0C24),
              Color(0xFF140D30),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: isDesktop
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column: The Simulated iPhone
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: PhoneSimulator(state: _state, embedInFrame: true),
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Right Column: The Expanded Analytics Dashboard
                        Expanded(
                          flex: 7,
                          child: DesktopDashboard(state: _state),
                        ),
                      ],
                    ),
                  )
                : PhoneSimulator(state: _state, embedInFrame: false),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// IPHONE SIMULATOR WIDGET
// -----------------------------------------------------------------------------
class PhoneSimulator extends StatelessWidget {
  final AppState state;
  final bool embedInFrame;
  const PhoneSimulator({super.key, required this.state, this.embedInFrame = true});

  @override
  Widget build(BuildContext context) {
    // Beautiful mobile screen resolution wrapper inside simulated iPhone frame
    final mainLayout = Stack(
      children: [
        // Internal Screen Content
        Column(
          children: [
            if (embedInFrame)
              // Top Status Bar Area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.wifi, color: Color(0xFF1A1A1A), size: 14),
                        const SizedBox(width: 6),
                        const Icon(Icons.battery_std, color: Color(0xFF1A1A1A), size: 14),
                      ],
                    )
                  ],
                ),
              ),
            
            // Screen Content Changer
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildScreenContent(context),
              ),
            ),
          ],
        ),

        // Shimmer Loading Overlay during verification API call
        if (state.isVerifying)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF534AB7)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Memverifikasi...',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mengekstrak klaim & mencari referensi akademik',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7A7A7A),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Error Popups
        if (state.errorMessage != null)
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF991B1B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF87171).withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Koneksi Gagal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      InkWell(
                        onTap: () => state.reset(),
                        child: const Icon(Icons.close, color: Colors.white70, size: 16),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (embedInFrame) {
      return Container(
        width: 320,
        height: 640,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              blurRadius: 50,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: mainLayout,
        ),
      );
    } else {
      return Container(
        color: Colors.white,
        child: mainLayout,
      );
    }
  }

  Widget _buildScreenContent(BuildContext context) {
    switch (state.screenIndex) {
      case 1:
        return _Screen1AISelector(state: state);
      case 2:
      case 3:
        return Stack(
          children: [
            _Screen2ChatSimulator(state: state),
            if (state.screenIndex == 3)
              _Screen3OverlayDrawer(state: state),
          ],
        );
      default:
        return _Screen1AISelector(state: state);
    }
  }
}

// -----------------------------------------------------------------------------
// PHONE SCREEN 1: CHOOSE AI
// -----------------------------------------------------------------------------
class _Screen1AISelector extends StatelessWidget {
  final AppState state;
  const _Screen1AISelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Logo & Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF534AB7).withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/verivio.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verivio',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lapisan verifikasi untuk semua AI',
                  style: TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'PILIH PLATFORM AI KAMU',
            style: TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          // AI Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: state.platforms.length,
              itemBuilder: (context, index) {
                final platform = state.platforms[index];
                final isSelected = state.selectedPlatformData['name'] == platform['name'];

                return InkWell(
                  onTap: () => state.selectPlatform(platform['name']),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEEDFE) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF534AB7) 
                            : const Color(0xFFDEE2E6),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: platform['bgColor'],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              platform['logo'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          platform['name'],
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Navigation Button
          ElevatedButton(
            onPressed: () => state.setScreen(2),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF534AB7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
              shadowColor: const Color(0xFF534AB7).withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Buka ${state.selectedPlatformData['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PHONE SCREEN 2: CHAT INTERFACE
// -----------------------------------------------------------------------------
class _Screen2ChatSimulator extends StatefulWidget {
  final AppState state;
  const _Screen2ChatSimulator({required this.state});

  @override
  State<_Screen2ChatSimulator> createState() => _Screen2ChatSimulatorState();
}

class _Screen2ChatSimulatorState extends State<_Screen2ChatSimulator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _chatController = TextEditingController();
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initWebView();
  }

  void _initWebView() {
    if (!kIsWeb) {
      final pData = widget.state.selectedPlatformData;
      String targetUrl = pData['name'] == 'ChatGPT'
          ? 'https://chatgpt.com'
          : pData['name'] == 'Gemini'
              ? 'https://gemini.google.com'
              : pData['name'] == 'Claude'
                  ? 'https://claude.ai'
                  : 'https://chat.deepseek.com';

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent("Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36")
        ..loadRequest(Uri.parse(targetUrl));
    }
  }

  @override
  void didUpdateWidget(covariant _Screen2ChatSimulator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kIsWeb && _webViewController != null) {
      final oldPlatform = oldWidget.state.selectedPlatformData['name'];
      final newPlatform = widget.state.selectedPlatformData['name'];
      if (oldPlatform != newPlatform) {
        String targetUrl = newPlatform == 'ChatGPT'
            ? 'https://chatgpt.com'
            : newPlatform == 'Gemini'
                ? 'https://gemini.google.com'
                : newPlatform == 'Claude'
                    ? 'https://claude.ai'
                    : 'https://chat.deepseek.com';
        _webViewController!.loadRequest(Uri.parse(targetUrl));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _handleRealVerify() async {
    if (_webViewController == null) return;
    
    widget.state.setVerifying(true);
    
    try {
      // Evaluate JS to extract the last response text
      final jsCode = """
        (function() {
          // ChatGPT selector
          let elements = document.querySelectorAll('.markdown');
          if (elements.length > 0) return elements[elements.length - 1].innerText;
          
          // Claude selector
          elements = document.querySelectorAll('.font-claude-message');
          if (elements.length > 0) return elements[elements.length - 1].innerText;

          // Gemini selector
          elements = document.querySelectorAll('message-content');
          if (elements.length > 0) return elements[elements.length - 1].innerText;

          // Fallback to paragraph/body texts
          return document.body.innerText || "";
        })()
      """;
      
      final dynamic result = await _webViewController!.runJavaScriptReturningResult(jsCode);
      String extractedText = "";
      if (result != null) {
        extractedText = result.toString();
        // Remove enclosing quotes added by json encoding in runJavaScriptReturningResult
        if (extractedText.startsWith('"') && extractedText.endsWith('"') && extractedText.length > 2) {
          extractedText = extractedText.substring(1, extractedText.length - 1);
        }
        // Decode JS string escape sequences
        extractedText = extractedText.replaceAll('\\n', '\n').replaceAll('\\"', '"');
      }

      if (extractedText.trim().isEmpty || extractedText == 'null' || extractedText.length < 5) {
        // Show fallback paste dialog
        widget.state.setVerifying(false);
        _showPasteDialog();
      } else {
        await widget.state.triggerVerificationForText(extractedText);
      }
    } catch (e) {
      widget.state.setVerifying(false);
      _showPasteDialog();
    }
  }

  void _showPasteDialog() {
    final pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Verify Teks Jawaban', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gagal mendeteksi jawaban otomatis dari WebView. Silakan salin & tempel teks jawaban AI di bawah ini:',
              style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDEE2E6)),
              ),
              child: TextField(
                controller: pasteController,
                maxLines: null,
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tempel teks jawaban AI di sini...',
                  hintStyle: TextStyle(color: Color(0xFF7A7A7A), fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = pasteController.text;
              Navigator.pop(ctx);
              if (text.trim().isNotEmpty) {
                widget.state.triggerVerificationForText(text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF534AB7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pData = widget.state.selectedPlatformData;
    
    // Fallback simulated layout for web browser target, and real WebViewWidget for mobile target
    if (kIsWeb) {
      final messages = widget.state.chatMessages;
      return Container(
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning info banner for browser mode since real webviews can't iframe Gemini/ChatGPT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: const Color(0xFFFEF9C3),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF713F12), size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Web Demo: Menggunakan chat simulasi. Silakan install APK untuk membuka web asli.',
                          style: TextStyle(
                            color: const Color(0xFF713F12),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Browser URL Address Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: const Color(0xFFF1F3F5),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Color(0xFF7A7A7A), size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pData['url'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.more_horiz, color: Color(0xFF7A7A7A), size: 14),
                    ],
                  ),
                ),

                // Chat Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F3F5), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        pData['name'],
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9ECEF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          pData['model'],
                          style: const TextStyle(
                            color: Color(0xFF495057),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // Chat Messages List (reversed)
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => widget.state.setScreen(1),
                            icon: const Icon(Icons.chevron_left, size: 16, color: Color(0xFF7A7A7A)),
                            label: const Text('Pilih Platform', style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 11)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                            ),
                          ),
                        );
                      }

                      final msg = messages[messages.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: msg.isUser ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            msg.isUser
                                ? CircleAvatar(
                                    radius: 13,
                                    backgroundColor: const Color(0xFF7C3AED),
                                    child: const Text(
                                      'U',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFDEE2E6)),
                                    ),
                                    child: ClipOval(
                                      child: msg.senderLogo != null
                                          ? Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Image.asset(
                                                msg.senderLogo!,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                msg.senderName,
                                                style: TextStyle(color: msg.senderColor, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                    ),
                                  ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: msg.isUser
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFFF1F3F5),
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      topLeft: msg.isUser ? null : const Radius.circular(4),
                                      topRight: msg.isUser ? const Radius.circular(4) : null,
                                    ),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: msg.isUser ? Colors.white : const Color(0xFF1A1A1A),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // AI Typing Indicator
                if (widget.state.isAiTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          child: const CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF534AB7)),
                          ),
                        ),
                        Text(
                          '${pData['name']} sedang menulis...',
                          style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),

                // Chat Input Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F3F5), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Ketik pesan...',
                              hintStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                widget.state.sendChatMessage(val);
                                _chatController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          final val = _chatController.text;
                          if (val.trim().isNotEmpty) {
                            widget.state.sendChatMessage(val);
                            _chatController.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF111111),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_upward, size: 14, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),

            // Floating Verify Button
            Positioned(
              bottom: 74,
              right: 14,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF534AB7).withOpacity(0.3 * (1 - _pulseController.value)),
                          blurRadius: 15 * _pulseController.value + 5,
                          spreadRadius: 8 * _pulseController.value,
                        )
                      ],
                    ),
                    child: child,
                  );
                },
                child: FloatingActionButton.extended(
                  onPressed: () => widget.state.triggerVerification(),
                  backgroundColor: const Color(0xFF534AB7),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  icon: const Icon(Icons.verified_user, size: 15),
                  label: const Text(
                    'Verify',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    } else {
      // WebView mode for native targets (APK / iOS)
      return Container(
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom web address bar for visual context
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: const Color(0xFFF1F3F5),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Color(0xFF7A7A7A), size: 18),
                        onPressed: () => widget.state.setScreen(1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.lock_outline, color: Color(0xFF7A7A7A), size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pData['url'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF7A7A7A), size: 14),
                        onPressed: () {
                          if (_webViewController != null) {
                            _webViewController!.reload();
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // WebView component
                Expanded(
                  child: _webViewController != null
                      ? WebViewWidget(controller: _webViewController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),

            // Floating pulse Verify button on top of WebView
            Positioned(
              bottom: 24,
              right: 14,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF534AB7).withOpacity(0.3 * (1 - _pulseController.value)),
                          blurRadius: 15 * _pulseController.value + 5,
                          spreadRadius: 8 * _pulseController.value,
                        )
                      ],
                    ),
                    child: child,
                  );
                },
                child: FloatingActionButton.extended(
                  onPressed: _handleRealVerify,
                  backgroundColor: const Color(0xFF534AB7),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  icon: const Icon(Icons.verified_user, size: 15),
                  label: const Text(
                    'Verify',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }
  }
}

// -----------------------------------------------------------------------------
// PHONE SCREEN 3: VERIFY OVERLAY DRAWER
// -----------------------------------------------------------------------------
class _Screen3OverlayDrawer extends StatelessWidget {
  final AppState state;
  const _Screen3OverlayDrawer({required this.state});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Semi-transparent blurred backdrop that closes the drawer when tapped
          Positioned.fill(
            child: GestureDetector(
              onTap: () => state.setScreen(2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          ),
          
          // Slide-up bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.75, // Takes 75% of the screen height
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEE2E6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    // Title Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (state.activeFeature != 'menu') ...[
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF1A1A1A)),
                                  onPressed: () => state.setActiveFeature('menu'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (state.activeFeature == 'menu') ...[
                                const Icon(Icons.verified_user, color: Color(0xFF534AB7), size: 16),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                state.activeFeature == 'menu'
                                    ? 'Verify'
                                    : _getFeatureTitle(state.activeFeature),
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Color(0xFF7A7A7A)),
                            onPressed: () => state.setScreen(2),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    if (state.activeFeature == 'menu')
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: Text(
                          'Jawaban AI siap diverifikasi. Pilih fitur:',
                          style: TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const Divider(color: Color(0xFFE9ECEF), height: 16),

                    // Dynamic Content view based on sub-features
                    Expanded(
                      child: state.activeFeature == 'menu'
                          ? _buildFeatureMenu()
                          : _buildSubFeatureContent(context),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  String _getFeatureTitle(String feature) {
    switch (feature) {
      case 'claims':
        return 'Claim Extractor';
      case 'papers':
        return 'Evidence Finder';
      case 'consensus':
        return 'Consensus Meter';
      case 'blindspot':
        return 'Blind Spot Alert';
      case 'citations':
        return 'Ready-to-Cite';
      default:
        return 'Verify';
    }
  }

  // Feature selection cards
  Widget _buildFeatureMenu() {
    final features = [
      {
        'id': 'claims',
        'title': 'Claim extractor',
        'desc': 'Pecah jawaban jadi klaim terpisah',
        'color': const Color(0xFFEEEDFE),
        'iconColor': const Color(0xFF534AB7),
        'icon': Icons.content_cut_outlined,
        'hasBadge': false,
      },
      {
        'id': 'papers',
        'title': 'Evidence finder',
        'desc': 'Cari jurnal & sumber ilmiah',
        'color': const Color(0xFFE1F5EE),
        'iconColor': const Color(0xFF0F6E56),
        'icon': Icons.menu_book_outlined,
        'hasBadge': false,
      },
      {
        'id': 'consensus',
        'title': 'Consensus meter',
        'desc': 'Lihat kekuatan konsensus riset',
        'color': const Color(0xFFE6F1FB),
        'iconColor': const Color(0xFF185FA5),
        'icon': Icons.speed_outlined,
        'hasBadge': false,
      },
      {
        'id': 'blindspot',
        'title': 'Blind spot alert',
        'desc': 'Deteksi perspektif yang absen',
        'color': const Color(0xFFFAEEDA),
        'iconColor': const Color(0xFF854F0B),
        'icon': Icons.public,
        'hasBadge': true,
      },
      {
        'id': 'citations',
        'title': 'Ready-to-cite',
        'desc': 'Sitasi APA / MLA / IEEE otomatis',
        'color': const Color(0xFFEAF3DE),
        'iconColor': const Color(0xFF3B6D11),
        'icon': Icons.format_quote,
        'hasBadge': false,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: features.length,
      separatorBuilder: (c, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final f = features[index];
        return InkWell(
          onTap: () => state.setActiveFeature(f['id'] as String),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDEE2E6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: f['color'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f['icon'] as IconData, color: f['iconColor'] as Color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (f['hasBadge'] as bool) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3DE),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'BARU',
                                style: TextStyle(
                                  color: Color(0xFF3B6D11),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ]
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f['desc'] as String,
                        style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF7A7A7A), size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sliding sheet subpages
  Widget _buildSubFeatureContent(BuildContext context) {
    final vData = state.verificationData;
    if (vData == null) return const Center(child: Text('No data loaded'));

    switch (state.activeFeature) {
      case 'claims':
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: vData.claims.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDEE2E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Klaim #${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF534AB7),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${vData.claims[index]}"',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case 'papers':
        if (vData.papers.isEmpty) {
          return const Center(
            child: Text('Tidak ada jurnal referensi ditemukan.', style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: vData.papers.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final p = vData.papers[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDEE2E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 12, color: Color(0xFF7A7A7A)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.authors.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, size: 10, color: Color(0xFF7A7A7A)),
                      const SizedBox(width: 4),
                      Text('${p.year}', style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.abstractText.isNotEmpty
                        ? (p.abstractText.length > 140 ? '${p.abstractText.substring(0, 140)}...' : p.abstractText)
                        : 'Abstrak tidak tersedia.',
                    style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 11, height: 1.4),
                  ),
                  if (p.url.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => launchUrl(p.url),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buka Jurnal',
                            style: TextStyle(
                              color: Color(0xFF534AB7),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 11, color: Color(0xFF534AB7)),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            );
          },
        );

      case 'consensus':
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: vData.claims.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final claim = vData.claims[index];
            final cResult = vData.consensus[claim] ??
                ConsensusResult(score: 0, level: 'Weak', support: 0, neutral: 0, oppose: 0, total: 0);

            Color levelColor = const Color(0xFF10A37F);
            if (cResult.level == 'Medium') levelColor = const Color(0xFFEAB308);
            if (cResult.level == 'Low' || cResult.level == 'Weak') levelColor = const Color(0xFFF97316);
            if (cResult.level == 'Contradictory') levelColor = const Color(0xFFEF4444);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDEE2E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$claim"',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CustomPaint(
                          painter: GaugePainter(score: cResult.score.toDouble(), color: levelColor),
                          child: Center(
                            child: Text(
                              '${cResult.score}%',
                              style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level: ${cResult.level}',
                              style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Support: ${cResult.support} | Neutral: ${cResult.neutral} | Oppose: ${cResult.oppose}',
                              style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 10),
                            ),
                            Text(
                              'Total Paper: ${cResult.total}',
                              style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        );

      case 'blindspot':
        final bs = vData.blindSpot;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Warning Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAECE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF993C1D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Color(0xFF993C1D), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Ringkasan Geografis',
                        style: TextStyle(
                          color: Color(0xFF993C1D),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bs.summary,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats title
            const Text(
              'SEBARAN WILAYAH INSTITUSI',
              style: TextStyle(
                color: Color(0xFF7A7A7A),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Bar stats list
            ...bs.distribution.entries.map((entry) {
              final count = entry.value;
              final widthFactor = (count / 8.0).clamp(0.05, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: widthFactor,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF534AB7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$count',
                      style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );

      case 'citations':
        if (vData.papers.isEmpty) {
          return const Center(
            child: Text('Tidak ada sitasi untuk ditampilkan.', style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12)),
          );
        }
        return Column(
          children: [
            // Citation Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: ['apa', 'mla', 'ieee'].map((fmt) {
                  final isActive = state.citationFormat == fmt;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => state.setCitationFormat(fmt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFEEEDFE) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive ? const Color(0xFF534AB7) : const Color(0xFFDEE2E6),
                              width: isActive ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            fmt.toUpperCase(),
                            style: TextStyle(
                              color: isActive ? const Color(0xFF534AB7) : const Color(0xFF7A7A7A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Citations List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: vData.papers.length,
                separatorBuilder: (c, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final paper = vData.papers[index];
                  final citationObj = vData.citations[paper.id];
                  
                  String citationText = 'Sitasi tidak tersedia.';
                  if (citationObj != null) {
                    if (state.citationFormat == 'apa') citationText = citationObj.apa;
                    if (state.citationFormat == 'mla') citationText = citationObj.mla;
                    if (state.citationFormat == 'ieee') citationText = citationObj.ieee;
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDEE2E6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          paper.title,
                          style: const TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  citationText,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: citationText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sitasi berhasil disalin ke clipboard!',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.copy, size: 14, color: Color(0xFF534AB7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );

      default:
        return const Center(child: Text('Menu'));
    }
  }
}

// -----------------------------------------------------------------------------
// EXPANDED DESKTOP VIEW DASHBOARD
// -----------------------------------------------------------------------------
class DesktopDashboard extends StatelessWidget {
  final AppState state;
  const DesktopDashboard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final vData = state.verificationData;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF110E25).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: vData == null
            ? _buildEmptyState()
            : _buildDashboardContent(context, vData),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user,
          size: 72,
          color: const Color(0xFF6366F1).withOpacity(0.12),
        ),
        const SizedBox(height: 18),
        const Text(
          'Analisis Konsensus Sains Verivio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Pilih salah satu platform AI di simulator handphone di sebelah kiri Anda, lalu tekan tombol "Verify" untuk memicu audit validitas jawaban dan melacak referensi riset secara real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, VerificationData vData) {
    // Quick statistics calculation
    double averageScore = 0;
    if (vData.consensus.isNotEmpty) {
      final totalScore = vData.consensus.values.fold(0, (sum, item) => sum + item.score);
      averageScore = totalScore / vData.consensus.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dasbor Analisis Sains',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Menampilkan hasil audit dari ${state.selectedPlatformData['name']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
            // Reset Button
            OutlinedButton.icon(
              onPressed: () => state.reset(),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reset Simulator', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cards layout
        Expanded(
          child: GridView(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.25,
            ),
            children: [
              // Stat Overview card
              _buildDashboardCard(
                title: 'Overview Validitas',
                icon: Icons.analytics_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      // Large radial consensus score
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: GaugePainter(
                            score: averageScore,
                            color: averageScore >= 50 ? const Color(0xFF10A37F) : const Color(0xFFEF4444),
                          ),
                          child: Center(
                            child: Text(
                              '${averageScore.round()}%',
                              style: TextStyle(
                                color: averageScore >= 50 ? const Color(0xFF10A37F) : const Color(0xFFEF4444),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Konsensus Rata-rata',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            Text(
                              averageScore >= 80
                                  ? 'Sangat Kuat (High)'
                                  : (averageScore >= 50 ? 'Sedang (Medium)' : 'Lemah (Low)'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Jumlah Klaim: ${vData.claims.length}\n• Jurnal Terlacak: ${vData.papers.length}',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, height: 1.5),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Blind Spot card
              _buildDashboardCard(
                title: 'Deteksi Blind Spot Geografis',
                icon: Icons.public,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F1D1D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.1)),
                        ),
                        child: Text(
                          vData.blindSpot.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 10, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Horizontal distribution bars
                      Expanded(
                        child: ListView(
                          children: vData.blindSpot.distribution.entries.take(3).map((entry) {
                            final widthFactor = (entry.value / 8.0).clamp(0.05, 1.0);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: widthFactor,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${entry.value}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Claims & Consensus grid
              _buildDashboardCard(
                title: 'Ekstraksi Klaim & Konsensus',
                icon: Icons.list_alt,
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: vData.claims.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final claim = vData.claims[index];
                    final consensus = vData.consensus[claim];
                    final score = consensus?.score ?? 0;
                    final level = consensus?.level ?? 'Weak';

                    Color lvlColor = const Color(0xFF10A37F);
                    if (level == 'Medium') lvlColor = const Color(0xFFEAB308);
                    if (level == 'Low' || level == 'Weak') lvlColor = const Color(0xFFF97316);
                    if (level == 'Contradictory') lvlColor = const Color(0xFFEF4444);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lvlColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: lvlColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$score%',
                            style: TextStyle(color: lvlColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"$claim"',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                              Text(
                                'Support: ${consensus?.support} | Neutral: ${consensus?.neutral} | Oppose: ${consensus?.oppose}',
                                style: const TextStyle(color: Colors.white38, fontSize: 9),
                              ),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

              // Literature & Papers card
              _buildDashboardCard(
                title: 'Katalog Bukti Riset (OpenAlex)',
                icon: Icons.menu_book,
                child: vData.papers.isEmpty
                    ? const Center(child: Text('Tidak ada paper referensi.', style: TextStyle(color: Colors.white38, fontSize: 11)))
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 8.0),
                        itemCount: vData.papers.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = vData.papers[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${p.year}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.authors.take(2).join(', ') + (p.authors.length > 2 ? ' et al.' : ''),
                                style: const TextStyle(color: Colors.white38, fontSize: 9),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.abstractText.isNotEmpty
                                    ? (p.abstractText.length > 100 ? '${p.abstractText.substring(0, 100)}...' : p.abstractText)
                                    : 'Abstrak tidak tersedia.',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                              ),
                              if (p.url.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => launchUrl(p.url),
                                  child: const Text(
                                    'Link Journal ↗',
                                    style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                )
                              ]
                            ],
                          );
                        },
                      ),
              ),

              // Citations Generator
              _buildDashboardCard(
                title: 'Generator Sitasi Jurnal',
                icon: Icons.format_quote,
                child: Column(
                  children: [
                    // Citation Tabs Row inside Desktop
                    Row(
                      children: ['apa', 'mla', 'ieee'].map((fmt) {
                        final isAct = state.citationFormat == fmt;
                        return Expanded(
                          child: InkWell(
                            onTap: () => state.setCitationFormat(fmt),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              margin: const EdgeInsets.symmetric(horizontal: 2.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isAct ? const Color(0xFF1E1B3E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAct ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Text(
                                fmt.toUpperCase(),
                                style: TextStyle(
                                  color: isAct ? Colors.white : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Citations Copy items
                    Expanded(
                      child: vData.papers.isEmpty
                          ? const Center(child: Text('Tidak ada sitasi.', style: TextStyle(color: Colors.white38, fontSize: 11)))
                          : ListView.separated(
                              itemCount: vData.papers.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final paper = vData.papers[index];
                                final cit = vData.citations[paper.id];
                                
                                String text = 'Sitasi tidak tersedia.';
                                if (cit != null) {
                                  if (state.citationFormat == 'apa') text = cit.apa;
                                  if (state.citationFormat == 'mla') text = cit.mla;
                                  if (state.citationFormat == 'ieee') text = cit.ieee;
                                }

                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              paper.title,
                                              style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              text,
                                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 14, color: Color(0xFF6366F1)),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: text));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Sitasi berhasil disalin ke clipboard!', style: TextStyle(fontSize: 12)),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13102B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// GAUGES PAINTER (Score percentage circular visualization)
// -----------------------------------------------------------------------------
class GaugePainter extends CustomPainter {
  final double score; // ranges from -100 to 100 (or 0 to 100)
  final Color color;

  GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius - 4, trackPaint);

    // Active Arc Paint
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Normalize score (-100 to 100) to (0 to 100) for representation if needed
    // However, if the score is already 0 to 100 positive percentiles:
    final double normalized = score.clamp(0, 100);
    final sweepAngle = (normalized / 100.0) * 2 * 3.14159265;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -3.14159265 / 2, // starts from top
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper method to open URLs conditionally via JS
void launchUrl(String url) {
  launchBrowser(url);
}
