import { prisma } from "./prisma.js";

/// Maximum outbound API calls allowed per calendar day.
const DAILY_BUDGET = 95; // keep 5 buffer below the 100-call free-plan limit

/// Throw this when the daily API budget is exhausted.
export class BudgetExceededError extends Error {
  constructor() {
    super("Daily API budget exceeded. Try again tomorrow or upgrade your plan.");
  }
}

/// Count outbound calls made today and throw if the budget is spent.
export async function checkDailyBudget(): Promise<void> {
  const startOfDay = new Date();
  startOfDay.setUTCHours(0, 0, 0, 0);

  const count = await prisma.apiCallLog.count({
    where: { calledAt: { gte: startOfDay } }
  });

  if (count >= DAILY_BUDGET) {
    throw new BudgetExceededError();
  }
}

/// Record one outbound API call in the log table.
export async function logApiCall(endpoint: string, params: Record<string, unknown>): Promise<void> {
  await prisma.apiCallLog.create({
    data: { endpoint, params: JSON.stringify(params) }
  });
}

/// Today's call count — exposed by /api/v1/status.
export async function dailyUsage(): Promise<{ used: number; budget: number }> {
  const startOfDay = new Date();
  startOfDay.setUTCHours(0, 0, 0, 0);
  const used = await prisma.apiCallLog.count({ where: { calledAt: { gte: startOfDay } } });
  return { used, budget: DAILY_BUDGET };
}

/// Cache-aside helper.
/// - Checks ApiCache by `cacheKey`.
/// - If a fresh record exists, returns its payload.
/// - Otherwise calls `fetcher()`, persists the result, and returns it.
export async function getCached<T>(
  cacheKey: string,
  ttlMs: number | null, // null = never expires
  fetcher: () => Promise<T>
): Promise<T> {
  const now = new Date();
  const cached = await prisma.apiCache.findUnique({ where: { cacheKey } });

  if (cached) {
    const isExpired = cached.expiresAt !== null && cached.expiresAt < now;
    if (!isExpired) {
      return cached.payload as T;
    }
  }

  // Cache miss or expired — call the external API.
  await checkDailyBudget();
  const data = await fetcher();

  const expiresAt = ttlMs === null ? null : new Date(now.getTime() + ttlMs);

  await prisma.apiCache.upsert({
    where: { cacheKey },
    update: { payload: data as object, fetchedAt: now, expiresAt },
    create: { cacheKey, payload: data as object, expiresAt }
  });

  return data;
}

export const TTL = {
  SEVEN_DAYS: 7 * 24 * 60 * 60 * 1000,
  ONE_DAY: 24 * 60 * 60 * 1000,
  FOREVER: null as null
} as const;
