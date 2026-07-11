import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/chat_message.dart';
import '../models/verification_models.dart';
import 'api_service.dart';

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
