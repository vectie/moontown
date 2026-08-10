# MoonTown spring civic modular building pack

This pack migrates the approved clean, contemporary eco-civic art language into
MoonTown's existing semantic map. It is deliberately a set of independent
building cutouts—not a rendered town plate or replacement user interface.

## Generation prompt

Use case: `stylized-concept`

Asset type: modular game-building sprites for MoonTown's procedural isometric
map.

Create sixteen separate contemporary civic buildings with a consistent
orthographic 45-degree isometric camera and approximately 32-degree elevation:
housing, maker workshop, AI agents lab, community cafe, green-energy center,
mobility hub, civic hall, policy library, vitality tower, story studio, talent
avenue, valley market, robotics lab, AI hardware lab, LLM training lab and OPC
studio. Use crisp semi-flat cel shading, thin deep blue-gray outlines, matte
warm-white surfaces, restrained timber, pale-cyan glass, spring greens and tiny
terracotta or yellow accents. Give each building only two or three role-specific
details and keep its silhouette readable at small scale.

Generate on a perfectly flat solid `#ff00ff` chroma-key background. Do not add
roads, ground tiles, residents, trees, UI, labels, signs, logos, cast shadows,
contact shadows or scene composition. Avoid painterly texture, PBR noise,
photorealism, glossy mobile-game materials, sci-fi megastructures, dense window
grids, roof machinery, haze, bloom, neon and old-kingdom motifs.

The runtime renderer owns placement, footprint scale, shadows, selection,
depth ordering and interaction. The normalized ground-center anchor for every
1024-by-1024 sprite is `(0.50, 0.80)`.

## Extension archetypes

- `policy-hall`: a low two-storey council and public-library pavilion with a
  restrained portico, curved chamber and planted roof.
- `vitality-tower`: a slender seven-storey wellness and civic-analytics tower
  with planted terraces, a cyan vertical bay and one coral entry canopy.
- `story-radar`: a compact community media studio with a rounded wing and one
  modest rooftop antenna and dish—never a science-fiction tower.
- `talent-avenue`: an elongated three-volume learning and residence arcade with
  stepped terraces and a welcoming public passage.
- `valley-market`: a one-storey open timber market pavilion with broad roof
  bays, a clear central aisle and restrained cream-yellow awnings.
- `research-embodied-robotics`: a high-bay maker lab with a test court and two
  small articulated industrial arms; no humanoid robots.
- `research-ai-hardware`: a clean fabrication pavilion with a visible cleanroom
  bay, restrained sawtooth roof and compact service court.
- `research-llm-training`: two calm learning and compute-library wings joined
  by a bridge around a planted courtyard; no data-center or sci-fi styling.
- `research-opc`: an L-shaped founder incubator studio with a strategy room,
  terrace and archive nook.

Each generated source uses the exact flat `#ff00ff` background. Backgrounds are
removed with the ImageGen chroma-key helper using a soft matte and despill, then
the visible silhouette is fitted inside the common 1024-square anchor contract:
centered horizontally, ground at y=0.96, and no baked ground plate or shadow.
