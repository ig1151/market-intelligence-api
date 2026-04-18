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
