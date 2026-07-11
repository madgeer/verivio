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

    // Step 2: Cari paper secara sekuensial untuk setiap klaim (menghindari rate limit OpenAlex)
    const paperResults: Paper[][] = [];
    for (const claim of claims) {
      const papers = await evidenceService.findEvidence(claim);
      paperResults.push(papers);
      // Jeda 100ms untuk menjaga rate limit tetap di bawah 10 request/detik
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Satukan semua paper ke dalam satu list datar (flat array)
    const allPapers: Paper[] = paperResults.flat();

    // Step 3: Hitung konsensus untuk seluruh klaim secara batch (hanya 1 request ke Gemini)
    const consensus = await consensusService.analyzeBatchConsensus(claims, paperResults);

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

export const chatAI = async (req: Request, res: Response): Promise<void> => {
  try {
    const { prompt } = req.body;
    if (!prompt || typeof prompt !== 'string') {
      res.status(400).json({ status: 'error', message: 'Request body must contain a "prompt" string' });
      return;
    }

    const apiKey = process.env.GEMINI_API_KEY;
    const isMock = !apiKey || apiKey === '' || apiKey === 'isi_dengan_api_key_gemini_kamu';
    
    if (isMock) {
      const mockAns = getMockChatResponse(prompt);
      res.status(200).json({ status: 'success', answer: mockAns });
      return;
    }

    const { GoogleGenerativeAI } = require("@google/generative-ai");
    const genAI = new GoogleGenerativeAI(apiKey);
    const modelName = process.env.GEMINI_MODEL || "gemini-2.5-flash";
    const model = genAI.getGenerativeModel({ model: modelName });
    
    const geminiPrompt = `You are a helpful AI assistant. Answer the user query clearly and factually.
Keep your response concise (between 2 to 4 sentences).
Make sure to state specific facts or research if applicable, so they can be scientifically verified later.

User query: ${prompt}`;

    const result = await model.generateContent(geminiPrompt);
    const responseText = result.response.text();
    
    res.status(200).json({
      status: 'success',
      answer: responseText || getMockChatResponse(prompt)
    });
  } catch (error: any) {
    console.warn('⚠️ Gemini chat API error. Fallback to mock response:', error);
    res.status(200).json({
      status: 'success',
      answer: getMockChatResponse(req.body.prompt || '')
    });
  }
};

const getMockChatResponse = (prompt: string): string => {
  const query = prompt.toLowerCase();
  if (query.includes('kafein') || query.includes('kopi') || query.includes('tidur')) {
    return 'Konsumsi kafein berlebihan terbukti secara ilmiah mengganggu fase tidur dalam (deep sleep). Kafein bekerja dengan memblokir reseptor adenosin di otak, sehingga meningkatkan kewaspadaan. Hal ini berdampak negatif pada penurunan durasi tidur total dan memperburuk kualitas pemulihan fisik.';
  }
  if (query.includes('media sosial') || query.includes('sosmed') || query.includes('mental') || query.includes('remaja')) {
    return 'Penelitian psikologi menunjukkan bahwa penggunaan media sosial lebih dari 3 jam per hari meningkatkan risiko kecemasan dan depresi pada remaja. Algoritma visual dari media sosial memicu perbandingan sosial yang merugikan. Remaja perempuan dilaporkan memiliki kerentanan lebih tinggi dibandingkan remaja laki-laki.';
  }
  return `Terkait pertanyaan Anda tentang "${prompt}", riset ilmiah menunjukkan adanya hubungan yang relevan. Analisis eksperimental mengindikasikan korelasi positif terhadap variabel perilaku terkait. Namun, diperlukan studi komparatif lebih lanjut untuk memvalidasi efek jangka panjang secara menyeluruh.`;
};