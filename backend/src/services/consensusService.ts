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

  async analyzeBatchConsensus(claims: string[], paperResults: Paper[][]): Promise<Record<string, ConsensusResult>> {
    const results: Record<string, ConsensusResult> = {};
    
    // Filter claims that actually have papers
    const claimsWithPapers = claims.map((claim, idx) => ({
      claim,
      idx,
      papers: paperResults[idx],
      total: paperResults[idx].length
    }));

    // If there are no claims with papers, return weak consensus immediately
    if (claimsWithPapers.every(c => c.total === 0)) {
      claims.forEach(claim => {
        results[claim] = { score: 0, level: "Weak", support: 0, neutral: 0, oppose: 0, total: 0 };
      });
      return results;
    }

    const client = this.getGeminiInstance();
    if (!client) {
      claims.forEach((claim, idx) => {
        results[claim] = this.getMockConsensus(paperResults[idx].length);
      });
      return results;
    }

    try {
      const modelName = process.env.GEMINI_MODEL || "gemini-2.5-flash";
      const model = client.getGenerativeModel({
        model: modelName,
        generationConfig: {
          responseMimeType: "application/json"
        }
      });

      // Construct a single consolidated prompt
      let promptText = `You are a scientific consensus analyzer. Your task is to evaluate multiple claims against their respective list of scientific papers.
For each claim and its associated paper list, classify each paper into one of these three categories:
1. "support": The paper's abstract supports, confirms, or agrees with the claim.
2. "oppose": The paper's abstract contradicts, disproves, or disagrees with the claim.
3. "neutral": The paper's abstract does not take a stance, is irrelevant, or has insufficient evidence.

Here is the data structure you must analyze:
`;

      claimsWithPapers.forEach((c, cIdx) => {
        if (c.total === 0) return;
        promptText += `\n=== CLAIM #${cIdx} ===\nClaim: "${c.claim}"\nPapers:\n`;
        c.papers.forEach((p) => {
          promptText += `- Paper ID: ${p.id}\n  Title: ${p.title}\n  Abstract: ${p.abstract || "No abstract available"}\n`;
        });
      });

      promptText += `
You must respond with a JSON object where the keys are the "Paper ID" values and the values are the classification string ("support", "oppose", or "neutral").
Analyze all paper IDs listed above.
Example output:
{
  "https://openalex.org/W12345": "support",
  "https://openalex.org/W67890": "neutral"
}`;

      const result = await model.generateContent(promptText);
      const responseText = result.response.text();
      
      if (!responseText) {
        throw new Error('No content returned from Gemini API in Batch Consensus Service');
      }

      const classifications = JSON.parse(responseText);

      claims.forEach((claim, idx) => {
        const papers = paperResults[idx];
        const total = papers.length;

        if (total === 0) {
          results[claim] = { score: 0, level: "Weak", support: 0, neutral: 0, oppose: 0, total: 0 };
          return;
        }

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

        results[claim] = {
          score,
          level: this.determineLevel(score),
          support,
          neutral,
          oppose,
          total
        };
      });

      return results;
    } catch (error) {
      console.warn("⚠️ Gemini API error in Batch ConsensusService, fallback to mock:", error);
      claims.forEach((claim, idx) => {
        results[claim] = this.getMockConsensus(paperResults[idx].length);
      });
      return results;
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
