import { GoogleGenerativeAI } from "@google/generative-ai";
import { Paper } from "./evidenceService";

export interface BlindSpotResult {
  dominantRegions: string[];
  underrepresentedRegions: string[];
  distribution: Record<string, number>;
  summary: string;
}

export class BlindSpotService {
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

  private regionMap: Record<string, string> = {
    // North America
    US: "North America", CA: "North America",
    // Europe
    GB: "Europe", DE: "Europe", FR: "Europe", IT: "Europe", ES: "Europe", NL: "Europe",
    SE: "Europe", CH: "Europe", NO: "Europe", FI: "Europe", DK: "Europe", IE: "Europe",
    BE: "Europe", AT: "Europe", PL: "Europe", RU: "Europe",
    // Southeast Asia
    ID: "Southeast Asia", SG: "Southeast Asia", MY: "Southeast Asia", PH: "Southeast Asia",
    TH: "Southeast Asia", VN: "Southeast Asia", KH: "Southeast Asia", LA: "Southeast Asia",
    // East Asia
    CN: "East Asia", JP: "East Asia", KR: "East Asia", TW: "East Asia",
    // South Asia
    IN: "South Asia", PK: "South Asia", BD: "South Asia",
    // Latin America
    BR: "Latin America", MX: "Latin America", AR: "Latin America", CO: "Latin America",
    // Oceania
    AU: "Oceania", NZ: "Oceania",
    // Middle East
    IL: "Middle East", TR: "Middle East", SA: "Middle East", AE: "Middle East",
    // Africa
    ZA: "Africa", NG: "Africa", EG: "Africa", KE: "Africa"
  };

  async detectBlindSpots(papers: Paper[]): Promise<BlindSpotResult> {
    const distribution: Record<string, number> = {};
    let totalInstitutions = 0;

    papers.forEach(paper => {
      if (!paper.countries || paper.countries.length === 0) {
        distribution["Unknown"] = (distribution["Unknown"] || 0) + 1;
        totalInstitutions++;
        return;
      }

      paper.countries.forEach(code => {
        const region = this.regionMap[code.toUpperCase()] || "Other Regions";
        distribution[region] = (distribution[region] || 0) + 1;
        totalInstitutions++;
      });
    });

    const dominantRegions: string[] = [];
    const threshold = totalInstitutions > 0 ? totalInstitutions * 0.4 : 0;
    Object.entries(distribution).forEach(([region, count]) => {
      if (region !== "Unknown" && count > threshold) {
        dominantRegions.push(region);
      }
    });

    const allExpectedRegions = ["North America", "Europe", "Southeast Asia", "East Asia", "South Asia", "Latin America", "Africa"];
    const underrepresentedRegions = allExpectedRegions.filter(
      region => !distribution[region] || distribution[region] === 0
    );

    const client = this.getGeminiInstance();

    // JIKA MOCK MODE AKTIF SEJAK AWAL
    if (!client) {
      return this.getMockBlindSpot(underrepresentedRegions, dominantRegions, distribution);
    }

    // JIKA GEMINI API AKTIF
    try {
      const modelName = process.env.GEMINI_MODEL || "gemini-2.5-flash";
      const model = client.getGenerativeModel({
        model: modelName
      });

      const statsText = Object.entries(distribution)
        .map(([region, count]) => `- ${region}: ${count} institusi`)
        .join('\n');

      const paperTitlesText = papers.map(p => `- ${p.title} (${p.countries.join(', ') || 'No Country Data'})`).join('\n');

      const prompt = `You are an academic bias and research blind spot analyzer. Your task is to analyze the geographic distribution of institutions involved in a set of research papers and write a concise, professional warning/alert summary (maximum 2 sentences, in Indonesian) about the research bias.

Geographic distribution of research institutions:
${statsText}

List of research papers analyzed:
${paperTitlesText}

Identify if the research is heavily skewed towards certain regions (e.g. North America, Europe) and which regions are neglected (especially Southeast Asia, Africa, or Latin America). Write a warning in Indonesian.

Example format:
"Penelitian sangat didominasi oleh institusi di Amerika Utara dan Eropa. Perspektif dari Asia Tenggara belum terwakili dalam studi ini."`;

      const result = await model.generateContent(prompt);
      const summary = result.response.text().trim();

      return {
        dominantRegions,
        underrepresentedRegions,
        distribution,
        summary
      };
    } catch (error) {
      // AUTOMATIC FALLBACK JIKA GEMINI LIMIT (429)
      console.warn("⚠️ Gemini API error in BlindSpotService (mungkin limit/429). Otomatis dialihkan ke MOCK MODE:", error);
      return this.getMockBlindSpot(underrepresentedRegions, dominantRegions, distribution);
    }
  }

  private getMockBlindSpot(underrepresentedRegions: string[], dominantRegions: string[], distribution: Record<string, number>): BlindSpotResult {
    console.log('💡 Menyajikan Mock Blind Spot untuk menyiasati limit Gemini.');
    let summary = "Penelitian didominasi oleh institusi global. ";
    if (underrepresentedRegions.includes("Southeast Asia")) {
      summary += "Perspektif dari Asia Tenggara (termasuk Indonesia) belum terwakili secara signifikan dalam sampel penelitian ini.";
    } else {
      summary += "Distribusi penelitian cukup tersebar namun masih terpusat di wilayah akademis utama.";
    }

    return {
      dominantRegions,
      underrepresentedRegions,
      distribution,
      summary
    };
  }
}
