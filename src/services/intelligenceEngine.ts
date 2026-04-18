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
