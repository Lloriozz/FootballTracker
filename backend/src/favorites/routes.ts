import { Router } from "express";
import { ok } from "../lib/http.js";
import { favoriteTeamsSchema, favoriteLeaguesSchema } from "./favorites.validation.js";

export const favoritesRouter = Router();

favoritesRouter.get("/teams", async (_request, response) => {
  ok(response, []);
});

favoritesRouter.put("/teams", async (request, response) => {
  ok(response, favoriteTeamsSchema.parse(request.body).externalTeamIds);
});

favoritesRouter.delete("/teams/:id", async (request, response) => {
  ok(response, { deleted: request.params.id });
});

favoritesRouter.get("/leagues", async (_request, response) => {
  ok(response, []);
});

favoritesRouter.put("/leagues", async (request, response) => {
  ok(response, favoriteLeaguesSchema.parse(request.body).externalLeagueIds);
});
