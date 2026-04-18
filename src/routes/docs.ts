import { Router, Request, Response } from 'express';
const router = Router();

router.get('/', (_req: Request, res: Response) => {
  res.json({
    service: 'Market Intelligence API',
    version: '1.0.0',
    description: 'Combines market decision signals with trust scoring for smarter trading decisions.',
    endpoints: [
      { method: 'GET', path: '/v1/analyze/{ticker}', description: 'Full market intelligence report combining market decision and trust score' },
      { method: 'GET', path: '/v1/health', description: 'Health check' },
      { method: 'GET', path: '/docs', description: 'Documentation' },
      { method: 'GET', path: '/openapi.json', description: 'OpenAPI spec' }
    ],
    verdicts: {
      proceed: 'Strong signal + high trust — safe to act',
      proceed_with_caution: 'Good signal but monitor trust indicators',
      wait: 'Mixed signals — wait for confluence',
      avoid: 'Low trust conflicts with market signal — stay out'
    },
    example: 'GET /v1/analyze/AAPL'
  });
});

export default router;
