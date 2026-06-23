import { Request, Response } from 'express';
import { ClaimService } from '../services/claimService';

const claimService = new ClaimService();

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

    // Ekstraksi klaim menggunakan OpenAI
    const claims = await claimService.extractClaims(answer);

    res.status(200).json({
        status: 'success',
        data: {
        claims,
        papers: {},      // Akan diisi oleh Evidence Service di langkah berikutnya
        consensus: {},   // Akan diisi oleh Consensus Service di Sprint 2
        blindSpot: {},   // Akan diisi oleh Blind Spot Service di Sprint 2
        citations: {}    // Akan diisi oleh Citation Service di Sprint 2
        }
    });
    } catch (error: any) {
    res.status(500).json({
        status: 'error',
        message: error.message || 'Internal Server Error during verification'
    });
    }
};