import { z } from "zod";

export const matchesQuerySchema = z.object({
  date: z.enum(["today", "yesterday", "upcoming"]).optional(),
  competitionId: z.string().optional(),
  teamIds: z.string().optional(),
  season: z.coerce.number().int().positive().optional()
});

export const competitionQuerySchema = z.object({
  season: z.coerce.number().int().positive().optional()
});

export const seasonQuerySchema = z.object({
  season: z.coerce.number().int().positive().default(new Date().getUTCFullYear())
});
