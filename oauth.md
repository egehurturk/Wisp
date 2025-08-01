


when app is slided away closed in background and opened again the strava connect model opens up for a second then vanishes away --


think about "backend":
* move strava oauth client to backend, exposing APIs?
* move credentials to backend?
* store user as a session instead of repeated SQL queries to supabase? 
    * how to get the current user?

webhooks backend

refactor code
