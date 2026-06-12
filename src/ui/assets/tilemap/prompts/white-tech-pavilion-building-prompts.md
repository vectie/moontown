# White Tech Pavilion Building Prompts

Last updated: 2026-05-28

These prompts generated the first 16-building White Tech Pavilion pack for
Wenyu Valley. They are reusable source prompts for producing more buildings in
the same family.

Asset output:

- source images: `ui/assets/tilemap/buildings/white-tech-pavilion/source/`
- transparent PNGs: `ui/assets/tilemap/buildings/white-tech-pavilion/alpha/`
- review contact sheet:
  `ui/assets/tilemap/buildings/white-tech-pavilion/white-tech-pavilion-contact-sheet.png`

## Shared Prompt Rules

Every prompt used this common contract:

```text
Use case: stylized-concept
Asset type: isometric tilemap building sprite source for background removal
Style: premium white ceramic and glass pavilion, subtle blue glass, 2.5D isometric 3/4 view, web tile-map game asset, not cartoon, not toy-like.
Composition: single complete building, centered, generous padding, visible roof and front facade, no cut-off edges.
Background: perfectly flat solid #00ff00 chroma-key background for removal, no shadows on background, no floor plane, no text, no people, no watermark.
```

## 16 Building Prompts

### 1. Town Shell

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Town Shell, the mayor/civic command center.
Building-specific details: central council atrium, small digital clock tower, rooftop garden ring, calm civic entrance plaza.
```

### 2. Resident Twin Homes

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Resident Twin Homes, a personal digital twin and memory residence hub.
Building-specific details: paired twin residential wings, private balcony pods, gentle garden courtyards, small privacy-light beacons, calm home-like scale.
```

### 3. Policy Hall

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Policy Hall, an AI policy intelligence and civic service building.
Building-specific details: council chamber dome, transparent hearing room, policy archive fins, orderly entrance steps, small civic flag pylons without text.
```

### 4. Contest Express

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Contest Express, a competition coaching and opportunity dispatch center.
Building-specific details: fast-track terminal form, modular briefing rooms, trophy-light atrium, small launch-platform entrance, energetic but clean.
```

### 5. Social Square

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Social Square, an agent and resident exchange building.
Building-specific details: circular forum hall, open terraces, translucent canopy, multiple small entrance arcs, warm public plaza feeling.
```

### 6. Talent Avenue

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Talent Avenue, a talent graph and opportunity matching building.
Building-specific details: long gallery spine, network-node facade lights, rooftop skill garden, interview pods, elegant avenue frontage.
```

### 7. Vitality Tower

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Vitality Tower, an observability, health, and dashboard building.
Building-specific details: vertical data lighthouse, circular sensor decks, rooftop beacon ring, small public monitoring plaza, clean health dashboard mood.
```

### 8. AI Science Garden

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley AI Science Garden, an AI education and experimentation garden.
Building-specific details: glass botanical research dome, classroom pods, small outdoor experiment plots, curved white canopy, spring garden atmosphere.
```

### 9. Physical Bridge

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Physical Bridge, a confirmation-gated real-world handoff and robotics interface building.
Building-specific details: elevated bridge span over a tiny water channel, secure handoff gate, logistics bay, sensor archways, physical-world connector identity.
```

### 10. Valley Market

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Market, a civic market and collaboration exchange building.
Building-specific details: clean market arcade, flexible stalls under white canopy, transparent ledger hall, small rooftop garden, exchange-place identity without text.
```

### 11. Story Radar

```text
Generate one modern sleek WHITE TECH PAVILION building for Wenyu Valley Story Radar, a public story, media, and broadcast insight building.
Building-specific details: small broadcast mast, curved screening room, rooftop signal dish, transparent editorial studio, gentle blue light strips, no text.
```

### 12. OPC Research

```text
Generate one modern sleek WHITE TECH PAVILION building for OPC research, a one-person-company intelligence and strategy research building.
Building-specific details: solo founder studio tower, small strategy war-room, finance/news observatory glass roof, private garden courtyard, quiet high-agency mood.
```

### 13. LLM Training Research

```text
Generate one modern sleek WHITE TECH PAVILION building for LLM training research, a deep AI model training knowledge lab.
Building-specific details: layered compute hall, glass data-core atrium, cooling fins, rooftop solar grid, quiet research library wing, no text.
```

### 14. Embodied Robotics Research

```text
Generate one modern sleek WHITE TECH PAVILION building for embodied robotics research, a robotics salon and experiment exchange building.
Building-specific details: robot test atrium, VLA/world-model discussion dome, small motion-capture courtyard, mechanical service bay, clean futuristic but civic.
```

### 15. AI Agents Research

```text
Generate one modern sleek WHITE TECH PAVILION building for AI agents research, a multi-agent orchestration and protocol lab.
Building-specific details: central dispatch atrium, many small connected meeting pods, rooftop network pattern, transparent operations room, no text.
```

### 16. AI Hardware Research

```text
Generate one modern sleek WHITE TECH PAVILION building for AI hardware research, a semiconductor and accelerator systems lab.
Building-specific details: chip-shaped roof skylight, cleanroom wing, cooling towers hidden inside white fins, wafer-inspired circular courtyard, no text.
```

## Reuse Notes

To create another building in this family:

1. Keep the shared prompt rules unchanged.
2. Replace only the building name and building-specific details.
3. Generate on the flat `#00ff00` chroma-key background.
4. Run chroma-key removal into the `alpha/` folder.
5. Add the asset to the module registry only after visual QA.
