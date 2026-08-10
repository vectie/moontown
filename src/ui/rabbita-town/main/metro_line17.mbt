///|
/// Beijing Subway Line 17 overlay: the real northern terminus of Line 17
/// sits inside the Energy Valley (未来科学城北站 opened 2023-12-30, with
/// 未来科学城站 one stop south), so the town map draws the line as a
/// stylized teal alignment through the eastern campus — the single most
/// recognizable modern landmark of the real district.
priv struct MetroExit {
  label : String
  destination : String
  x : Double
  y : Double
}

///|
priv struct MetroStation {
  name : String
  x : Double
  y : Double
  exits : Array[MetroExit]
}

///|
fn metro_line17_path() -> Array[(Double, Double)] {
  if authoritative_energy_valley_transport_ready() {
    let result : Array[(Double, Double)] = []
    for index in 0..<authoritative_energy_valley_metro_path_count() {
      result.push(
        (
          authoritative_energy_valley_metro_path_x(index).to_double() / 1000.0,
          authoritative_energy_valley_metro_path_y(index).to_double() / 1000.0,
        ),
      )
    }
    return result
  }
  if reference_line17_snapshot_ready() {
    let result : Array[(Double, Double)] = []
    for index in 0..<reference_line17_path_count() {
      result.push(
        (
          reference_line17_path_x_millis(index).to_double() / 1000.0,
          reference_line17_path_y_millis(index).to_double() / 1000.0,
        ),
      )
    }
    return result
  }
  [
    (139.5, 143.5),
    (136.0, 128.0),
    (131.5, 112.0),
    (128.0, 99.0),
    (126.5, 88.0), // 未来科学城站
    (125.5, 76.0),
    (125.0, 64.0),
    (125.0, 52.0), // 未来科学城北站
    (124.0, 38.0),
    (122.5, 20.0),
    // The alignment continues north off-map, but its semantic geometry ends
    // at the compiled world boundary. The visible stroke still reaches the
    // edge without publishing an out-of-bounds installation position.
    (121.5, 0.0),
  ]
}

///|
fn metro_line17_stations() -> Array[MetroStation] {
  if authoritative_energy_valley_transport_ready() {
    let result : Array[MetroStation] = []
    for station_index in 0..<authoritative_energy_valley_metro_station_count() {
      let exits : Array[MetroExit] = []
      for
        exit_index in 0..<authoritative_energy_valley_metro_exit_count(
          station_index,
        ) {
        exits.push({
          label: authoritative_energy_valley_metro_exit_label(
            station_index, exit_index,
          ),
          destination: authoritative_energy_valley_metro_exit_destination(
            station_index, exit_index,
          ),
          x: authoritative_energy_valley_metro_exit_x(station_index, exit_index).to_double() /
          1000.0,
          y: authoritative_energy_valley_metro_exit_y(station_index, exit_index).to_double() /
          1000.0,
        })
      }
      result.push({
        name: authoritative_energy_valley_metro_station_name(station_index),
        x: authoritative_energy_valley_metro_station_x(station_index).to_double() /
        1000.0,
        y: authoritative_energy_valley_metro_station_y(station_index).to_double() /
        1000.0,
        exits,
      })
    }
    return result
  }
  if reference_line17_snapshot_ready() {
    let result : Array[MetroStation] = []
    for station_index in 0..<reference_line17_station_count() {
      let exits : Array[MetroExit] = []
      for exit_index in 0..<reference_line17_exit_count(station_index) {
        exits.push({
          label: reference_line17_exit_label(station_index, exit_index),
          destination: reference_line17_exit_destination(
            station_index, exit_index,
          ),
          x: reference_line17_exit_x_millis(station_index, exit_index).to_double() /
          1000.0,
          y: reference_line17_exit_y_millis(station_index, exit_index).to_double() /
          1000.0,
        })
      }
      result.push({
        name: reference_line17_station_name(station_index),
        x: reference_line17_station_x_millis(station_index).to_double() / 1000.0,
        y: reference_line17_station_y_millis(station_index).to_double() / 1000.0,
        exits,
      })
    }
    return result
  }
  [
    {
      name: "未来科学城站",
      x: 126.5,
      y: 88.0,
      exits: [
        { label: "A", destination: "能源谷核心区", x: 124.8, y: 87.0 },
        { label: "B", destination: "能源谷核心区", x: 128.2, y: 89.0 },
      ],
    },
    {
      name: "未来科学城北站",
      x: 125.0,
      y: 52.0,
      exits: [
        { label: "C", destination: "英才北一街", x: 123.4, y: 51.0 },
        { label: "D", destination: "英才北一街", x: 126.7, y: 53.0 },
      ],
    },
  ]
}

///|
fn metro_line17_station_exit_count() -> Int {
  metro_line17_stations().fold(init=0, fn(total, station) {
    total + station.exits.length()
  })
}

///|
/// Resolve the exact display/installation point independently from the
/// integer portal threshold used by the legacy pathfinding seam.
fn metro_line17_station_exit_position(
  station_name : String,
  exit_label : String,
) -> (Double, Double)? {
  for station in metro_line17_stations() {
    if station.name != station_name {
      continue
    }
    for exit in station.exits {
      if exit.label == exit_label {
        return Some((exit.x, exit.y))
      }
    }
  }
  None
}

///|
fn metro_station_exit_summary(station : MetroStation) -> String {
  if station.exits.is_empty() {
    return ""
  }
  let labels = station.exits.map(exit => exit.label).join(" / ")
  "\{labels} 口 · \{station.exits[0].destination}"
}

///|
fn metro_line17_close_detail_visible(zoom : Double) -> Bool {
  zoom >= 0.72
}

///|
/// One JS crossing draws the whole alignment: casing, teal body, and the
/// sleeper ticks, from screen-space points serialized by MoonBit.
extern "js" fn golden_draw_metro_line(
  context : @dom.CanvasRenderingContext2D,
  points_json : String,
  zoom : Double,
) -> Unit =
  #| (context, pointsJson, zoom) => {
  #|   const points = JSON.parse(pointsJson);
  #|   if (!Array.isArray(points) || points.length < 2) return;
  #|   const trace = () => {
  #|     context.beginPath();
  #|     context.moveTo(points[0][0], points[0][1]);
  #|     for (let index = 1; index < points.length; index += 1) {
  #|       const [px, py] = points[index];
  #|       const [qx, qy] = points[index - 1];
  #|       context.quadraticCurveTo(
  #|         qx, qy, (px + qx) / 2, (py + qy) / 2,
  #|       );
  #|     }
  #|     const last = points[points.length - 1];
  #|     context.lineTo(last[0], last[1]);
  #|   };
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|   context.strokeStyle = "rgba(245,253,255,0.85)";
  #|   context.lineWidth = Math.max(2.4, 10 * zoom);
  #|   trace();
  #|   context.stroke();
  #|   context.strokeStyle = "#00a3a8";
  #|   context.lineWidth = Math.max(1.6, 6 * zoom);
  #|   trace();
  #|   context.stroke();
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_metro_station(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  name : String,
  exit_summary : String,
) -> Unit =
  #| (context, sx, sy, zoom, name, exitSummary) => {
  #|   const radius = Math.max(4, 13 * zoom);
  #|   context.save();
  #|   context.beginPath();
  #|   context.arc(sx, sy, radius + Math.max(1.5, 3 * zoom), 0, Math.PI * 2);
  #|   context.fillStyle = "rgba(255,255,255,0.92)";
  #|   context.fill();
  #|   context.beginPath();
  #|   context.arc(sx, sy, radius, 0, Math.PI * 2);
  #|   context.fillStyle = "#00a3a8";
  #|   context.fill();
  #|   context.fillStyle = "#ffffff";
  #|   const badge = Math.max(7, 11 * zoom);
  #|   context.font = `700 ${badge}px sans-serif`;
  #|   context.textAlign = "center";
  #|   context.textBaseline = "middle";
  #|   context.fillText("17", sx, sy + badge * 0.06);
  #|   if (zoom >= 0.16) {
  #|     const fontSize = Math.max(9, 22 * zoom);
  #|     context.font = `600 ${fontSize}px sans-serif`;
  #|     const padding = fontSize * 0.45;
  #|     const width = context.measureText(name).width + padding * 2;
  #|     const lx = sx + radius + Math.max(4, 8 * zoom);
  #|     const showExit = zoom >= 0.72 && exitSummary;
  #|     const ly = sy - fontSize * 0.75;
  #|     const labelHeight = showExit ? fontSize * 2.45 : fontSize * 1.5;
  #|     context.fillStyle = "rgba(8,25,32,0.72)";
  #|     context.beginPath();
  #|     context.roundRect(
  #|       lx, ly, Math.max(width, showExit
  #|         ? context.measureText(exitSummary).width + padding * 2
  #|         : width), labelHeight, fontSize * 0.4,
  #|     );
  #|     context.fill();
  #|     context.fillStyle = "#ecfeff";
  #|     context.textAlign = "left";
  #|     context.fillText(name, lx + padding, ly + fontSize * 0.78);
  #|     if (showExit) {
  #|       context.fillStyle = "rgba(207,250,254,0.82)";
  #|       context.font = `500 ${Math.max(8, fontSize * 0.78)}px sans-serif`;
  #|       context.fillText(exitSummary, lx + padding, ly + fontSize * 1.72);
  #|     }
  #|   }
  #|   context.restore();
  #| }

///|
/// A small glass-and-teal pavilion gives each typed exit a physical landmark,
/// rather than leaving the exit copy stranded in an unseen data field.
extern "js" fn golden_draw_metro_station_exit(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  label : String,
) -> Unit =
  #| (context, sx, sy, zoom, label) => {
  #|   if (zoom < 0.72) return;
  #|   const width = Math.max(5, 12 * zoom);
  #|   const height = Math.max(4, 10 * zoom);
  #|   context.save();
  #|   context.fillStyle = "rgba(5,30,35,0.28)";
  #|   context.beginPath();
  #|   context.ellipse(sx + 2, sy + 2, width * 0.72, height * 0.36,
  #|     0, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.fillStyle = "rgba(190,238,240,0.88)";
  #|   context.strokeStyle = "#007f84";
  #|   context.lineWidth = Math.max(0.8, 1.4 * zoom);
  #|   context.beginPath();
  #|   context.moveTo(sx - width / 2, sy);
  #|   context.lineTo(sx - width * 0.34, sy - height);
  #|   context.lineTo(sx + width * 0.5, sy - height * 0.64);
  #|   context.lineTo(sx + width / 2, sy);
  #|   context.closePath();
  #|   context.fill();
  #|   context.stroke();
  #|   context.fillStyle = "#006c70";
  #|   context.beginPath();
  #|   context.roundRect(
  #|     sx - width * 0.24, sy - height * 1.35,
  #|     width * 0.48, height * 0.58, Math.max(1, 2 * zoom),
  #|   );
  #|   context.fill();
  #|   context.fillStyle = "#ffffff";
  #|   context.font = `700 ${Math.max(6, 9 * zoom)}px sans-serif`;
  #|   context.textAlign = "center";
  #|   context.textBaseline = "middle";
  #|   context.fillText(label, sx, sy - height * 1.06);
  #|   context.restore();
  #| }

///|
/// Small floating legend so a first-time player understands the teal line.
fn render_metro_legend(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if !model.metro_visible {
    return @html.nothing
  }
  div(class="metro-legend pointer-events-auto", [
    span(class="metro-legend-badge", "17"),
    span(class="metro-legend-copy", [
      div(class="metro-legend-title", "地铁 17 号线 · 贯穿能源谷"),
      div(
        class="metro-legend-sub",
        "未来科学城北 → 未来科学城 → 望京西 · 4 站到望京",
      ),
    ]),
  ])
}
