import { ApiFootballClient } from "../external/ExternalFootballClient.js";
import { env } from "../lib/env.js";
import { getCached, logApiCall, TTL } from "../lib/cache.js";

const client = new ApiFootballClient(env.EXTERNAL_FOOTBALL_API_BASE_URL, env.EXTERNAL_FOOTBALL_API_KEY ?? "");

const FAMOUS_PLAYERS = [
  {
    id: "154", name: "Lionel Messi", firstName: "Lionel", lastName: "Messi", age: 36, nationality: "Argentina", height: "170 cm", weight: "72 kg", photo: "https://media.api-sports.io/football/players/154.png", injured: false,
    statistics: [{ teamId: "2283", teamName: "Inter Miami", teamLogo: "", leagueId: "", leagueName: "", leagueLogo: "", leagueCountry: "", season: null, position: "Attacker", appearances: 0, lineups: 0, minutesPlayed: 0, rating: null, goals: 0, assists: 0, yellowCards: 0, redCards: 0 }]
  },
  {
    id: "874", name: "Cristiano Ronaldo", firstName: "Cristiano", lastName: "Ronaldo", age: 39, nationality: "Portugal", height: "187 cm", weight: "83 kg", photo: "https://media.api-sports.io/football/players/874.png", injured: false,
    statistics: [{ teamId: "2939", teamName: "Al Nassr", teamLogo: "", leagueId: "", leagueName: "", leagueLogo: "", leagueCountry: "", season: null, position: "Attacker", appearances: 0, lineups: 0, minutesPlayed: 0, rating: null, goals: 0, assists: 0, yellowCards: 0, redCards: 0 }]
  },
  {
    id: "278", name: "Kylian Mbappé", firstName: "Kylian", lastName: "Mbappé", age: 25, nationality: "France", height: "178 cm", weight: "73 kg", photo: "https://media.api-sports.io/football/players/278.png", injured: false,
    statistics: [{ teamId: "541", teamName: "Real Madrid", teamLogo: "", leagueId: "", leagueName: "", leagueLogo: "", leagueCountry: "", season: null, position: "Attacker", appearances: 0, lineups: 0, minutesPlayed: 0, rating: null, goals: 0, assists: 0, yellowCards: 0, redCards: 0 }]
  },
  {
    id: "1100", name: "Erling Haaland", firstName: "Erling", lastName: "Haaland", age: 23, nationality: "Norway", height: "195 cm", weight: "88 kg", photo: "https://media.api-sports.io/football/players/1100.png", injured: false,
    statistics: [{ teamId: "50", teamName: "Manchester City", teamLogo: "", leagueId: "", leagueName: "", leagueLogo: "", leagueCountry: "", season: null, position: "Attacker", appearances: 0, lineups: 0, minutesPlayed: 0, rating: null, goals: 0, assists: 0, yellowCards: 0, redCards: 0 }]
  },
  {
    id: "41606", name: "Jude Bellingham", firstName: "Jude", lastName: "Bellingham", age: 20, nationality: "England", height: "186 cm", weight: "75 kg", photo: "https://media.api-sports.io/football/players/41606.png", injured: false,
    statistics: [{ teamId: "541", teamName: "Real Madrid", teamLogo: "", leagueId: "", leagueName: "", leagueLogo: "", leagueCountry: "", season: null, position: "Midfielder", appearances: 0, lineups: 0, minutesPlayed: 0, rating: null, goals: 0, assists: 0, yellowCards: 0, redCards: 0 }]
  }
];

/// Search players by name. Uses /players/profiles to allow global search without a team/league.
export async function searchPlayers(search: string, season: string, leagueId?: number) {
  if (!search || search.trim().length === 0) {
    return FAMOUS_PLAYERS;
  }
  
  const cacheKey = `players:profiles:${search.toLowerCase().trim()}`;
  return getCached(cacheKey, TTL.SEVEN_DAYS, async () => {
    const params: Record<string, string | number | undefined> = { search };
    await logApiCall("/players/profiles", params);
    const raw = await client["get"]<{ response: unknown[] }>("/players/profiles", params);
    return raw.response.map(normalizePlayer);
  });
}

/// Full player profile + season statistics for one player.
export async function playerDetail(playerId: string, season: string) {
  const cacheKey = `player:${playerId}:${season}`;
  const ttl = Number(season) < new Date().getUTCFullYear() ? TTL.FOREVER : TTL.SEVEN_DAYS;

  return getCached(cacheKey, ttl, async () => {
    await logApiCall("/players", { id: playerId, season });
    const raw = await client["get"]<{ response: unknown[] }>("/players", { id: playerId, season });
    if (!raw.response[0]) throw new Error(`Player ${playerId} not found for season ${season}.`);
    return normalizePlayer(raw.response[0]);
  });
}

type RawPlayer = {
  player: {
    id: number;
    name: string;
    firstname?: string | null;
    lastname?: string | null;
    age?: number | null;
    nationality?: string | null;
    height?: string | null;
    weight?: string | null;
    photo?: string | null;
    injured?: boolean;
  };
  statistics?: Array<{
    team: { id: number; name: string; logo?: string | null };
    league: { id: number; name: string; logo?: string | null; country?: string; season?: number };
    games: { appearences?: number | null; lineups?: number | null; minutes?: number | null; position?: string | null; rating?: string | null };
    goals: { total?: number | null; assists?: number | null };
    cards: { yellow?: number | null; red?: number | null };
  }>;
};

function normalizePlayer(item: unknown) {
  const p = item as RawPlayer;
  return {
    id: String(p.player.id),
    name: p.player.name,
    firstName: p.player.firstname ?? "",
    lastName: p.player.lastname ?? "",
    age: p.player.age ?? null,
    nationality: p.player.nationality ?? "",
    height: p.player.height ?? "",
    weight: p.player.weight ?? "",
    photo: p.player.photo ?? "",
    injured: p.player.injured ?? false,
    statistics: (p.statistics || []).map((s) => ({
      teamId: String(s.team.id),
      teamName: s.team.name,
      teamLogo: s.team.logo ?? "",
      leagueId: String(s.league.id),
      leagueName: s.league.name,
      leagueLogo: s.league.logo ?? "",
      leagueCountry: s.league.country ?? "",
      season: s.league.season ?? null,
      position: s.games.position ?? "",
      appearances: s.games.appearences ?? 0,
      lineups: s.games.lineups ?? 0,
      minutesPlayed: s.games.minutes ?? 0,
      rating: s.games.rating ? parseFloat(s.games.rating) : null,
      goals: s.goals.total ?? 0,
      assists: s.goals.assists ?? 0,
      yellowCards: s.cards.yellow ?? 0,
      redCards: s.cards.red ?? 0
    }))
  };
}
