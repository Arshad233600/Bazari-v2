import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { rebuildSearchIndex } from "./tasks/rebuildSearchIndex";
import { rebuildSearchIndexMeili } from "./tasks/rebuildSearchIndexMeili";
import { computeTrendingReal } from "./tasks/computeTrendingReal";
import { updateRemoteConfigTargetsKpiAware } from "./tasks/updateRemoteConfigTargetsKpiAware";

if (admin.apps.length === 0) admin.initializeApp();

export const runDailyJobs = functions.https.onRequest(async (req, res) => {
  const token = req.get("authorization")?.replace("Bearer ", "");
  const expected = process.env.DAILY_JOBS_TOKEN;
  if (!expected || token !== expected) return res.status(401).send("Unauthorized");
  try {
    const engine = (process.env.SEARCH_ENGINE || "ALGOLIA").toUpperCase();
    if (engine === "MEILI" || engine === "MEILISEARCH") await rebuildSearchIndexMeili();
    else await rebuildSearchIndex();
    await computeTrendingReal();
    await updateRemoteConfigTargetsKpiAware();
    return res.status(200).send("OK");
  } catch (e) {
    console.error(e);
    return res.status(500).send("Failed");
  }
});