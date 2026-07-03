import { z } from "zod";

export const favoriteTeamsSchema = z.object({ externalTeamIds: z.array(z.string().min(1)) });
export const favoriteLeaguesSchema = z.object({ externalLeagueIds: z.array(z.string().min(1)) });
