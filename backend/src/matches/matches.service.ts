import { ApiFootballClient } from "../external/ExternalFootballClient.js";
import { env } from "../lib/env.js";
import { HttpError } from "../lib/http.js";

const externalFootballClient = new ApiFootballClient(env.EXTERNAL_FOOTBALL_API_BASE_URL, env.EXTERNAL_FOOTBALL_API_KEY ?? "");

function ensureExternalAPIConfigured() {
  if (!env.EXTERNAL_FOOTBALL_API_KEY) {
    throw new HttpError(503, "EXTERNAL_API_NOT_CONFIGURED", "Set EXTERNAL_FOOTBALL_API_KEY to connect to API-Football.");
  }
}

function resolveFixtureDate(date: "today" | "yesterday" | "upcoming" | undefined): string | undefined {
  if (!date || date === "upcoming") {
    return undefined;
  }

  const value = new Date();
  if (date === "yesterday") {
    value.setUTCDate(value.getUTCDate() - 1);
  }
  return value.toISOString().slice(0, 10);
}

export async function getCompetitions(query: { season?: number }) {
  ensureExternalAPIConfigured();
  return externalFootballClient.competitions(query);
}

export async function getMatches(query: { date?: "today" | "yesterday" | "upcoming"; competitionId?: string; teamIds?: string; season?: number }) {
  ensureExternalAPIConfigured();
  return externalFootballClient.matches({
    date: resolveFixtureDate(query.date),
    competitionId: query.competitionId,
    teamIds: query.teamIds?.split(",").map((teamId) => teamId.trim()).filter(Boolean),
    season: query.season
  });
}

export async function getMatchDetail(matchId: string) {
  ensureExternalAPIConfigured();
  return externalFootballClient.matchDetail(matchId);
}

export async function getMatchStats(matchId: string) {
  ensureExternalAPIConfigured();
  return externalFootballClient.stats(matchId);
}

export async function getPlayByPlay(matchId: string) {
  ensureExternalAPIConfigured();
  return externalFootballClient.playByPlay(matchId);
}

export async function getStandings(competitionId: string, season: number) {
  ensureExternalAPIConfigured();
  return externalFootballClient.standings(competitionId, season);
}

export async function getBracket(competitionId: string, season: number) {
  ensureExternalAPIConfigured();
  return externalFootballClient.bracket(competitionId, season);
}
