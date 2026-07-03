import { ApiFootballClient } from "../external/ExternalFootballClient.js";
import { env } from "../lib/env.js";
import { getCached, logApiCall, TTL } from "../lib/cache.js";

const client = new ApiFootballClient(env.EXTERNAL_FOOTBALL_API_BASE_URL, env.EXTERNAL_FOOTBALL_API_KEY ?? "");

/// Search teams by name or fetch by league. Results are cached for 7 days.
export async function searchTeams(query: { search?: string; league?: number; season?: string }) {
  const cacheKey = `teams:search:${query.search?.toLowerCase().trim() ?? "none"}:league:${query.league ?? "none"}:season:${query.season ?? "none"}`;
  return getCached(cacheKey, TTL.SEVEN_DAYS, async () => {
    const params: Record<string, string | number | undefined> = {};
    if (query.search) params["search"] = query.search;
    if (query.league) params["league"] = query.league;
    if (query.season) params["season"] = query.season;
    
    await logApiCall("/teams", params);
    const raw = await client["get"]<{ response: unknown[] }>("/teams", params);
    return raw.response.map(normalizeTeam);
  });
}

/// All fixtures for a specific team in a season. Past seasons cached forever.
export async function teamFixtures(teamId: string, season: string, leagueId?: number) {
  const cacheKey = `fixtures:team:${teamId}:${season}${leagueId ? `:league:${leagueId}` : ""}`;
  const ttl = Number(season) < new Date().getUTCFullYear() ? TTL.FOREVER : TTL.ONE_DAY;

  return getCached(cacheKey, ttl, async () => {
    await logApiCall("/fixtures", { team: teamId, season, league: leagueId });
    const params: Record<string, string | number | undefined> = { team: teamId, season };
    if (leagueId) params["league"] = leagueId;
    const raw = await client["get"]<{ response: unknown[] }>("/fixtures", params);
    return raw.response.map(normalizeFixture);
  });
}

function normalizeTeam(item: unknown) {
  const t = (item as { team: Record<string, unknown>; venue?: Record<string, unknown> }).team;
  return {
    id: String(t["id"]),
    name: String(t["name"]),
    shortName: String(t["code"] ?? t["name"]),
    country: String(t["country"] ?? ""),
    logo: String(t["logo"] ?? ""),
    founded: t["founded"] ?? null
  };
}

function normalizeFixture(item: unknown) {
  const f = item as {
    fixture: { id: number; date: string; status: { short: string; elapsed?: number | null } };
    league: { id: number; name: string; round?: string | null; logo?: string };
    teams: { home: { id: number; name: string; logo?: string; winner?: boolean | null }; away: { id: number; name: string; logo?: string; winner?: boolean | null } };
    goals: { home: number | null; away: number | null };
    score?: { fulltime?: { home?: number | null; away?: number | null } };
  };

  return {
    id: String(f.fixture.id),
    competition: f.league.name,
    competitionId: String(f.league.id),
    competitionLogo: f.league.logo ?? "",
    round: f.league.round ?? "",
    status: normalizeStatus(f.fixture.status.short),
    elapsed: f.fixture.status.elapsed ?? null,
    kickoff: f.fixture.date,
    homeTeam: { id: String(f.teams.home.id), name: f.teams.home.name, shortName: f.teams.home.name, emblem: f.teams.home.logo ?? "●", primaryColorHex: "#0B5D1E", secondaryColorHex: "#123C69" },
    awayTeam: { id: String(f.teams.away.id), name: f.teams.away.name, shortName: f.teams.away.name, emblem: f.teams.away.logo ?? "●", primaryColorHex: "#1A3A5C", secondaryColorHex: "#0B5D1E" },
    homeScore: f.goals.home,
    awayScore: f.goals.away,
    isFavorite: false
  };
}

function normalizeStatus(short: string): string {
  if (["FT", "AET", "PEN"].includes(short)) return "finished";
  if (["1H", "HT", "2H", "ET", "BT", "P", "LIVE"].includes(short)) return "live";
  return "scheduled";
}
