import { Router } from "express";
import { ok } from "../lib/http.js";
import { teamSearchSchema, teamFixturesSchema } from "./teams.validation.js";
import * as teamsService from "./teams.service.js";

export const teamsRouter = Router();

/// GET /api/v1/teams?search=Arsenal&league=39&season=2023
teamsRouter.get("/", async (request, response, next) => {
  try {
    const query = teamSearchSchema.parse(request.query);
    if (!query.search && !query.league) {
        throw new Error("Must provide either search or league parameter");
    }
    ok(response, await teamsService.searchTeams(query));
  } catch (error) {
    next(error);
  }
});

/// GET /api/v1/teams/:id/fixtures?season=2023&league=39
teamsRouter.get("/:id/fixtures", async (request, response, next) => {
  try {
    const { season, league } = teamFixturesSchema.parse(request.query);
    ok(response, await teamsService.teamFixtures(request.params.id, season, league));
  } catch (error) {
    next(error);
  }
});
