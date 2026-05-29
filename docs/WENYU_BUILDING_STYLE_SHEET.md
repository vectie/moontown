# Wenyu Building Style Sheet

Last updated: 2026-05-28

This sheet is for choosing the next building-art direction before replacing the
current Wenyu module sprites. The current cartoon/pixel style should stay as a
backup asset set until a new direction is selected and implemented across all
buildings.

Preview image:

- [wenyu-building-style-sheet-v1.png](/Users/kq/Workspace/moontown/ui/assets/tilemap/style-sheets/wenyu-building-style-sheet-v1.png)

## Style Options

| Option | Direction | Best For | Tradeoff |
| ---: | --- | --- | --- |
| 1 | Glass Civic Campus | AI government, observability, policy, control center | Very modern, but may feel corporate if overused |
| 2 | White Tech Pavilion | AI garden, education, youth innovation, labs | Clean and optimistic, but needs shadow/depth to avoid looking sterile |
| 3 | Warm Timber Innovation Park | community, social exchange, resident/talent spaces | Friendly and premium, but less futuristic |
| 4 | Neo-Chinese Smart Valley | Wenyu identity, civic landmark, town shell | Strong local identity, but harder to keep modular across all buildings |
| 5 | Minimal Concrete + Green Roof | public service, market, bridge, infrastructure | Durable and realistic, but may feel too quiet unless accented |
| 6 | Night Neon Knowledge District | events, media, story radar, night mode | Visually rich, but not ideal as the default daytime map style |

## Recommended Pick

Use a hybrid system:

- Default civic base: `2 White Tech Pavilion`
- Landmark identity: `4 Neo-Chinese Smart Valley`
- Community buildings: `3 Warm Timber Innovation Park`
- Infrastructure and market: `5 Minimal Concrete + Green Roof`
- Night/event overlay: `6 Night Neon Knowledge District`
- Backup/current mode: current cartoon/pixel assets

This gives Wenyu a modern and sleek visual language without making every
building look identical.

## White Tech Pavilion Pack

The first selected pack has been generated for 16 buildings:

- 11 Wenyu civic modules
- 5 long-horizon research domains: OPC, LLM training, robotics, agents, and
  hardware

Preview:

- [white-tech-pavilion-contact-sheet.png](/Users/kq/Workspace/moontown/ui/assets/tilemap/buildings/white-tech-pavilion/white-tech-pavilion-contact-sheet.png)

Assets:

- source PNGs:
  [source](/Users/kq/Workspace/moontown/ui/assets/tilemap/buildings/white-tech-pavilion/source)
- transparent PNGs:
  [alpha](/Users/kq/Workspace/moontown/ui/assets/tilemap/buildings/white-tech-pavilion/alpha)
- reusable prompts:
  [white-tech-pavilion-building-prompts.md](/Users/kq/Workspace/moontown/ui/assets/tilemap/prompts/white-tech-pavilion-building-prompts.md)

The pack is now registered in
`ui/assets/tilemap/modules/wenyu-town-modules.json`. Each building entry
declares its visual asset, footprint, display size, entrance tile, protocol
pattern, use case, and agent flow. The viewport uses that data to place the
building on the map, expose protocol details in the interior view, and show the
same metadata in editor mode.

This makes the building layer an editable town plan rather than a hardcoded
sprite list:

- Move a building by changing `grid_x`, `grid_y`, `entrance_x`, and
  `entrance_y`.
- Resize a building by changing `footprint_w`, `footprint_h`, `display_w`, and
  `display_h`.
- Change its behavior by changing `protocol_pattern`, `use_case`, and
  `agent_flow`.
- Replace its art by changing `asset_base`.
- Disable it by setting `enabled` to `false`.

The reference Wenyu terrain remains the source of truth for roads. Module
entrances are still configured for agent routing, but the renderer should not
paint a second synthetic road network on top of the map unless a future editor
explicitly regenerates the base terrain layer.

## Implementation Rule

Do not replace all module buildings with one generic style. Each Wenyu module
should declare:

- `style_family`
- `building_variant`
- `day_asset`
- `night_asset`
- `roof_asset`
- `shadow_asset`
- `hover_glow_asset`

The module registry should remain the source of truth, so a designer can switch
styles by configuration instead of editing MoonBit code.

## Next Asset Batch

After a direction is chosen, generate final transparent PNGs for:

- Town Shell
- Resident Twin Homes
- Policy Hall
- Contest Express
- Social Square
- Talent Avenue
- Vitality Tower
- AI Science Garden
- Physical Bridge
- Valley Market
- Story Radar

Each final building should include base, roof, shadow, and optional glow layers
so the tile renderer can preserve depth and hover affordances.
