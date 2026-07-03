import { Router } from "express";
import { ok } from "../lib/http.js";
import { matchesQuerySchema, competitionQuerySchema, seasonQuerySchema } from "./matches.validation.js";
import * as matchesService from "./matches.service.js";

export const matchesRouter = Router();

matchesRouter.get("/competitions", async (request, response, next) => {
  try {
    const query = competitionQuerySchema.parse(request.query);
    ok(response, await matchesService.getCompetitions(query));
  } catch (error) {
    next(error);
  }
});

matchesRouter.get("/matches", async (request, response, next) => {
  try {
    const query = matchesQuerySchema.parse(request.query);
    ok(response, await matchesService.getMatches(query), { filters: query });
  } catch (error) {
    next(error);
  }
});

matchesRouter.get("/matches/:matchId", async (request, response, next) => {
  try {
    ok(response, await matchesService.getMatchDetail(request.params.matchId));
  } catch (error) {
    next(error);
  }
});

matchesRouter.get("/matches/:matchId/stats", async (request, response, next) => {
  try {
    ok(response, await matchesService.getMatchStats(request.params.matchId));
  } catch (error) {
    next(error);
  }
});

matchesRouter.get("/matches/:matchId/play-by-play", async (request, response, next) => {
  try {
    ok(response, await matchesService.getPlayByPlay(request.params.matchId));
  } catch (error) {
    next(error);
  }
});

matchesRouter.get("/competitions/:id/standings", async (request, response, next) => {
  try {
    const query = seasonQuerySchema.parse(request.query);
    ok(response, await matchesService.getStandings(request.params.id, query.season));
  } catch (error) {
    next(error);
  }
});

matchesRouter.get("/competitions/:id/bracket", async (request, response, next) => {
  try {
    const query = seasonQuerySchema.parse(request.query);
    ok(response, await matchesService.getBracket(request.params.id, query.season));
  } catch (error) {
    next(error);
  }
});
