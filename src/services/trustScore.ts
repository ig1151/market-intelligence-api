import axios from 'axios';
import { TrustResult } from '../types';

export async function getTrustScore(identifier: string): Promise<TrustResult> {
  const baseUrl = process.env.TRUST_API_URL;
  if (!baseUrl) throw new Error('TRUST_API_URL not configured');

  const response = await axios.post(
    `${baseUrl}/v1/assess`,
    { email: `${identifier.toLowerCase()}@marketcheck.com` },
    { timeout: 15000 }
  );

  const data = response.data;
  return {
    trust_score: data.trust_score ?? 50,
    trust_label: data.trust_level ?? 'neutral',
    risk_level: data.recommendation ?? 'verify',
    summary: data.summary ?? ''
  };
}