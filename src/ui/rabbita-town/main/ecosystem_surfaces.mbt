///|
/// The status digest is intentionally an inset of the existing expandable
/// town-status surface. It ranks at most three signals and never competes with
/// the map as a permanent panel.
fn render_ecosystem_attention_digest(
  dispatch : Dispatch[Msg],
  model : Model,
  semantic_snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  let seed = active_energy_valley_seed()
  let semantic_signal_count = semantic_snapshot.active_signals().length()
  let semantic_world_invalid = ecosystem_contract_world_validation_failed(
      model, seed,
    ) ||
    ecosystem_contract_snapshot_validation_failed(model, seed)
  let semantic_validation_summary = ecosystem_contract_validation_summary(
    model, seed,
  )
  let focused_place_id = match model.energy_selected_building {
    Some(building) => ecosystem_place_profile_for_building(building).id
    None => ""
  }
  let attention = ecosystem_attention_feed(
    model,
    seed,
    focused_place_id,
    model.ecosystem_attention_receipts,
    3,
  )
  section(class="ecosystem-attention-digest", [
    header(class="ecosystem-digest-header", [
      div([
        p(class="ecosystem-digest-eyebrow", "此刻值得看"),
        p(
          class="ecosystem-digest-rule",
          "真实工作优先；看过的日常信号会自动降温。",
        ),
      ]),
      span(
        class="ecosystem-digest-count",
        title="统一语义快照 · \{semantic_signal_count} 个有效信号 · \{semantic_snapshot.active_presences().length()} 个在途/在场主体 · \{semantic_snapshot.active_exchanges().length()} 条场所交换",
        if attention.is_empty() {
          "安静"
        } else {
          "\{attention.length()} 条"
        },
      ),
    ]),
    div([
      if semantic_world_invalid {
        p(
          class="ecosystem-digest-validation-warning",
          title=semantic_validation_summary,
          "地图语义校验未通过；底图仍可查看，但道路交互、在场与交换已安全停用。",
        )
      } else {
        span("")
      },
      if attention.is_empty() {
        p(
          class="ecosystem-digest-empty",
          "暂无需要你处理的新信号；居民日常与道路流动仍在继续。",
        )
      } else {
        div(
          class="ecosystem-digest-list",
          attention.map(item => render_ecosystem_attention_item(dispatch, item)),
        )
      },
    ]),
  ])
}

///|
fn ecosystem_attention_item_tone(signal : EcosystemAttentionSignal) -> String {
  if signal.urgency >= 82 {
    "is-alert"
  } else {
    match signal.provenance {
      RuntimeLive => "is-live"
      RuntimeRecord => "is-recorded"
      AmbientPreview => "is-ambient"
      LocalPlayer => "is-player"
      AuthoredPlace | LocalPlace => "is-place"
    }
  }
}

///|
fn ecosystem_provenance_tone(source : EcosystemProvenance) -> String {
  match source {
    RuntimeLive => "is-live"
    RuntimeRecord => "is-recorded"
    AmbientPreview => "is-ambient"
    LocalPlayer => "is-player"
    AuthoredPlace => "is-authored"
    LocalPlace => "is-local"
  }
}

///|
fn render_ecosystem_attention_item(
  dispatch : Dispatch[Msg],
  item : EcosystemRankedAttention,
) -> @rabbita.Html {
  let signal = item.signal
  let disclosure = ecosystem_attention_disclosure(signal)
  article(
    class="ecosystem-digest-item \{ecosystem_attention_item_tone(signal)}",
    [
      div(class="ecosystem-digest-item-copy", [
        div(class="ecosystem-digest-item-meta", [
          span(
            class="ecosystem-provenance-badge \{ecosystem_provenance_tone(signal.provenance)}",
            disclosure.provenance_badge,
          ),
          span(
            class="ecosystem-digest-score",
            "关注 \{item.score.clamp(min=0, max=999)}",
          ),
        ]),
        p(class="ecosystem-digest-headline", disclosure.nearby),
        p(
          class="ecosystem-digest-detail",
          ecosystem_compact_text(
            energy_valley_safe_runtime_copy(
              signal.detail,
              "详细内容含本地路径或过长信息，已隐藏。",
              150,
            ),
            78,
          ),
        ),
      ]),
      button(
        class="ecosystem-digest-action",
        on_click=dispatch(
          OpenEcosystemAttention(signal.cooldown_key, signal.interaction_target),
        ),
        attrs=@html.Attrs::build().aria_label(
          "\{disclosure.interaction_label}：\{signal.headline}",
        ),
        disclosure.interaction_label,
      ),
    ],
  )
}

///|
fn ecosystem_place_vitality(
  model : Model,
  building : GoldenValleyBuilding,
  semantic_world : @energy_valley_contract.CompiledTownWorld,
) -> Int {
  let snapshot = ecosystem_cached_world_snapshot(
    model,
    active_energy_valley_seed(),
  )
  match ecosystem_canvas_place_for_building(snapshot, building) {
    Some(place) => {
      let target_id = ecosystem_contract_attention_target_id(
        ecosystem_contract_id(place.id),
      )
      match semantic_world.find_attention_target(target_id) {
        Some(target) => target.base_salience_per_mille / 10
        None => ecosystem_canvas_attention_total(place.attention)
      }
    }
    None => {
      let profile = ecosystem_place_profile_for_building(building)
      (profile.focus_bias + profile.social_bias + profile.discovery_bias) / 3
    }
  }
}

///|
fn ecosystem_story_runtime_provenance(
  model : Model,
  profile : EcosystemPlaceProfile,
  place : EcosystemPlace,
  snapshot : @energy_valley_contract.TownSnapshot,
) -> EcosystemProvenance {
  let presence = ecosystem_place_presence_view(
    model,
    snapshot,
    ecosystem_contract_id(place.id),
  )
  let records = ecosystem_story_runtime_record_counts(model, place)
  if presence.runtime_inside_count > 0 || presence.runtime_arriving_count > 0 {
    RuntimeLive
  } else if records.0 > 0 || records.1 > 0 {
    RuntimeRecord
  } else {
    profile.provenance
  }
}

///|
/// Runtime record counts are an overlay query keyed by the place's stable
/// resource binding. They are deliberately never stored in the compatibility
/// world, so a cache hit cannot preserve a previous Live observation.
fn ecosystem_story_runtime_record_counts(
  model : Model,
  place : EcosystemPlace,
) -> (Int, Int) {
  match (place.runtime.runtime_key, model.energy_valley_runtime.projection) {
    (Some(runtime_key), Some(projection)) => {
      let task_count = projection.tasks
        .filter(task => {
          ecosystem_runtime_key_matches(task.buildingModuleKey, runtime_key)
        })
        .length()
      let agent_count = projection.agents
        .filter(agent => {
          match agent.buildingModuleKey {
            Some(agent_key) =>
              ecosystem_runtime_key_matches(agent_key, runtime_key)
            None => false
          }
        })
        .length()
      (task_count, agent_count)
    }
    _ => (0, 0)
  }
}

///|
fn ecosystem_story_runtime_copy(
  model : Model,
  place : EcosystemPlace,
  snapshot : @energy_valley_contract.TownSnapshot,
) -> String {
  let records = ecosystem_story_runtime_record_counts(model, place)
  let task_count = records.0
  let agent_count = records.1
  let semantic_place_id = ecosystem_contract_id(place.id)
  let runtime_presences = snapshot
    .presences_at(semantic_place_id)
    .filter(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    })
  let inside_count = runtime_presences
    .filter(presence => presence.phase is @energy_valley_contract.Inside)
    .length()
  let arriving_count = runtime_presences
    .filter(presence => {
      presence.phase is @energy_valley_contract.Approaching ||
      presence.phase is @energy_valley_contract.AtEntrance
    })
    .length()
  if inside_count > 0 && model.energy_valley_runtime.phase is Live {
    "真实运行时在场 · \{task_count} 项工作 · 在内 Agent \{inside_count} 位"
  } else if arriving_count > 0 && model.energy_valley_runtime.phase is Live {
    "真实运行时在途 · \{task_count} 项工作 · 将到 Agent \{arriving_count} 位；尚未计入建筑占用"
  } else if (task_count > 0 || agent_count > 0) &&
    model.energy_valley_runtime.phase is Live {
    "当前运行时记录已关联 · \{task_count} 项工作 · 快照 Agent \{agent_count} 位；尚无到达或在场证据"
  } else if task_count > 0 || agent_count > 0 {
    "最近运行时记录 · \{task_count} 项工作 · 快照 Agent \{agent_count} 位；不代表当前仍在执行"
  } else {
    "场所日常为环境叙事；当前没有真实运行时工作证据"
  }
}

///|
fn ecosystem_story_program_label(
  local_key : String,
  fallback : String,
) -> String {
  match local_key {
    "civic-hall" => "公共服务厅"
    "civic-court" => "市民庭院"
    "research-lab" => "科研实验室"
    "research-garden" => "科研花园"
    "street-homes" => "临街居所"
    "residential-court" => "社区庭院"
    "valley-market" => "谷地市集"
    "mixed-court" => "混合共享庭院"
    "park-pavilion" => "公园亭"
    "park-commons" => "公园共享地"
    "waterfront-pavilion" => "滨水亭"
    "waterfront-walk" => "滨水步道"
    "transit-hall" => "交通大厅"
    "transit-court" => "交通前庭"
    _ => fallback
  }
}

///|
/// Explains the bounded procedural decision without exposing compiler noise.
/// Geography remains Wenyu-authored; this program and seed are the stable DNA
/// that drive the place's massing, roof, interior, and extra interaction slot.
fn ecosystem_story_program_copy(
  world : @energy_valley_contract.CompiledTownWorld,
  place_id : String,
) -> String {
  match world.find_place(ecosystem_contract_id(place_id)) {
    Some(place) =>
      match place.program_id {
        Some(program_id) =>
          match world.find_parcel_program(program_id) {
            Some(program) => {
              let label = ecosystem_story_program_label(
                program.id.local_key(),
                program.label,
              )
              let variant = match place.building {
                Some(building) => building.interior_seed.abs() % 1000
                None => world.layout_seed.abs() % 1000
              }
              "\{label} · 空间变体 \{variant}"
            }
            None => "程序引用缺失；已停止生成扩展"
          }
        None => "温榆原始场所 · 保留地理骨架"
      }
    None => "场所尚未进入统一编译世界"
  }
}

///|
fn ecosystem_story_primary_frontage(
  snapshot : EcosystemWorldSnapshot,
  place_id : String,
  entrance : EcosystemEntrance?,
) -> EcosystemRoadFrontage? {
  let links = ecosystem_frontages_for_place(snapshot, place_id)
  match entrance {
    Some(primary) =>
      for link in links {
        if link.entrance_id == primary.id {
          return Some(link)
        }
      }
    None => ()
  }
  if links.is_empty() {
    None
  } else {
    Some(links[0])
  }
}

///|
fn ecosystem_story_road_class_label(road_class : String) -> String {
  match road_class {
    "major" | "M" => "主干路"
    "bridge" | "b" => "桥梁"
    "local" | "R" => "街区道路"
    "custom" => "本地新路"
    other if other.is_empty() => "道路"
    other => other
  }
}

///|
fn ecosystem_story_access_copy(
  entrance : EcosystemEntrance?,
  frontage : EcosystemRoadFrontage?,
) -> String {
  match (entrance, frontage) {
    (Some(portal), Some(link)) => {
      let connection = if link.direct {
        "直接接入"
      } else {
        "经 \{link.distance} 格步行接驳"
      }
      let accessibility = if portal.accessible {
        "可通行"
      } else {
        "暂不可通行"
      }
      "\{portal.label} · \{ecosystem_story_road_class_label(link.road_class)} · \{connection} · \{accessibility}"
    }
    (Some(portal), None) =>
      "\{portal.label}已定位，但尚无道路接驳证据"
    (None, _) => "尚未编译出可用入口与道路接驳"
  }
}

///|
/// Reconciles the compatibility doorway with the accepted contract world.
/// Local frontage geometry alone cannot claim access: the semantic portal must
/// still be bound to the compiler's gateway-connected pedestrian component.
fn ecosystem_story_semantic_access(
  snapshot : EcosystemWorldSnapshot,
  place : EcosystemPlace,
  semantic_world : @energy_valley_contract.CompiledTownWorld,
) -> (EcosystemEntrance?, EcosystemRoadFrontage?) {
  match semantic_world.find_place(ecosystem_contract_id(place.id)) {
    None => (None, None)
    Some(semantic_place) =>
      match semantic_place.primary_entrance() {
        None => (None, None)
        Some(semantic_portal) => {
          let mut resolved : EcosystemEntrance? = None
          for candidate in snapshot.entrances {
            if candidate.place_id == place.id &&
              candidate.id == semantic_portal.id.to_string() {
              resolved = Some({
                ..candidate,
                accessible: semantic_portal.road_node_id is Some(_) &&
                semantic_place.traits.any(place_trait => {
                  place_trait is @energy_valley_contract.Accessible
                }),
              })
              break
            }
          }
          match resolved {
            Some(entrance) if entrance.accessible =>
              (
                Some(entrance),
                ecosystem_story_primary_frontage(
                  snapshot,
                  place.id,
                  Some(entrance),
                ),
              )
            Some(entrance) => (Some(entrance), None)
            None => (None, None)
          }
        }
      }
  }
}

///|
fn ecosystem_story_semantic_affordances(
  snapshot : EcosystemWorldSnapshot,
  place : EcosystemPlace,
  semantic_world : @energy_valley_contract.CompiledTownWorld,
) -> Array[EcosystemWorldAffordance] {
  let semantic_place = semantic_world.find_place(
    ecosystem_contract_id(place.id),
  )
  ecosystem_affordances_for_place(snapshot, place.id).map(affordance => {
    let enabled = match semantic_place {
      None => false
      Some(accepted) =>
        affordance.enabled &&
        accepted.interaction_slots.any(slot => {
          slot.id == ecosystem_contract_id(affordance.id)
        })
    }
    { ..affordance, enabled, }
  })
}

///|
fn ecosystem_story_affordance_label(kind : EcosystemAffordanceKind) -> String {
  match kind {
    EcosystemInspect => "查看"
    EcosystemEnter => "进入"
    EcosystemWork => "工作"
    EcosystemExchange => "交换"
    EcosystemRest => "休息"
    EcosystemObserve => "观察"
    EcosystemTravel => "通行"
    EcosystemPublish => "发布"
    EcosystemGather => "聚集"
  }
}

///|
fn ecosystem_story_relation_identity(identity : String) -> String {
  match identity {
    "vitality-tower" => "vitality-dashboard"
    "story-radar" => "broadcast-tower"
    other => other
  }
}

///|
fn render_ecosystem_place_relationships(
  semantic_world : @energy_valley_contract.CompiledTownWorld,
  place_id : String,
  affordances : Array[EcosystemWorldAffordance],
) -> @rabbita.Html {
  let relations = semantic_world.relations_from(ecosystem_contract_id(place_id))
  let relation_chips : Array[@rabbita.Html] = []
  for relation in relations {
    relation_chips.push(
      span(
        class="ecosystem-relation-chip",
        semantic_world
        .find_place(relation.target_place_id)
        .map(target => target.name)
        .unwrap_or(relation.target_place_id.local_key()),
      ),
    )
  }
  @html.details(class="ecosystem-story-details", [
    @html.summary(class="ecosystem-story-summary", [
      span("它如何连接全镇"),
      span(
        class="ecosystem-story-summary-count",
        "\{relations.length()} 个关系 · \{affordances.length()} 个能力",
      ),
    ]),
    div(class="ecosystem-story-details-body", [
      div(class="ecosystem-story-detail-group", [
        p(class="ecosystem-story-detail-label", "协作关系"),
        if relations.is_empty() {
          p(
            class="ecosystem-story-detail-empty",
            "这是本地生成场所；目前只通过入口和路网接入小镇。",
          )
        } else {
          div(class="ecosystem-relation-list", relation_chips)
        },
      ]),
      div(class="ecosystem-story-detail-group", [
        p(class="ecosystem-story-detail-label", "可发生的动作"),
        if affordances.is_empty() {
          p(class="ecosystem-story-detail-empty", "尚未声明可用动作。")
        } else {
          div(
            class="ecosystem-affordance-list",
            affordances.map(affordance => {
              span(
                class="ecosystem-affordance \{if affordance.enabled { "is-enabled" } else { "is-disabled" }}",
                "\{ecosystem_story_affordance_label(affordance.kind)} · \{affordance.capacity.max(1)} 位",
              )
            }),
          )
        },
      ]),
    ]),
  ])
}

///|
/// A story block for the existing building inspector. Geography, access,
/// affordances, and runtime claims all come from the same compiled snapshot;
/// prose only supplies personality and progressive explanation.
fn render_ecosystem_place_story(
  model : Model,
  building : GoldenValleyBuilding,
  semantic_snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  let seed = active_energy_valley_seed()
  let profile = ecosystem_place_profile_for_building(building)
  let snapshot = ecosystem_cached_world_snapshot(model, seed)
  match ecosystem_canvas_place_for_building(snapshot, building) {
    None =>
      section(class="ecosystem-place-story is-unresolved", [
        div(class="ecosystem-place-story-header", [
          div(class="ecosystem-place-glyph", profile.glyph),
          div([
            p(class="ecosystem-place-character", profile.characteristic),
            p(
              class="ecosystem-story-copy",
              "场所个性已生成，但语义入口尚未完成编译；不会伪造道路或运行时状态。",
            ),
          ]),
        ]),
      ])
    Some(place) => {
      let semantic_world = semantic_snapshot.world
      let provenance = ecosystem_story_runtime_provenance(
        model, profile, place, semantic_snapshot,
      )
      let vitality = ecosystem_place_vitality(model, building, semantic_world)
      let presence = ecosystem_place_presence_view(
        model,
        semantic_snapshot,
        ecosystem_contract_id(place.id),
      )
      let (entrance, frontage) = ecosystem_story_semantic_access(
        snapshot, place, semantic_world,
      )
      let affordances = ecosystem_story_semantic_affordances(
        snapshot, place, semantic_world,
      )
      section(class="ecosystem-place-story", [
        div(class="ecosystem-place-story-header", [
          div(
            class="ecosystem-place-glyph",
            style=["--ecosystem-accent: \{profile.accent}"],
            profile.glyph,
          ),
          div(class="ecosystem-place-story-heading", [
            div(class="ecosystem-place-story-title-row", [
              p(class="ecosystem-place-character", profile.characteristic),
              span(
                class="ecosystem-provenance-badge \{ecosystem_provenance_tone(provenance)}",
                ecosystem_provenance_badge(provenance),
              ),
            ]),
            p(class="ecosystem-story-copy", profile.living_detail),
          ]),
        ]),
        div(class="ecosystem-vitality", [
          div(class="ecosystem-vitality-row", [
            span("语义活力"),
            span(class="ecosystem-vitality-value", "\{vitality}"),
          ]),
          div(
            class="ecosystem-vitality-track",
            attrs=@html.Attrs::build().aria_label(
              "语义活力 \{vitality} / 100",
            ),
            [
              div(
                class="ecosystem-vitality-fill",
                style=[
                  "width: \{vitality}%",
                  "--ecosystem-accent: \{profile.accent}",
                ],
                no_children(),
              ),
            ],
          ),
        ]),
        div(
          class="ecosystem-place-now \{if presence.attention_boost > 0 { "is-active" } else { "is-quiet" }}",
          [
            div(class="ecosystem-place-now-glyph", presence.activity_glyph),
            div(class="ecosystem-place-now-copy", [
              div(class="ecosystem-place-now-heading", [
                span("此刻在这里"),
                if presence.provenance_groups.is_empty() {
                  span(
                    class="ecosystem-provenance-badge is-place",
                    "SEMANTIC · QUIET",
                  )
                } else {
                  div(
                    class="ecosystem-place-now-provenance",
                    presence.provenance_groups.map(group => {
                      span(
                        class="ecosystem-provenance-badge \{group.tone}",
                        "\{group.label} · \{group.count}",
                      )
                    }),
                  )
                },
              ]),
              p(ecosystem_place_presence_summary(presence)),
            ]),
          ],
        ),
        div(class="ecosystem-story-facts", [
          p(class="ecosystem-story-fact", [
            span(class="ecosystem-story-fact-label", "程序基因"),
            span(ecosystem_story_program_copy(semantic_world, place.id)),
          ]),
          p(class="ecosystem-story-fact", [
            span(class="ecosystem-story-fact-label", "运行真相"),
            span(ecosystem_story_runtime_copy(model, place, semantic_snapshot)),
          ]),
          p(
            class="ecosystem-story-fact \{if frontage is None { "is-warning" } else { "" }}",
            [
              span(class="ecosystem-story-fact-label", "到达方式"),
              span(ecosystem_story_access_copy(entrance, frontage)),
            ],
          ),
        ]),
        render_ecosystem_place_relationships(
          semantic_world,
          place.id,
          affordances,
        ),
      ])
    }
  }
}
