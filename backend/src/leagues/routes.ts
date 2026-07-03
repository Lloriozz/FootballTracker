import { Router } from "express";
import { ok } from "../lib/http.js";
import { leagueListSchema, leagueFixturesSchema } from "./leagues.validation.js";
import * as leaguesService from "./leagues.service.js";

export const leaguesRouter = Router();

/// GET /api/v1/leagues?country=England&search=Premier
leaguesRouter.get("/", async (request, response, next) => {
  try {
    const filters = leagueListSchema.parse(request.query);
    ok(response, await leaguesService.listLeagues(filters));
  } catch (error) {
    next(error);
  }
});

/// GET /api/v1/leagues/:id/fixtures?season=2023
leaguesRouter.get("/:id/fixtures", async (request, response, next) => {
  try {
    const { season } = leagueFixturesSchema.parse(request.query);
    ok(response, await leaguesService.leagueFixtures(request.params.id, season));
  } catch (error) {
    next(error);
  }
});
