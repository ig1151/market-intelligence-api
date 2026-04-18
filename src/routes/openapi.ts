import { Router, Request, Response } from 'express';
const router = Router();

router.get('/', (_req: Request, res: Response) => {
  res.json({
    openapi: '3.0.0',
    info: { title: 'Market Intelligence API', version: '1.0.0', description: 'Market decision + trust scoring mashup for smarter trading decisions' },
    servers: [{ url: 'https://market-intelligence-api.onrender.com' }],
    paths: {
      '/v1/analyze/{ticker}': {
        get: {
          summary: 'Get full market intelligence for a ticker',
          parameters: [{ name: 'ticker', in: 'path', required: true, schema: { type: 'string' }, example: 'AAPL' }],
          responses: {
            '200': { description: 'Intelligence response' },
            '400': { description: 'Invalid ticker' },
            '404': { description: 'Asset not found' },
            '429': { description: 'Rate limit exceeded' }
          }
        }
      },
      '/v1/health': {
        get: { summary: 'Health check', responses: { '200': { description: 'OK' } } }
      }
    }
  });
});

export default router;
