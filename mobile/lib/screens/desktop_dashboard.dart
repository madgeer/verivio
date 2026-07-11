import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../models/verification_models.dart';
import '../widgets/gauge_painter.dart';
import '../utils/launcher.dart';

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
