import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Health Check Endpoint
app.get('/api/v1/health', (req: Request, res: Response) => {
    res.status(200).json({
    status: 'success',
    message: 'VERITY API is healthy and running',
    timestamp: new Date().toISOString()
    });
});

// Global Error Handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err.stack);
    res.status(500).json({
    status: 'error',
    message: err.message || 'Internal Server Error'
    });
});

export default app;