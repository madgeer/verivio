import 'package:flutter/material.dart';
import '../../services/app_state.dart';

class Screen1AISelector extends StatelessWidget {
  final AppState state;
  const Screen1AISelector({super.key, required this.state});

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
