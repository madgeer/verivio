import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import verifyRoute from './routes/verifyRoute';

// Initialize express app
const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/v1', verifyRoute);

// Health Check Endpoint
app.get('/api/v1/health', (req: Request, res: Response) => {
    res.status(200).json({
    status: 'success',
    message: 'Verivio API is healthy and running',
    timestamp: new Date().toISOString()
    });
});

// Serve Flutter Web Static Files in Production
const flutterWebBuildPath = path.join(__dirname, '../../mobile/build/web');
if (fs.existsSync(flutterWebBuildPath)) {
  console.log(`[Verivio] Serving Flutter Web production assets from: ${flutterWebBuildPath}`);
  app.use(express.static(flutterWebBuildPath));
  
  // SPA routing fallback (redirect non-API requests to index.html)
  app.get(/.*/, (req: Request, res: Response, next: NextFunction) => {
    if (req.url.startsWith('/api')) {
      return next();
    }
    res.sendFile(path.join(flutterWebBuildPath, 'index.html'));
  });
} else {
  console.warn(`[Verivio] Warning: Flutter web build folder not found at ${flutterWebBuildPath}. Running API services only.`);
}

// Global Error Handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err.stack);
    res.status(500).json({
    status: 'error',
    message: err.message || 'Internal Server Error'
    });
});

export default app;