import { ApiFootballClient } from "../external/ExternalFootballClient.js";
import { env } from "../lib/env.js";
import { getCached, logApiCall, TTL } from "../lib/cache.js";

const client = new ApiFootballClient(env.EXTERNAL_FOOTBALL_API_BASE_URL, env.EXTERNAL_FOOTBALL_API_KEY ?? "");

/// List leagues, optionally filtered by country or search term.
/// Cached 7 days since league metadata rarely changes.
export async function listLeagues(filters: { country?: string; search?: string }) {
  const key = `leagues:${filters.country ?? "all"}:${filters.search ?? ""}`;
  return getCached(key, TTL.SEVEN_DAYS, async () => {
    const params: Record<string, string | number | undefined> = { type: "League" };
    if (filters.country) params["country"] = filters.country;
    if (filters.search) params["search"] = filters.search;
    await logApiCall("/leagues", params);
    const raw = await client["get"]<{ response: unknown[] }>("/leagues", params);
    return raw.response.map(normalizeLeague);
  });
}

/// All fixtures for a league in one season. Past seasons cached forever.
export async function leagueFixtures(leagueId: string, season: string) {
  const cacheKey = `fixtures:league:${leagueId}:${season}`;
  const ttl = Number(season) < new Date().getUTCFullYear() ? TTL.FOREVER : TTL.ONE_DAY;

  return getCached(cacheKey, ttl, async () => {
    await logApiCall("/fixtures", { league: leagueId, season });
    const raw = await client["get"]<{ response: unknown[] }>("/fixtures", { league: leagueId, season });
    return raw.response.map(normalizeFixture);
  });
}

function normalizeLeague(item: unknown) {
  const e = item as {
    league: { id: number; name: string; logo?: string | null; type?: string };
    country: { name: string; flag?: string | null };
    seasons?: Array<{ year: number; current: boolean }>;
  };
  const currentSeason = e.seasons?.find((s) => s.current);
  return {
    id: String(e.league.id),
    name: e.league.name,
    country: e.country.name,
    icon: e.league.logo ?? "🏆",
    flag: e.country.flag ?? "",
    status: currentSeason ? "Active" : "Offseason",
    hasTeams: true
  };
}

function normalizeFixture(item: unknown) {
  const f = item as {
    fixture: { id: number; date: string; status: { short: string; elapsed?: number | null } };
    league: { id: number; name: string; round?: string | null; logo?: string };
    teams: { home: { id: number; name: string; logo?: string }; away: { id: number; name: string; logo?: string } };
    goals: { home: number | null; away: number | null };
  };

  const normalizeStatus = (s: string) => {
    if (["FT", "AET", "PEN"].includes(s)) return "finished";
    if (["1H", "HT", "2H", "ET", "BT", "P", "LIVE"].includes(s)) return "live";
    return "scheduled";
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
