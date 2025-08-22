# Bazari 8656 — A‑to‑Z FullPack (2025‑08‑14)
- Flutter app with tabs: Home, Search, Chat (local), Seller.
- Offline Remote Config + Trending assets.
- Daily Update service loads RC + Trending once per day.
- Mock repository (assets) ensures app runs without backend.
- Functions for search (Algolia/Meili), trending, RC targets (skip if secrets missing).
- CI daily + backup.

## Run
flutter pub get
flutter run