import { GoogleGenerativeAI } from "@google/generative-ai";
import { Paper } from "./evidenceService";

export interface ConsensusResult {
  score: number;
  level: "High" | "Medium" | "Low" | "Weak" | "Contradictory";
  support: number;
  neutral: number;
  oppose: number;
  total: number;
}

export class ConsensusService {
  private genAI: GoogleGenerativeAI | null = null;

  private getGeminiInstance(): GoogleGenerativeAI | null {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey === '' || apiKey === 'isi_dengan_api_key_gemini_kamu') {
      return null;
    }
    if (!this.genAI) {
      this.genAI = new GoogleGenerativeAI(apiKey);
    }
    return this.genAI;
  }

  async analyzeConsensus(claim: string, papers: Paper[]): Promise<ConsensusResult> {
    const total = papers.length;
    if (total === 0) {
      return { score: 0, level: "Weak", support: 0, neutral: 0, oppose: 0, total: 0 };
    }

    const client = this.getGeminiInstance();

    // JIKA MOCK MODE AKTIF SEJAK AWAL
    if (!client) {
      return this.getMockConsensus(total);
    }

    try {
      const modelName = process.env.GEMINI_MODEL || "gemini-2.5-flash";
      const model = client.getGenerativeModel({
        model: modelName,
        generationConfig: {
          responseMimeType: "application/json"
        }
      });

      const paperListText = papers.map((p, idx) => `
Paper ID: ${p.id}
Title: ${p.title}
Abstract: ${p.abstract || "No abstract available"}
---`).join('\n');

      const prompt = `You are a scientific consensus analyzer. Your task is to evaluate a list of scientific papers and classify their relationship to a specific claim.
The claim is: "${claim}"

Here is the list of papers:
${paperListText}

For each paper, classify it into one of these three categories:
1. "support": The paper's abstract supports, confirms, or agrees with the claim.
2. "oppose": The paper's abstract contradicts, disproves, or disagrees with the claim.
3. "neutral": The paper's abstract does not take a stance, is irrelevant, or has insufficient evidence to support or oppose the claim.

You must respond with a JSON object where the keys are the "Paper ID" values and the values are the classification string ("support", "oppose", or "neutral").
Example output:
{
  "https://openalex.org/W12345": "support",
  "https://openalex.org/W67890": "neutral"
}`;

      const result = await model.generateContent(prompt);
      const responseText = result.response.text();
      
      if (!responseText) {
        throw new Error('No content returned from Gemini API in Consensus Service');
      }

      const classifications = JSON.parse(responseText);

      let support = 0;
      let oppose = 0;
      let neutral = 0;

      papers.forEach(p => {
        const category = classifications[p.id];
        if (category === 'support') support++;
        else if (category === 'oppose') oppose++;
        else neutral++;
      });

      const score = Math.round(((support - oppose) / total) * 100);

      return {
        score,
        level: this.determineLevel(score),
        support,
        neutral,
        oppose,
        total
      };
    } catch (error) {
      // AUTOMATIC FALLBACK JIKA GEMINI LIMIT (429)
      console.warn(`⚠️ Gemini API error in ConsensusService (mungkin limit/429) untuk klaim "${claim}". Otomatis dialihkan ke MOCK MODE:`, error);
      return this.getMockConsensus(total);
    }
  }

  private getMockConsensus(total: number): ConsensusResult {
    console.log('💡 Menyajikan Mock Consensus untuk menyiasati limit Gemini.');
    const support = Math.ceil(total * 0.6); // 60% support
    const oppose = Math.floor(total * 0.1);  // 10% oppose
    const neutral = total - support - oppose;
    const score = Math.round(((support - oppose) / total) * 100);
    return {
      score,
      level: this.determineLevel(score),
      support,
      neutral,
      oppose,
      total
    };
  }

  private determineLevel(score: number): "High" | "Medium" | "Low" | "Weak" | "Contradictory" {
    if (score >= 80) return "High";
    if (score >= 50) return "Medium";
    if (score >= 20) return "Low";
    if (score >= 0) return "Weak";
    return "Contradictory";
  }
}
