export interface ExternalFootballClient {
  competitions(filters?: { season?: number }): Promise<CompetitionDTO[]>;
  matches(filters: { date?: string; competitionId?: string; teamIds?: string[]; season?: number }): Promise<MatchDTO[]>;
  matchDetail(matchId: string): Promise<MatchDetailDTO>;
  stats(matchId: string): Promise<unknown[]>;
  playByPlay(matchId: string): Promise<MatchEventDTO[]>;
  standings(competitionId: string, season: number): Promise<unknown[]>;
  bracket(competitionId: string, season: number): Promise<unknown[]>;
}

export type CompetitionDTO = {
  id: string;
  name: string;
  icon: string;
  status: string;
  hasTeams: boolean;
};

export type TeamDTO = {
  id: string;
  name: string;
  shortName: string;
  emblem: string;
  primaryColorHex: string;
  secondaryColorHex: string;
};

export type MatchDTO = {
  id: string;
  competition: string;
  round: string;
  status: "scheduled" | "live" | "finished";
  kickoff: string;
  homeTeam: TeamDTO;
  awayTeam: TeamDTO;
  homeScore: number | null;
  awayScore: number | null;
  isFavorite: boolean;
};

export type MatchEventDTO = {
  id: string;
  minute: string;
  type: string;
  description: string;
  teamName: string;
};

export type MatchDetailDTO = {
  match: MatchDTO;
  goals: MatchEventDTO[];
  stats: unknown[];
  lineups: unknown[];
  events: MatchEventDTO[];
};

export class ApiFootballClient implements ExternalFootballClient {
  constructor(private readonly baseURL: string, private readonly apiKey: string) {}

  async competitions(filters: { season?: number } = {}): Promise<CompetitionDTO[]> {
    const payload = await this.get<ApiFootballListResponse<ApiFootballLeagueEnvelope>>("/leagues", {
      season: filters.season
    });
    return payload.response.map(normalizeCompetition);
  }

  async matches(filters: { date?: string; competitionId?: string; teamIds?: string[]; season?: number }): Promise<MatchDTO[]> {
    const payload = await this.get<ApiFootballListResponse<ApiFootballFixtureEnvelope>>("/fixtures", {
      date: filters.date,
      league: filters.competitionId,
      season: filters.season,
      team: filters.teamIds?.[0]
    });
    return payload.response.map(normalizeMatch);
  }

  async matchDetail(matchId: string): Promise<MatchDetailDTO> {
    const [fixtures, stats, events, lineups] = await Promise.all([
      this.get<ApiFootballListResponse<ApiFootballFixtureEnvelope>>("/fixtures", { id: matchId }),
      this.stats(matchId),
      this.playByPlay(matchId),
      this.get<ApiFootballListResponse<unknown>>("/fixtures/lineups", { fixture: matchId })
    ]);

    const fixture = fixtures.response[0];
    if (!fixture) {
      throw new Error(`Fixture ${matchId} was not found by API-Football.`);
    }

    return {
      match: normalizeMatch(fixture),
      goals: events.filter((event) => event.type.toLowerCase() === "goal"),
      stats,
      lineups: lineups.response,
      events
    };
  }

  async stats(matchId: string): Promise<unknown[]> {
    const payload = await this.get<ApiFootballListResponse<unknown>>("/fixtures/statistics", { fixture: matchId });
    return payload.response;
  }

  async playByPlay(matchId: string): Promise<MatchEventDTO[]> {
    const payload = await this.get<ApiFootballListResponse<ApiFootballEvent>>("/fixtures/events", { fixture: matchId });
    return payload.response.map(normalizeEvent);
  }

  async standings(competitionId: string, season: number): Promise<unknown[]> {
    const payload = await this.get<ApiFootballListResponse<unknown>>("/standings", { league: competitionId, season });
    return payload.response;
  }

  async bracket(competitionId: string, season: number): Promise<unknown[]> {
    const payload = await this.get<ApiFootballListResponse<unknown>>("/fixtures/rounds", { league: competitionId, season });
    return payload.response;
  }

  private async get<T>(path: string, params: Record<string, string | number | undefined> = {}): Promise<T> {
    if (!this.apiKey) {
      throw new Error("API-Football key is not configured.");
    }

    const url = new URL(path, this.baseURL);
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== "") {
        url.searchParams.set(key, String(value));
      }
    }

    const response = await fetch(url, {
      headers: {
        accept: "application/json",
        "x-apisports-key": this.apiKey
      }
    });

    if (!response.ok) {
      throw new Error(`API-Football request failed with ${response.status}.`);
    }

    return await response.json() as T;
  }
}

type ApiFootballListResponse<T> = {
  response: T[];
};

type ApiFootballLeagueEnvelope = {
  league: { id: number; name: string; logo?: string | null };
  seasons?: Array<{ year: number; current: boolean }>;
};

type ApiFootballFixtureEnvelope = {
  fixture: { id: number; date: string; status: { short: string; long: string; elapsed?: number | null } };
  league: { id: number; name: string; round?: string | null };
  teams: {
    home: { id: number; name: string; logo?: string | null; winner?: boolean | null };
    away: { id: number; name: string; logo?: string | null; winner?: boolean | null };
  };
  goals: { home: number | null; away: number | null };
};

type ApiFootballEvent = {
  time: { elapsed?: number | null; extra?: number | null };
  team: { name: string };
  player?: { name?: string | null };
  type: string;
  detail: string;
  comments?: string | null;
};

function normalizeCompetition(item: ApiFootballLeagueEnvelope): CompetitionDTO {
  const currentSeason = item.seasons?.find((season) => season.current);
  return {
    id: String(item.league.id),
    name: item.league.name,
    icon: item.league.logo ?? "🏆",
    status: currentSeason ? "Live" : "Offseason",
    hasTeams: true
  };
}

function normalizeMatch(item: ApiFootballFixtureEnvelope): MatchDTO {
  return {
    id: String(item.fixture.id),
    competition: item.league.name,
    round: item.league.round ?? "",
    status: normalizeStatus(item.fixture.status.short),
    kickoff: item.fixture.date,
    homeTeam: normalizeTeam(item.teams.home),
    awayTeam: normalizeTeam(item.teams.away),
    homeScore: item.goals.home,
    awayScore: item.goals.away,
    isFavorite: false
  };
}

function normalizeTeam(team: ApiFootballFixtureEnvelope["teams"]["home"]): TeamDTO {
  return {
    id: String(team.id),
    name: team.name,
    shortName: team.name,
    emblem: team.logo ?? "●",
    primaryColorHex: "#0B5D1E",
    secondaryColorHex: "#123C69"
  };
}

function normalizeStatus(short: string): MatchDTO["status"] {
  if (["FT", "AET", "PEN"].includes(short)) {
    return "finished";
  }
  if (["1H", "HT", "2H", "ET", "BT", "P", "SUSP", "INT", "LIVE"].includes(short)) {
    return "live";
  }
  return "scheduled";
}

function normalizeEvent(event: ApiFootballEvent, index: number): MatchEventDTO {
  const extra = event.time.extra ? `+${event.time.extra}` : "";
  const player = event.player?.name ? `${event.player.name}: ` : "";
  return {
    id: `${event.team.name}-${event.type}-${event.time.elapsed ?? 0}-${index}`,
    minute: `${event.time.elapsed ?? 0}${extra}`,
    type: event.type,
    description: `${player}${event.detail}${event.comments ? ` (${event.comments})` : ""}`,
    teamName: event.team.name
  };
}
