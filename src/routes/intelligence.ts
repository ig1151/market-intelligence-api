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
