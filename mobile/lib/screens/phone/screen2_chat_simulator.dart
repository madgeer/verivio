import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/chat_message.dart';
import '../../services/app_state.dart';

class Screen2ChatSimulator extends StatefulWidget {
  final AppState state;
  const Screen2ChatSimulator({super.key, required this.state});

  @override
  State<Screen2ChatSimulator> createState() => _Screen2ChatSimulatorState();
}

class _Screen2ChatSimulatorState extends State<Screen2ChatSimulator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _chatController = TextEditingController();
  WebViewController? _webViewController;
  double? _verifyButtonX;
  double? _verifyButtonY;

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
  void didUpdateWidget(covariant Screen2ChatSimulator oldWidget) {
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

            // Floating Verify Button (Draggable)
            Positioned(
              left: _verifyButtonX,
              top: _verifyButtonY,
              right: _verifyButtonX == null ? 14 : null,
              bottom: _verifyButtonX == null ? 74 : null,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final size = MediaQuery.of(context).size;
                    _verifyButtonX = (_verifyButtonX ?? size.width - 120) + details.delta.dx;
                    _verifyButtonY = (_verifyButtonY ?? size.height - 140) + details.delta.dy;
                    _verifyButtonX = _verifyButtonX!.clamp(0.0, size.width - 110);
                    _verifyButtonY = _verifyButtonY!.clamp(0.0, size.height - 60);
                  });
                },
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

            // Floating pulse Verify button on top of WebView (Draggable)
            Positioned(
              left: _verifyButtonX,
              top: _verifyButtonY,
              right: _verifyButtonX == null ? 14 : null,
              bottom: _verifyButtonX == null ? 24 : null,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final size = MediaQuery.of(context).size;
                    _verifyButtonX = (_verifyButtonX ?? size.width - 120) + details.delta.dx;
                    _verifyButtonY = (_verifyButtonY ?? size.height - 90) + details.delta.dy;
                    _verifyButtonX = _verifyButtonX!.clamp(0.0, size.width - 110);
                    _verifyButtonY = _verifyButtonY!.clamp(0.0, size.height - 60);
                  });
                },
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
              ),
            )
          ],
        ),
      );
    }
  }
}
