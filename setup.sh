#!/bin/bash
set -e

mkdir -p src/{routes,middleware,services,utils,types}

cat > package.json << 'EOF'
{
  "name": "market-intelligence-api",
  "version": "1.0.0",
  "description": "Market decision + trust scoring mashup API. Combines technical signals with trust analysis for smarter trading decisions.",
  "main": "dist/index.js",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "compression": "^1.7.4",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "express-rate-limit": "^7.1.5",
    "helmet": "^7.1.0",
    "joi": "^17.11.0"
  },
  "devDependencies": {
    "@types/compression": "^1.7.5",
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.2"
  }
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

cat > render.yaml << 'EOF'
services:
  - type: web
    name: market-intelligence-api
    env: node
    buildCommand: npm install && npm run build
    startCommand: node dist/index.js
    healthCheckPath: /v1/health
    envVars:
      - key: NODE_ENV
        value: production
      - key: MARKET_SIGNAL_API_URL
        value: https://market-signal-api-iu2o.onrender.com
      - key: TRUST_API_URL
        value: https://trust-api-22r8.onrender.com
EOF

cat > .gitignore << 'EOF'
node_modules/
dist/
.env
*.log
EOF

cat > .env << 'EOF'
PORT=3000
MARKET_SIGNAL_API_URL=https://market-signal-api-iu2o.onrender.com
TRUST_API_URL=https://trust-api-22r8.onrender.com
EOF

cat > src/types/index.ts << 'EOF'
export interface MarketDecision {
  asset: string;
  decision: string;
  confidence: number;
  risk: string;
  action: string;
  verdict: string;
  trend: string;
  momentum: string;
  volatility: string;
  factors: {
    rsi: number;
    macd: string;
    volume_spike: boolean;
    ma_crossover: string;
    price_change_1d: number;
    price_change_7d: number;
    price_change_30d: number;
  };
  reasons: string[];
}

export interface TrustResult {
  trust_score: number;
  trust_label: string;
  risk_level: string;
  summary: string;
}

export interface IntelligenceResponse {
  asset: string;
  market_decision: string;
  market_confidence: number;
  market_risk: string;
  market_action: string;
  trust_score: number;
  trust_label: string;
  trust_risk: string;
  final_verdict: string;
  final_action: string;
  confidence: number;
  summary: string;
  signals: {
    trend: string;
    momentum: string;
    volatility: string;
    rsi: number;
    macd: string;
    volume_spike: boolean;
    ma_crossover: string;
    price_change_1d: number;
    price_change_7d: number;
    price_change_30d: number;
  };
  reasons: string[];
  analyzedAt: string;
}
EOF

cat > src/middleware/logger.ts << 'EOF'
export const logger = {
  info: (obj: unknown, msg?: string) =>
    console.log(JSON.stringify({ level: 'info', ...(typeof obj === 'object' ? obj : { data: obj }), msg })),
  warn: (obj: unknown, msg?: string) =>
    console.warn(JSON.stringify({ level: 'warn', ...(typeof obj === 'object' ? obj : { data: obj }), msg })),
  error: (obj: unknown, msg?: string) =>
    console.error(JSON.stringify({ level: 'error', ...(typeof obj === 'object' ? obj : { data: obj }), msg })),
};
EOF

cat > src/middleware/requestLogger.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { logger } from './logger';

export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  res.on('finish', () => {
    logger.info({ method: req.method, path: req.path, status: res.statusCode, ms: Date.now() - start });
  });
  next();
}
EOF

cat > src/middleware/rateLimiter.ts << 'EOF'
import rateLimit from 'express-rate-limit';

export const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many requests',
    message: 'Rate limit exceeded. Max 100 requests per 15 minutes.'
  }
});
EOF

cat > src/services/marketSignal.ts << 'EOF'
import axios from 'axios';
import { MarketDecision } from '../types';

export async function getMarketDecision(ticker: string): Promise<MarketDecision> {
  const baseUrl = process.env.MARKET_SIGNAL_API_URL;
  if (!baseUrl) throw new Error('MARKET_SIGNAL_API_URL not configured');

  const response = await axios.get(`${baseUrl}/v1/signal/${ticker}`, { timeout: 15000 });
  return response.data;
}
EOF

cat > src/services/trustScore.ts << 'EOF'
import axios from 'axios';
import { TrustResult } from '../types';

export async function getTrustScore(identifier: string): Promise<TrustResult> {
  const baseUrl = process.env.TRUST_API_URL;
  if (!baseUrl) throw new Error('TRUST_API_URL not configured');

  const response = await axios.get(`${baseUrl}/v1/trust/${identifier}`, { timeout: 15000 });
  return response.data;
}
EOF

cat > src/services/intelligenceEngine.ts << 'EOF'
import { MarketDecision, TrustResult, IntelligenceResponse } from '../types';

function combinedVerdict(decision: string, trustScore: number, marketRisk: string): string {
  const bullish = ['strong_buy', 'buy'].includes(decision);
  const bearish = ['strong_sell', 'sell'].includes(decision);
  const highTrust = trustScore >= 70;
  const lowTrust = trustScore < 40;
  const highRisk = marketRisk === 'high';

  if (bullish && highTrust && !highRisk) return 'proceed';
  if (bullish && highTrust && highRisk) return 'proceed_with_caution';
  if (bullish && lowTrust) return 'avoid';
  if (bullish && !highTrust) return 'proceed_with_caution';
  if (decision === 'neutral') return 'wait';
  if (bearish && lowTrust) return 'avoid';
  if (bearish) return 'avoid';
  return 'wait';
}

function combinedAction(verdict: string, decision: string, trustLabel: string): string {
  if (verdict === 'proceed') return `Strong ${decision.replace('_', ' ')} — high trust confirmed`;
  if (verdict === 'proceed_with_caution') return `${decision.replace('_', ' ')} with caution — monitor trust signals`;
  if (verdict === 'avoid') return `Avoid — ${trustLabel} trust score conflicts with market signal`;
  return 'Hold and wait for stronger confluence';
}

function combinedConfidence(marketConfidence: number, trustScore: number): number {
  const trustNorm = trustScore / 100;
  return Math.round(((marketConfidence + trustNorm) / 2) * 100) / 100;
}

function buildSummary(asset: string, decision: string, trustLabel: string, verdict: string): string {
  const decisionText = decision.replace('_', ' ');
  if (verdict === 'proceed') return `${asset} shows a ${decisionText} signal with ${trustLabel} trust. Safe to proceed.`;
  if (verdict === 'proceed_with_caution') return `${asset} shows a ${decisionText} signal but trust score warrants caution.`;
  if (verdict === 'avoid') return `${asset} market signal says ${decisionText} but low trust score. Avoid.`;
  return `${asset} shows mixed signals. Wait for stronger confluence before acting.`;
}

export function buildIntelligence(
  ticker: string,
  market: MarketDecision,
  trust: TrustResult
): IntelligenceResponse {
  const verdict = combinedVerdict(market.decision, trust.trust_score, market.risk);
  const finalAction = combinedAction(verdict, market.decision, trust.trust_label);
  const confidence = combinedConfidence(market.confidence, trust.trust_score);
  const summary = buildSummary(ticker, market.decision, trust.trust_label, verdict);

  return {
    asset: ticker.toUpperCase(),
    market_decision: market.decision,
    market_confidence: market.confidence,
    market_risk: market.risk,
    market_action: market.action,
    trust_score: trust.trust_score,
    trust_label: trust.trust_label,
    trust_risk: trust.risk_level,
    final_verdict: verdict,
    final_action: finalAction,
    confidence,
    summary,
    signals: {
      trend: market.trend,
      momentum: market.momentum,
      volatility: market.volatility,
      rsi: market.factors.rsi,
      macd: market.factors.macd,
      volume_spike: market.factors.volume_spike,
      ma_crossover: market.factors.ma_crossover,
      price_change_1d: market.factors.price_change_1d,
      price_change_7d: market.factors.price_change_7d,
      price_change_30d: market.factors.price_change_30d
    },
    reasons: market.reasons,
    analyzedAt: new Date().toISOString()
  };
}
EOF

cat > src/routes/health.ts << 'EOF'
import { Router, Request, Response } from 'express';
const router = Router();

router.get('/', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'market-intelligence-api',
    version: '1.0.0',
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString()
  });
});

export default router;
EOF

cat > src/routes/intelligence.ts << 'EOF'
import { Router, Request, Response } from 'express';
import Joi from 'joi';
import { getMarketDecision } from '../services/marketSignal';
import { getTrustScore } from '../services/trustScore';
import { buildIntelligence } from '../services/intelligenceEngine';
import { logger } from '../middleware/logger';

const router = Router();

const schema = Joi.object({
  ticker: Joi.string().alphanum().min(1).max(10).uppercase().required()
});

router.get('/:ticker', async (req: Request, res: Response): Promise<void> => {
  const { error, value } = schema.validate(req.params);
  if (error) {
    res.status(400).json({ error: 'Invalid ticker', message: error.details[0].message });
    return;
  }

  try {
    const [market, trust] = await Promise.all([
      getMarketDecision(value.ticker),
      getTrustScore(value.ticker)
    ]);

    const result = buildIntelligence(value.ticker, market, trust);
    res.json(result);
  } catch (err: any) {
    const msg: string = err.message || 'Unknown error';
    logger.error({ ticker: value.ticker, msg }, 'Intelligence error');
    if (msg.includes('404')) { res.status(404).json({ error: 'Asset not found', message: msg }); return; }
    if (msg.includes('429')) { res.status(429).json({ error: 'Rate limit', message: msg }); return; }
    res.status(500).json({ error: 'Internal server error', message: msg });
  }
});

export default router;
EOF

cat > src/routes/docs.ts << 'EOF'
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
EOF

cat > src/routes/openapi.ts << 'EOF'
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
EOF

cat > src/index.ts << 'EOF'
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { requestLogger } from './middleware/requestLogger';
import { rateLimiter } from './middleware/rateLimiter';
import intelligenceRouter from './routes/intelligence';
import healthRouter from './routes/health';
import docsRouter from './routes/docs';
import openapiRouter from './routes/openapi';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(requestLogger);
app.use(rateLimiter);

app.use('/v1/health', healthRouter);
app.use('/v1/analyze', intelligenceRouter);
app.use('/docs', docsRouter);
app.use('/openapi.json', openapiRouter);

app.get('/', (_req, res) => {
  res.json({
    service: 'Market Intelligence API',
    version: '1.0.0',
    docs: '/docs',
    health: '/v1/health',
    example: '/v1/analyze/AAPL'
  });
});

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(JSON.stringify({ level: 'info', msg: `Market Intelligence API running on port ${PORT}` }));
});

export default app;
EOF

echo "✅ All files created."
echo ""
echo "Next steps:"
echo "  1. npm install"
echo "  2. npm run dev"
echo "  3. curl http://localhost:3000/v1/analyze/AAPL"