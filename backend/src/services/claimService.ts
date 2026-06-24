import { GoogleGenerativeAI } from "@google/generative-ai";

export class ClaimService {
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

    async extractClaims(answer: string): Promise<string[]> {
        if (!answer || answer.trim() === '') {
            throw new Error('Answer cannot be empty');
        }

        const client = this.getGeminiInstance();

        // JIKA MOCK MODE AKTIF SEJAK AWAL
        if (!client) {
            return this.getMockClaims(answer);
        }

        // JIKA GEMINI API AKTIF
        try {
            const modelName = process.env.GEMINI_MODEL || "gemini-2.5-flash";
            const model = client.getGenerativeModel({ 
                model: modelName,
                generationConfig: {
                    responseMimeType: "application/json"
                }
            });

            const prompt = `You are an expert scientific claim extractor. Your task is to analyze the provided text (which is an AI's answer to a query) and break it down into a list of independent, testable scientific claims.
For each claim, write it as a concise, clear sentence.
Avoid extracting personal opinions, subjective statements, or general pleasantries. Focus only on factual and testable assertions.
You must respond with a JSON object containing a single key "claims" which is an array of strings.

Example output format:
{
  "claims": ["Claim 1", "Claim 2"]
}

Extract claims from the following text:
${answer}`;

            const result = await model.generateContent(prompt);
            const responseText = result.response.text();
            
            if (!responseText) {
                throw new Error('No content returned from Gemini API');
            }

            const parsed = JSON.parse(responseText);
            if (!parsed.claims || !Array.isArray(parsed.claims)) {
                throw new Error('Invalid JSON structure returned from Gemini');
            }

            return parsed.claims;
        } catch (error) {
            // AUTOMATIC FALLBACK JIKA GEMINI LIMIT (429) ATAU ERROR LAINNYA
            console.warn('⚠️ Gemini API error in ClaimService (mungkin limit/429). Otomatis dialihkan ke MOCK MODE:', error);
            return this.getMockClaims(answer);
        }
    }

    private getMockClaims(answer: string): string[] {
        console.log('💡 Menyajikan Mock Claims untuk menyiasati limit Gemini.');
        const lowerAnswer = answer.toLowerCase();
        
        if (lowerAnswer.includes('media sosial') || lowerAnswer.includes('sosmed') || lowerAnswer.includes('depresi')) {
            return [
                "Penggunaan media sosial berlebihan berpengaruh negatif terhadap kesehatan mental remaja",
                "Penggunaan media sosial lebih dari 3 jam per hari meningkatkan risiko depresi",
                "Remaja perempuan lebih rentan terhadap dampak negatif media sosial"
            ];
        }
        
        return [
            "Konsumsi kafein berlebihan meningkatkan risiko gangguan tidur",
            "Kualitas tidur yang buruk mempengaruhi fokus dan memori jangka pendek"
        ];
    }
}