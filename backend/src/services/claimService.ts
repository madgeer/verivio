import OpenAI from "openai";
    
export class ClaimService {
    private openai: OpenAI | null = null;

    private getOpenAIInstance(): OpenAI | null {    
        const apiKey = process.env.OPENAI_API_KEY;
        
        // Jika API Key kosong atau masih berupa placeholder, kembalikan null (aktifkan Mock Mode)
        if (!apiKey || apiKey === '' || apiKey === 'your_openai_api_key_here') {
            return null;
        }

        if (!this.openai) {
            this.openai = new OpenAI({ apiKey });
        }
        return this.openai;
    }

    async extractClaims(answer: string): Promise<string[]> {
        if (!answer || answer.trim() === '') {
            throw new Error('Answer cannot be empty');
        }

        const client = this.getOpenAIInstance();

        // JIKA MOCK MODE AKTIF (client bernilai null)
        if (!client) {
            console.log('⚠️ OPENAI_API_KEY tidak ditemukan. Berjalan dalam MOCK MODE.');
            
            const lowerAnswer = answer.toLowerCase();
            
            // Berikan klaim tiruan yang realistis jika membahas tentang media sosial
            if (lowerAnswer.includes('media sosial') || lowerAnswer.includes('sosmed') || lowerAnswer.includes('depresi')) {
                return [
                    "Penggunaan media sosial berlebihan berpengaruh negatif terhadap kesehatan mental remaja",
                    "Penggunaan media sosial lebih dari 3 jam per hari meningkatkan risiko depresi",
                    "Remaja perempuan lebih rentan terhadap dampak negatif media sosial"
                ];
            }
            
            // Default mock claims jika topiknya umum
            return [
                "Konsumsi kafein berlebihan meningkatkan risiko gangguan tidur",
                "Kualitas tidur yang buruk mempengaruhi fokus dan memori jangka pendek"
            ];
        }

        // JIKA API KEY ADA (Panggil OpenAI asli)
        try {
            const response = await client.chat.completions.create({
                model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert scientific claim extractor. Your task is to analyze the provided text (which is an AI's
                                    answer to a query) and break it down into a list of independent, testable scientific claims.
                                    For each claim, write it as a concise, clear sentence.
                                    Avoid extracting personal opinions, subjective statements, or general pleasantries. Focus only on factual and testable assertions.
                                    You must respond with a JSON object containing a single key "claims" which is an array of strings.
                                    Example output format:
                                    {
                                        "claims": ["Claim 1", "Claim 2"]
                                    }`
                    },
                    {
                        role: 'user',
                        content: `Extract claims from the following text:\n\n${answer}`
                    }
                ],
                response_format: {type: 'json_object'}
            });

            const content = response.choices[0]?.message?.content;
            if(!content) {
                throw new Error('No content returned from OpenAI API');
            }

            const parsed = JSON.parse(content);
            if(!parsed.claims || !Array.isArray(parsed.claims)) {
                throw new Error('Invalid JSON structure returned from OpenAI')
            }
            return parsed.claims;
        } catch (error) {
            console.error('Error in ClaimService.extractClaims:', error);
            throw error;
        }
    }
}