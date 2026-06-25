class Paper {
  final String id;
  final String title;
  final List<String> authors;
  final int year;
  final String doi;
  final String url;
  final String abstractText;
  final List<String> countries;

  Paper({
    required this.id,
    required this.title,
    required this.authors,
    required this.year,
    required this.doi,
    required this.url,
    required this.abstractText,
    required this.countries,
  });

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      authors: List<String>.from(json['authors'] ?? []),
      year: json['year'] ?? 0,
      doi: json['doi'] ?? '',
      url: json['url'] ?? '',
      abstractText: json['abstract'] ?? '',
      countries: List<String>.from(json['countries'] ?? []),
    );
  }
}

class ConsensusResult {
  final int score;
  final String level;
  final int support;
  final int neutral;
  final int oppose;
  final int total;

  ConsensusResult({
    required this.score,
    required this.level,
    required this.support,
    required this.neutral,
    required this.oppose,
    required this.total,
  });

  factory ConsensusResult.fromJson(Map<String, dynamic> json) {
    return ConsensusResult(
      score: json['score'] ?? 0,
      level: json['level'] ?? 'Weak',
      support: json['support'] ?? 0,
      neutral: json['neutral'] ?? 0,
      oppose: json['oppose'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class BlindSpotResult {
  final Map<String, int> distribution;
  final String summary;

  BlindSpotResult({
    required this.distribution,
    required this.summary,
  });

  factory BlindSpotResult.fromJson(Map<String, dynamic> json) {
    final Map<String, int> dist = {};
    if (json['distribution'] != null) {
      json['distribution'].forEach((key, value) {
        dist[key] = (value as num).toInt();
      });
    }
    return BlindSpotResult(
      distribution: dist,
      summary: json['summary'] ?? json['warning'] ?? '', // Handle both fields
    );
  }
}

class Citation {
  final String apa;
  final String mla;
  final String ieee;

  Citation({
    required this.apa,
    required this.mla,
    required this.ieee,
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      apa: json['apa'] ?? '',
      mla: json['mla'] ?? '',
      ieee: json['ieee'] ?? '',
    );
  }
}

class VerificationData {
  final List<String> claims;
  final List<Paper> papers;
  final Map<String, ConsensusResult> consensus;
  final BlindSpotResult blindSpot;
  final Map<String, Citation> citations;

  VerificationData({
    required this.claims,
    required this.papers,
    required this.consensus,
    required this.blindSpot,
    required this.citations,
  });

  factory VerificationData.fromJson(Map<String, dynamic> json) {
    // Parse claims
    final claims = List<String>.from(json['claims'] ?? []);
    
    // Parse papers
    final List<Paper> papersList = [];
    if (json['papers'] != null) {
      json['papers'].forEach((v) {
        papersList.add(Paper.fromJson(v));
      });
    }

    // Parse consensus map
    final Map<String, ConsensusResult> consensusMap = {};
    if (json['consensus'] != null) {
      json['consensus'].forEach((key, value) {
        consensusMap[key] = ConsensusResult.fromJson(value);
      });
    }

    // Parse blindSpot
    final blindSpot = BlindSpotResult.fromJson(json['blindSpot'] ?? {});

    // Parse citations map
    final Map<String, Citation> citationsMap = {};
    if (json['citations'] != null) {
      json['citations'].forEach((key, value) {
        citationsMap[key] = Citation.fromJson(value);
      });
    }

    return VerificationData(
      claims: claims,
      papers: papersList,
      consensus: consensusMap,
      blindSpot: blindSpot,
      citations: citationsMap,
    );
  }
}
