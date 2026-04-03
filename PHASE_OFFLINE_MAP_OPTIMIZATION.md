# Offline Map Optimization Phases

## Goal
Reduce offline tile storage while preserving ride usability, especially in coastal areas.

## Scope
- Applies to raster tile downloads using `flutter_map` + `flutter_map_tile_caching`.
- Focuses on reducing unnecessary downloads over ocean/water-heavy areas.

## Success Metrics
- Reduce downloaded tile count by at least 30% for water-heavy regions.
- Keep map usability for typical rides (land + coast) unchanged.
- Keep download UX simple and understandable for users.

## Phase 0: Baseline and Measurement
### Objective
Establish current behavior and size before optimization.

### Changes
- Capture baseline tile count and estimated size for representative areas:
  - Inland city area
  - Coastal area
  - Mostly ocean area
- Add simple logging around download requests and completion.

### Deliverables
- Baseline table in notes with area, zoom range, tile count, and size.
- Confirm no regressions in current offline download flow.

### Exit Criteria
- Baseline metrics are recorded and reproducible.

## Phase 1: Immediate Win (Low Change)
### Objective
Apply zoom-tier download policy to reduce size with minimal code risk.

### Policy
- Full selected area: low zoom only (example `z8-z10`).
- Core ride region only: high zoom (example `z11-z16`).
- Core ride region source:
  - Current location with configurable radius, or
  - Ride bounding box + configurable buffer.

### UX
- Show estimated size split by low/high zoom layers.
- Warn user when selected area is mostly outside core high-zoom region.

### Deliverables
- Config fields for `lowZoomMin`, `lowZoomMax`, `highZoomMin`, `highZoomMax`, and `highZoomRadiusKm`.
- Updated downloader that schedules two regions.

### Exit Criteria
- At least 20-40% size reduction in coastal/ocean-heavy selections.
- No missing detail in expected ride corridors.

## Phase 2: Land-Mask Filtering (Best Long-Term)
### Objective
Skip high-zoom tiles that are fully ocean to maximize storage efficiency.

### Approach
- Integrate a land polygon dataset (global or region-bounded).
- Before high-zoom enqueue, test candidate tiles against land mask:
  - Download if tile intersects land.
  - Skip if tile is fully ocean.
- Apply coastline safety buffer (example 10-20 km) to avoid edge misses.

### UX
- Add toggle: "Optimize ocean tiles".
- Show projected savings before download starts.

### Deliverables
- Tile filtering module (land intersection check).
- Configurable coastline buffer.
- User-visible projected savings estimate.

### Exit Criteria
- At least 40-70% reduction for ocean-heavy regions vs baseline.
- No meaningful visual gaps on coastal rides.

## Phase 3: Hardening and Validation
### Objective
Validate correctness, performance, and user trust.

### Changes
- Add integration tests for tile selection logic.
- Add benchmark script/scenario for tile count comparison.
- Add fallback behavior if land dataset unavailable.

### Deliverables
- Test cases for inland, coastal, island, and ocean-only selections.
- Regression checklist for offline navigation experience.

### Exit Criteria
- Tests pass.
- Performance acceptable on mid-range devices.
- No critical UX regressions.

## Risks and Mitigations
- Coastal false negatives:
  - Mitigate with coastline buffer and conservative filter defaults.
- Increased implementation complexity:
  - Keep Phase 1 independent and shippable.
- Dataset size overhead:
  - Use simplified polygons and optional regional packs.

## Rollout Recommendation
1. Ship Phase 1 first for fast, low-risk savings.
2. Implement Phase 2 behind a feature flag.
3. Promote Phase 2 to default after validation in Phase 3.
