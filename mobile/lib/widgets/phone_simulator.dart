import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../screens/phone/screen1_ai_selector.dart';
import '../screens/phone/screen2_chat_simulator.dart';
import '../screens/phone/screen3_overlay_drawer.dart';

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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '9:41',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.wifi, color: Color(0xFF1A1A1A), size: 14),
                        SizedBox(width: 6),
                        Icon(Icons.battery_std, color: Color(0xFF1A1A1A), size: 14),
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF534AB7)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Memverifikasi...',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
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
        return Screen1AISelector(state: state);
      case 2:
      case 3:
        return Stack(
          children: [
            Screen2ChatSimulator(state: state),
            if (state.screenIndex == 3)
              Screen3OverlayDrawer(state: state),
          ],
        );
      default:
        return Screen1AISelector(state: state);
    }
  }
}
