import OpenAI from "openai";
    
export class ClaimService {
    private openai: OpenAI | null = null;

    private getOpenAIInstance(): OpenAI {
        if (!this.openai) {
            const apiKey = process.env.OPENAI_API_KEY;
            if (!apiKey || apiKey === '' || apiKey === 'your_openai_api_key_here') {
                throw new Error('OPENAI_API_KEY belum dikonfigurasi. Harap isi API Key valid di file .env');
            }
            this.openai = new OpenAI({ apiKey });
        }
        return this.openai;
    }

    async extractClaims(answer: string): Promise<string[]> {
        if (!answer || answer.trim() === '') {
            throw new Error('Answer cannot be empty');
        }

        try {
            const client = this.getOpenAIInstance();

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