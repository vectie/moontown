# gpt-image-2 Prompts: Wenyu Valley Tilemap

Use these prompts with the image-2 CLI path once `OPENAI_API_KEY` is available.

## Ground Tileset

```text
Use case: stylized-concept
Asset type: game tileset PNG spritesheet
Primary request: Create a pixel-art isometric ground tileset for Wenyu Valley AI Innovation Town.
Scene/backdrop: spring riverside valley with cozy civic-tech town mood
Style/medium: crisp pixel art, Stardew-like warmth, 2.5D isometric tiles
Composition/framing: each ground tile must fit a 64x32 isometric diamond grid; transparent or flat removable background around each tile
Lighting/mood: top-left sunlight, soft spring atmosphere, bottom-right pixel shadow
Color palette: fresh greens, warm tan paths, blue-green river, pink and yellow spring flowers
Required tiles: grass plain, grass light, grass dark, grass with pink flowers, grass with yellow flowers, river straight, river bank, dirt path, plaza stone, wood bridge
Constraints: no text, no UI, no characters, no buildings, no perspective drift, no blur, no watermark; keep every tile aligned to the same 64x32 isometric diamond
Avoid: painterly edges, photorealism, shadows outside tile bounds, inconsistent camera angle
```

Suggested command:

```bash
python "$CODEX_HOME/skills/.system/imagegen/scripts/image_gen.py" generate \
  --prompt-file ui/assets/tilemap/prompts/gpt-image-2-wenyu-valley.md \
  --quality high \
  --size 1024x1024 \
  --out ui/assets/tilemap/tilesets/wenyu-ground.png
```

## Object Tileset

```text
Use case: stylized-concept
Asset type: game object spritesheet
Primary request: Create pixel-art isometric object sprites for a spring Wenyu Valley town map.
Style/medium: crisp pixel art, 2.5D isometric, transparent or flat removable background
Composition/framing: separated object sprites with generous padding; bottom-center anchor; all objects compatible with 64x32 isometric ground tiles
Lighting/mood: top-left sunlight, bottom-right shadow
Required objects: large tree, small tree, bush, spring flower patch, warm civic path lamp
Constraints: no text, no UI, no characters, no buildings, no watermark; consistent palette and camera angle
Avoid: blurry antialiasing, perspective drift, baked ground plane larger than the object footprint
```

## Building Splits

```text
Use case: stylized-concept
Asset type: split-layer isometric building spritesheet
Primary request: Create isometric pixel-art building sprites for Wenyu Valley AI Innovation Town, split into base and roof/canopy layers.
Style/medium: crisp pixel art, Stardew-like warm civic valley, 2.5D isometric
Composition/framing: each building needs separate base and roof/canopy sprites, bottom-center anchor, no baked text
Lighting/mood: top-left sun, bottom-right pixel shadow
Required buildings: City Hall, MoonBook house, Worker Yard
Constraints: no labels, no UI, no characters, no watermark; roof/canopy layer must be separable so workers can render between base and roof
Avoid: single flattened building sprite, inconsistent camera angle, photorealism
```
