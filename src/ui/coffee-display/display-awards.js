// Actual winners are organizer-confirmed; AI supplements are display assets,
// never participant records or vote-derived results.
export const prizeItems={figure:{sprite:'figure',title:'史迪奇公仔',full:'assets/prize-figure-real.png'},tote:{sprite:'tote',title:'白色帆布包',full:'assets/prize-tote-real.png'},coffee:{sprite:'coffee',title:'半醒咖啡券'}};
const real=(title,author,asset,extra={})=>({kind:'work',title,author,thumb:`assets/${asset}-thumb.webp`,full:`assets/${asset}.png`,ai:false,selection:'organizer',...extra});
const ai=(title,asset)=>({kind:'work',title,author:'主办方 AI 创作',thumb:`assets/${asset}-thumb.webp`,full:`assets/${asset}.png`,ai:true,selection:'display-supplement'});
export const awardGroups=[
 {issue:1,theme:'半醒咖啡',rank:'一等奖',prize:'figure',works:[real('深秋半醒，刚刚好','小王','work-autumn')]},
 {issue:1,theme:'半醒咖啡',rank:'二等奖',prize:'tote',works:[ai('一盏未醒','award-second-ink'),ai('醒来频率','award-second-op')]},
 {issue:1,theme:'半醒咖啡',rank:'三等奖',prize:'coffee',works:[real('勺子','勺子','work-spoon'),real('森林氧吧','草莓奶昔','work-forest'),ai('早安，半醒','award-third-line')]},
 {issue:2,theme:'变身',rank:'一等奖',prize:'figure',works:[real('执豆为杖 予你醇香','魔法使','week02-winner',{entryId:'c14d65aa5fc59a9269078b73a8d4ddf5d374d273ecbd4391a5058e4780587125',confirmedOn:'2026-11-22'})]},
 {issue:2,theme:'变身',rank:'二等奖',prize:'tote',works:[ai('折光新生','week02-refraction'),ai('破茧时刻','week02-butterfly')]},
 {issue:2,theme:'变身',rank:'三等奖',prize:'coffee',works:[ai('风雨之后','week02-storm'),ai('醒成一束光','week02-cyanotype'),ai('一杯新世界','week02-origami')]},
];
export function workCaption(group,work){return `第${group.issue}期 · ${group.theme} · ${group.rank} · ${work.ai?'AI 补位展示':'主办方确认获奖'} · ${work.author}`}
export function tickerDuration(width,viewportWidth){return Math.max(45,width/Math.max(48,viewportWidth*.012))}
