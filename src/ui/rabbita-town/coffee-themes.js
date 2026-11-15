const firstPrompts=[
 ['杯里小城','一只装着清晨的咖啡杯，杯中是一座还没有醒来的微缩小城，奶油色和森林绿，温暖的手绘插画，安静而奇妙，不要文字和商标'],
 ['云朵打盹','半醒咖啡的奇妙早晨，一只打哈欠的小云朵坐在咖啡杯边，纸质拼贴与柔软的剪纸层次，温暖阳光，简洁构图，不要文字和商标'],
 ['一口森林','半醒时刻的咖啡想象，咖啡香气化成一片会生长的小森林，黏土微缩世界，圆润可爱，暖奶油底色与自然绿，不要文字和商标'],
];
const transformationPrompts=[
 ['折光变身','变身主题，成年少女的大头像微微仰向蓝天，目光看向镜头，手举一只有透明把手的切面水晶咖啡杯，杯中是琥珀色咖啡。阳光穿过杯子的透明切面，在脸颊、肩膀和飘动的深蓝发丝上折射出彩虹光带。精致日系平面插画，利落线条，鲜明明暗色块，清透蓝紫色，构图集中在人脸、杯子和光，不要文字、水印和商标'],
 ['自我成蝶','变身主题，一位成年女子跪坐在地上，双手捧着咖啡，坚毅而充满希望。一侧虹彩蝶翼已从纱中展开，另一侧仍在挣脱茧丝，蝶翼里映出过去低头的自己。成熟平面艺术插画，流动线条，宝石般的光色，粉紫晨光，简洁有力，不要文字、水印和商标'],
 ['风雨蜕变','变身主题，一位成年人端坐于台上，手捧一杯咖啡，周围是风雨交加的蓝紫夜空与闪电。衣角正在蜕变为发光的晶体，身后留下过去低头的影子，咖啡蒸汽平静上升。成熟平面艺术插画，强烈明暗，清晰色块，有力量和希望，不要文字、水印和商标'],
];
export function creationGuide(event={}) {
 const transformation=/(?:变身|蜕变)/.test(event.topic || '') || /^banxing-coffee-(?:20261116|week02-qa)/.test(event.id || '');
 return transformation?{key:'transformation',label:'描述你的变身灵感',placeholder:'不填也可以：阳光穿过水晶咖啡杯，在少女身上映出彩色折光。',prompts:transformationPrompts,reference:'coffee/transformation-reference.webp',referenceAlt:'本期变身灵感示例，非参赛作品'}:{key:'first',label:'描述你的半醒时刻',placeholder:'不填也可以：我们会画一座住在咖啡杯里的清晨小城。',prompts:firstPrompts,reference:'coffee/cup.png',referenceAlt:'主办参考杯型，非参赛作品'};
}
