import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_state.dart';
import '../../models/verification_models.dart';
import '../../widgets/gauge_painter.dart';
import '../../utils/launcher.dart';

class Screen3OverlayDrawer extends StatelessWidget {
  final AppState state;
  const Screen3OverlayDrawer({super.key, required this.state});

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
