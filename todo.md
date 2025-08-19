* Cache latest run in homepage --> performance improvements
* Cache runs in runs list page 
    - it fetches from DB every time ??
    - use cache!!
* When sync with strava, update values if there are already existing runs with the same id
* Add a button that says "sync to strava" in run summary view
* Bug in timers (maybe elapsed time = elapsed time + moving time oluyor?) 
* UI Improvements:
    * Runs page
    * Runs card
        * Detailed run page when clicked on
        * Replay runs page
    * Chart improvement
        * Make it clickable, when clicked on the bar, it should show the respective run
        * Chart should always start on Monday
        * No data on week, it should show gridlines (now it doesn't)
* Strava OAuth issue
* Run view refresh it makes error

* Maybes:
    * Put locationString as a column in the db

* Integrate Apple Health
* Ghosts
    - Ghost CRUD
    - Ghost 
* User profile
* Settings page
* Run unit preferences



🚨 CRITICAL PERFORMANCE ISSUES

1. Memory Leak in ActiveRunViewModel

ActiveRunViewModel.swift:343 - Ghost movement timer never gets cleaned up, causing permanent memory
leak and battery drain.

2. Main Thread Blocking in Keychain Operations

StravaService.swift:424-464 - All keychain operations (SecItemAdd, SecItemDelete) run synchronously
on main thread, freezing UI during authentication.

⚡ HIGH IMPACT LATENCIES

3. GPS Performance Bottleneck

ActiveRunViewModel.swift:104-115 - Distance calculations on main thread get exponentially slower as
route gets longer, causing UI stuttering during long runs.

4. MapKit Rendering Inefficiency

GPSMapView.swift:68-94 - Completely recreates all map overlays on every update instead of diffing,
causing visual flickering and poor animation performance.

5. Search/Filter Performance

RunsViewModel.swift:53-106 - Complex filtering runs on main thread without optimization, causing
noticeable lag when searching through run history.

🎯 QUICK WINS FOR BETTER UX

Immediate Fixes (< 1 hour each):

1. Store and invalidate ghost timer: var ghostTimer: Timer? + ghostTimer?.invalidate()
2. Move keychain to background queue: Wrap Security calls in Task.detached
3. Cache filter results: Store computed filteredAndSortedRuns instead of recalculating
4. Optimize GPS updates: Move distance calculations off main thread

Medium-term Improvements:

1. MapKit diffing: Only update changed overlays/annotations
2. Lazy data loading: Load run data on-demand vs all upfront
3. Animation optimization: Replace DispatchQueue.main.asyncAfter chains with CADisplayLink

📊 Performance Impact Summary

| Issue               | User Experience Impact        | Fix Difficulty |
|---------------------|-------------------------------|----------------|
| Timer memory leak   | Battery drain, eventual crash | Easy           |
| Keychain blocking   | UI freezes during auth        | Easy           |
| GPS calculations    | Stuttering during runs        | Medium         |
| MapKit inefficiency | Choppy map animations         | Medium         |
| Search lag          | Delayed search results        | Easy           |

The most critical issues are the memory leak (can crash the app) and keychain blocking (freezes UI).
These should be your immediate priorities for a smoother user experience.