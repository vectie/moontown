// Winners shown here are organizer-confirmed display selections. Generated
// display assets retain provenance here and are never backend participant records.
export const prizeItems={figure:{sprite:'figure',title:'史迪奇公仔',full:'assets/prize-figure-real.png'},judy:{sprite:'figure',title:'朱迪侦探手办',thumb:'assets/prize-judy-v1.webp',full:'assets/prize-judy-v1.png'},tote:{sprite:'tote',title:'白色帆布包',full:'assets/prize-tote-real.png'},coffee:{sprite:'coffee',title:'半醒咖啡券'}};
const real=(title,author,asset,extra={})=>({kind:'work',title,author,thumb:`assets/${asset}-thumb.webp`,full:`assets/${asset}.png`,ai:false,selection:'organizer',...extra});
const ai=(title,author,asset)=>({kind:'work',title,author,thumb:`assets/${asset}-thumb.webp`,full:`assets/${asset}.png`,ai:true,selection:'organizer-display'});
export const awardGroups=[
 {issue:1,theme:'半醒咖啡',rank:'一等奖',prize:'figure',works:[real('深秋半醒，刚刚好','小王','work-autumn')]},
 {issue:1,theme:'半醒咖啡',rank:'二等奖',prize:'tote',works:[ai('一盏未醒','白桃乌龙','award-second-ink'),ai('醒来频率','薄荷星','award-second-op')]},
 {issue:1,theme:'半醒咖啡',rank:'三等奖',prize:'coffee',works:[real('勺子','勺子','work-spoon'),real('森林氧吧','草莓奶昔','work-forest'),ai('早安，半醒','小满','award-third-line')]},
 {issue:2,theme:'变身',rank:'一等奖',prize:'judy',works:[real('执豆为杖 予你醇香','魔法使','week02-winner',{entryId:'c14d65aa5fc59a9269078b73a8d4ddf5d374d273ecbd4391a5058e4780587125',confirmedOn:'2026-11-22'})]},
 {issue:2,theme:'变身',rank:'二等奖',prize:'tote',works:[ai('折光新生','风铃','week02-refraction'),ai('破茧时刻','青禾','week02-butterfly')]},
 {issue:2,theme:'变身',rank:'三等奖',prize:'coffee',works:[ai('风雨之后','栗子云','week02-storm'),ai('醒成一束光','橘子汽水','week02-cyanotype'),ai('一杯新世界','一朵慢云','week02-origami')]},
];
export function workCaption(group,work){return `第${group.issue}期 · ${group.theme} · ${group.rank} · 主办方确认获奖 · ${work.author}`}
export function tickerDuration(width,viewportWidth){return Math.max(45,width/Math.max(48,viewportWidth*.012))}
