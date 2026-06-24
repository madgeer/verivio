import { Request, Response } from 'express';
import { ClaimService } from '../services/claimService';
import { EvidenceService, Paper } from '../services/evidenceService';
import { ConsensusService, ConsensusResult } from '../services/consensusService';
import { BlindSpotService } from '../services/blindSpotService';
import { CitationService } from '../services/citationService';

const claimService = new ClaimService();
const evidenceService = new EvidenceService();
const consensusService = new ConsensusService();
const blindSpotService = new BlindSpotService();
const citationService = new CitationService();

export const verifyAnswer = async (req: Request, res: Response): Promise<void> => {
  try {
    const { answer } = req.body;

    if (!answer || typeof answer !== 'string') {
      res.status(400).json({
        status: 'error',
        message: 'Request body must contain an "answer" string'
      });
      return;
    }

    // Step 1: Ekstraksi klaim menggunakan Gemini (atau Mock Mode)
    const claims = await claimService.extractClaims(answer);

    // Step 2: Cari paper secara paralel untuk setiap klaim
    const paperPromises = claims.map(claim => evidenceService.findEvidence(claim));
    const paperResults = await Promise.all(paperPromises);

    // Satukan semua paper ke dalam satu list datar (flat array)
    const allPapers: Paper[] = paperResults.flat();

    // Step 3: Hitung konsensus untuk setiap klaim secara paralel
    const consensusPromises = claims.map(async (claim, idx) => {
      const papersForClaim = paperResults[idx];
      const result = await consensusService.analyzeConsensus(claim, papersForClaim);
      return { claim, result };
    });
    const consensusResultsArray = await Promise.all(consensusPromises);
    
    // Konversi hasil array ke format Map/Object { [claim]: ConsensusResult }
    const consensus: Record<string, ConsensusResult> = {};
    consensusResultsArray.forEach(item => {
      consensus[item.claim] = item.result;
    });

    // Step 4: Analisis Blind Spot (bias geografis) untuk seluruh paper gabungan
    const blindSpot = await blindSpotService.detectBlindSpots(allPapers);

    // Step 5: Buat sitasi (APA, MLA, IEEE) untuk setiap paper
    const citations = await citationService.generateCitations(allPapers);

    res.status(200).json({
      status: 'success',
      data: {
        claims,
        papers: allPapers,
        consensus,
        blindSpot,
        citations
      }
    });
  } catch (error: any) {
    res.status(500).json({
      status: 'error',
      message: error.message || 'Internal Server Error during verification'
    });
  }
};