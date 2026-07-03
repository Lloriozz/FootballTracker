import cors from "cors";
import express from "express";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { env } from "./lib/env.js";
import { errorHandler, ok } from "./lib/http.js";
import { dailyUsage } from "./lib/cache.js";
import { authRouter } from "./auth/routes.js";
import { favoritesRouter } from "./favorites/routes.js";
import { teamsRouter } from "./teams/routes.js";
import { leaguesRouter } from "./leagues/routes.js";
import { playersRouter } from "./players/routes.js";

const app = express();

app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGIN, credentials: true }));
app.use(express.json());

// Auth with rate limiting.
app.use("/api/v1/auth", rateLimit({ windowMs: 60_000, limit: 20 }), authRouter);

// Favorites (per-user, requires auth middleware in future).
app.use("/api/v1/favorites", favoritesRouter);

// Football data — teams, leagues, players.
app.use("/api/v1/teams", teamsRouter);
app.use("/api/v1/leagues", leaguesRouter);
app.use("/api/v1/players", playersRouter);

// API budget status — useful for monitoring.
app.get("/api/v1/status", async (_req, res, next) => {
  try {
    ok(res, await dailyUsage());
  } catch (error) {
    next(error);
  }
});

app.use(errorHandler);

app.listen(env.PORT, () => {
  console.log(`⚽ Football Tracker API listening on :${env.PORT}`);
});
