import { z } from "zod";

export const playerSearchSchema = z.object({
  search: z.string().default(""),
  season: z.enum(["2022", "2023", "2024"]).default("2023"),
  league: z.coerce.number().int().positive().optional()
});

export const playerDetailSchema = z.object({
  season: z.enum(["2022", "2023", "2024"]).default("2023")
});
