import { z } from "zod";

export const leagueListSchema = z.object({
  country: z.string().max(100).optional(),
  search: z.string().max(100).optional()
});

export const leagueFixturesSchema = z.object({
  season: z.enum(["2022", "2023", "2024"]).default("2023")
});
