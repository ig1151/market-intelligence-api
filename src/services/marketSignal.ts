import axios from 'axios';
import { MarketDecision } from '../types';

export async function getMarketDecision(ticker: string): Promise<MarketDecision> {
  const baseUrl = process.env.MARKET_SIGNAL_API_URL;
  if (!baseUrl) throw new Error('MARKET_SIGNAL_API_URL not configured');

  const response = await axios.get(`${baseUrl}/v1/signal/${ticker}`, { timeout: 15000 });
  return response.data;
}
