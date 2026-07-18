// Firestore seeding has been retired. The app reads food data exclusively
// from the bundled assets/data/myfcd_full.json, which is generated offline
// by tool/merge_foods.py (merges MyFCD, SGFOCOS, backed and curated sets,
// cleans names, and normalizes categories). The global /foods collection is
// no longer written; its security rules deny client writes.
//
// To update food data: edit the source JSONs or the additions list in
// tool/merge_foods.py, then run `python tool/merge_foods.py` from the
// Flutter root. This file is kept only so old imports fail loudly if
// reintroduced — safe to delete.
