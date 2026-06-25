import axios from 'axios';
    
export interface Paper {
    id: string;
    claim: string; // Menyimpan klaim terkait agar tahu paper ini mendukung klaim mana
    title: string;
    authors: string[];
    year: number;
    doi: string | null;
    url: string;
    abstract: string;
    countries: string[]; // Menampung kode negara asal institusi riset (e.g. US, ID, GB)
}

export class EvidenceService {
    private baseUrl = 'https://api.openalex.org';

    async findEvidence(claim: string): Promise<Paper[]> {
    if (!claim || claim.trim() === '') {
        return [];
    }

    try {
        const email = process.env.OPENALEX_EMAIL;
        // Gunakan User-Agent yang sopan agar masuk ke "polite pool" OpenAlex (gratis & cepat)
        const headers: Record<string, string> = {
        'User-Agent': `Verivio/1.0 (${email ? `mailto:${email}` : 'anonymous@verivio.com'})`
        };

        // Panggil OpenAlex API (cari work/paper berdasarkan teks klaim)
        const response = await axios.get(`${this.baseUrl}/works`, {
        params: {
            search: claim,
            per_page: 5, // Batasi 5 paper teratas saja per klaim agar performa tetap cepat
        },
        headers,
        timeout: 5000 // Timeout 5 detik agar tidak menggantung terlalu lama
        });

        const results = response.data.results || [];

        return results.map((work: any) => {
        // Ambil display name para penulis
        const authors = (work.authorships || []).map(
            (auth: any) => auth.author?.display_name || 'Unknown Author'
        );

        // Ambil kode negara institusi penulis
        const countries: string[] = [];
        (work.authorships || []).forEach((auth: any) => {
            (auth.institutions || []).forEach((inst: any) => {
                if (inst.country_code && !countries.includes(inst.country_code)) {
                    countries.push(inst.country_code);
                }
            });
        });

        // OpenAlex mengembalikan abstrak dalam bentuk inverted index. 
        // Kita butuh merekonstruksinya menjadi teks utuh untuk analisis konsensus nanti.
        const abstract = this.reconstructAbstract(work.abstract_inverted_index);

        return {
            id: work.id || '',
            claim: claim,
            title: work.title || 'Untitled',
            authors,
            year: work.publication_year || 0,
            doi: work.doi || null,
            url: work.primary_location?.landing_page_url || work.doi || '',
            abstract,
            countries
        };
        });
    } catch (error) {
        console.error(`Error in EvidenceService.findEvidence untuk klaim "${claim}":`, error);
        // Jika terjadi error pada satu klaim, kembalikan array kosong agar proses klaim lain tidak terhenti
        return [];
    }
    }

    // Fungsi utilitas merekonstruksi abstrak dari data inverted index OpenAlex
    private reconstructAbstract(invertedIndex: Record<string, number[]> | null | undefined): string {
    if (!invertedIndex) return '';
    
    try {
        const words: string[] = [];
        for (const [word, positions] of Object.entries(invertedIndex)) {
        for (const pos of positions) {
            words[pos] = word;
        }
        }
        // Hapus nilai undefined/kosong dan gabungkan menjadi kalimat
        return words.filter(w => w !== undefined).join(' ');
    } catch (e) {
        console.error('Error reconstructing abstract:', e);
        return '';
    }
    }
}