import { Router } from "express";
import { ok } from "../lib/http.js";
import { playerSearchSchema, playerDetailSchema } from "./players.validation.js";
import * as playersService from "./players.service.js";

export const playersRouter = Router();

/// GET /api/v1/players?search=Salah&season=2023&league=39
playersRouter.get("/", async (request, response, next) => {
  try {
    const { search, season, league } = playerSearchSchema.parse(request.query);
    ok(response, await playersService.searchPlayers(search, season, league));
  } catch (error) {
    next(error);
  }
});

/// GET /api/v1/players/:id?season=2023
playersRouter.get("/:id", async (request, response, next) => {
  try {
    const { season } = playerDetailSchema.parse(request.query);
    ok(response, await playersService.playerDetail(request.params.id, season));
  } catch (error) {
    next(error);
  }
});
