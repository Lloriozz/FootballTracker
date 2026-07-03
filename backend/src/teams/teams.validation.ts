import { z } from "zod";

export const teamSearchSchema = z.object({
  search: z.string().min(2).max(100).optional(),
  league: z.coerce.number().int().positive().optional(),
  season: z.string().optional()
});

export const teamFixturesSchema = z.object({
  season: z.enum(["2022", "2023", "2024"]).default("2023"),
  league: z.coerce.number().int().positive().optional()
});
