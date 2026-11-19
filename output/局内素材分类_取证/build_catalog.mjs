import fs from 'node:fs/promises';
import path from 'node:path';

const cwd=process.cwd();
const evidence=path.join(cwd,'output','局内素材分类_取证');
const dest=path.join(cwd,'output','局内素材分类');
await fs.mkdir(dest,{recursive:true});
const files=(await fs.readdir(evidence)).filter(n=>/^(page_\d+|rows_\d+_\d+)\.json$/.test(n));
const raw=(await Promise.all(files.map(async n=>JSON.parse(await fs.readFile(path.join(evidence,n),'utf8'))))).flat().sort((a,b)=>a.index-b.index);
const meta=JSON.parse(await fs.readFile(path.join(evidence,'metadata.json'),'utf8'));
const configs=JSON.parse(await fs.readFile(path.join(evidence,'config_parsed.json'),'utf8'));
if(raw.length!==meta.total||new Set(raw.map(r=>r.index)).size!==meta.total)throw new Error('Inventory count or index mismatch');
for(let i=0;i<raw.length;i++)if(raw[i].index!==i+1)throw new Error('Missing snapshot row');
const byId=k=>new Map(configs[k].map(r=>[r.id,r]));
const resources=byId('ResourcesItemSetting'),crafts=byId('CraftItemSetting'),jobs=byId('CharaterSetting');
const enemies=new Map(configs.EnemySetting.map(r=>[r.name,r]));
const categories=['地形与植被','建筑与场景组合','营地与建造设施','资源、食物与消耗品','武器与交互工具','角色、敌人与动物','服饰、护具与皮肤','机关、特效与界面','辅助与空对象','待辨认素材'];
const label=(cat,sub,display,basis,notes='')=>({category:cat,subcategory:sub,display,basis,notes});
const translations={Map:'地图设施',Clock:'时钟',Bed:'帐篷',Wok:'烹饪锅',Torch:'火把',TravelStation:'传送车站',RespawnCoffin:'复活棺材',TimeMachine:'时间机器'};
const resourceTypes={
 Bag:['武器与交互工具','搬运袋'],Axe:['武器与交互工具','斧头'],Lamp:['武器与交互工具','油灯'],BluePrint:['武器与交互工具','蓝图道具'],Tool:['武器与交互工具','其他工具'],Sword:['武器与交互工具','近战武器'],Hammer:['武器与交互工具','建造锤'],Guitar:['武器与交互工具','吉他'],LightSaber:['武器与交互工具','光剑'],GoldPan:['武器与交互工具','淘金盘'],Dumbbell:['武器与交互工具','训练工具'],LadderBuilder:['武器与交互工具','梯子工具'],Bell:['武器与交互工具','驯兽工具'],Wormhole:['武器与交互工具','回城道具'],InfiniteWormholes:['武器与交互工具','回城道具'],LaserPistol:['武器与交互工具','能量武器'],Pickaxe:['武器与交互工具','矿镐'],
 Wood:['资源、食物与消耗品','木类回收物'],Combustible:['资源、食物与消耗品','燃料'],Iron:['资源、食物与消耗品','铁类回收物'],Vegetable:['资源、食物与消耗品','蔬果'],Meat:['资源、食物与消耗品','生肉食材'],Soup:['资源、食物与消耗品','汤'],TreeSeek:['资源、食物与消耗品','种子'],RabbitFoot:['资源、食物与消耗品','动物掉落'],Gold:['资源、食物与消耗品','金'],Gem:['资源、食物与消耗品','宝石'],CookedFood:['资源、食物与消耗品','熟食'],ItemReward:['资源、食物与消耗品','任务或奖励物'],Mushroom:['资源、食物与消耗品','蘑菇'],DetoxMushroom:['资源、食物与消耗品','解毒蘑菇'],ToxicMushroom:['资源、食物与消耗品','特殊消耗物'],Crystal:['资源、食物与消耗品','水晶'],ChristmasGift:['资源、食物与消耗品','圣诞礼物'],Niter:['资源、食物与消耗品','硝石'],Gear:['资源、食物与消耗品','齿轮'],KingTurkeyFeather:['资源、食物与消耗品','Boss掉落'],KingMooseAntler:['资源、食物与消耗品','Boss掉落'],
 Chestplate:['服饰、护具与皮肤','护甲'],FaceMask:['服饰、护具与皮肤','面罩'],Shoe:['服饰、护具与皮肤','鞋靴'],Scarf:['服饰、护具与皮肤','围巾'],Heal:['资源、食物与消耗品','医疗用品'],RevolverBullet:['资源、食物与消耗品','弹药'],RifleBullet:['资源、食物与消耗品','弹药'],ShotGunBullet:['资源、食物与消耗品','弹药'],GatlinBullet:['资源、食物与消耗品','弹药'],
 Gun:['武器与交互工具','枪械'],SAMRifle:['武器与交互工具','枪械'],Bow:['武器与交互工具','弓'],Throwable:['武器与交互工具','投掷武器'],Gatlin:['武器与交互工具','加特林'],Bomb:['武器与交互工具','爆炸物'],BarrelPistol4:['武器与交互工具','枪械'],HolyWater:['武器与交互工具','圣水'],ReusableMolotov:['武器与交互工具','投掷武器'],WeaponPart:['武器与交互工具','武器零件'],
 WolfSkin:['资源、食物与消耗品','动物皮料'],CougarSkin:['资源、食物与消耗品','动物皮料'],BearSkin:['资源、食物与消耗品','动物皮料'],MadBearSkin:['资源、食物与消耗品','动物皮料'],DeadBody:['资源、食物与消耗品','尸体道具'],UI:['机关、特效与界面','界面道具']};
function resource(r,lo){
 let type=resourceTypes[lo.ItemType]??['资源、食物与消耗品',/^Trophies/.test(lo.ItemType??'')?'奖励凭证':'其他物品'];
 if(lo.id>=701&&lo.id<=705)type=['资源、食物与消耗品','宝石工具'];
 if(lo.id===403)type=['资源、食物与消耗品','生物燃料'];
 return label(...type,lo.ItemName.trim(),'配置确认',`ResourcesItemSetting #${lo.id} / ${lo.ItemType}`);
}
function craft(r,lo){
 const n=lo.ItemName.trim();let sub=translations[lo.ItemType];
 if(!sub)sub=/Farm|Fish/.test(n)?'生产设施':/Bunny Trap|Catch Trap/.test(n)?'捕猎设施':/Ladder/.test(n)?'梯子':/Trap|Abatis|Wall|Wire|Door|Turret|Tesla|Gamma|Sheet|Watchtower|WatchTower/.test(n)?'防御设施':/Cooking/.test(n)?'烹饪设施':/Shelf|storage/.test(n)?'储物设施':/Fuel/.test(n)?'燃料生产':/Ammo/.test(n)?'弹药设施':/Wash/.test(n)?'淘金设施':'其他可建设施';
 return label('营地与建造设施',sub,n,'配置确认',`CraftItemSetting #${lo.id}`);
}
function classify(r){
 const p=r.path,n=r.name.trim(),id=/^\d+$/.test(n)?Number(n):null;
 if(r.parts===0)return label('辅助与空对象',r.descendants===0?'空对象':'无几何容器',n,'结构确认',r.descendants===0?'没有后代对象':'未发现 BasePart；不能据此判断无用途');
 if(r.class==='Terrain'||n==='SpawnLocation'||n==='Baseplate')return label('辅助与空对象',n==='SpawnLocation'?'出生点':n==='Terrain'?'Terrain对象':'底板',n,'结构确认');
 if(p.startsWith('Workspace.Prefabs.Resources.')){
  if(id!==null&&resources.has(id))return resource(r,resources.get(id));
  return label('待辨认素材','物品预设未映射',n,'待核实',n==='99999'?'多个同名保留项；未映射到物品配置':'处于 Resources 目录，未按当前名称匹配配置');
 }
 if(p.startsWith('Workspace.Prefabs.蓝图.')){
  if(id!==null&&crafts.has(id))return craft(r,crafts.get(id));
  return label('营地与建造设施','未映射设施预设',n,'目录确认','未匹配 CraftItemSetting');
 }
 if(p.startsWith('Workspace.Prefabs.CharacterHat.'))return label('服饰、护具与皮肤','职业头饰',jobs.has(id)?`${jobs.get(id).Name.trim()} 头饰`:n,'目录确认',jobs.has(id)?`CharaterSetting #${id}`:'职业编号未映射');
 if(p.startsWith('Workspace.Prefabs.CharacterAccessory.'))return label('服饰、护具与皮肤','职业配饰',jobs.has(id)?`${jobs.get(id).Name.trim()} 配饰`:n,'目录确认',jobs.has(id)?`CharaterSetting #${id}`:'职业编号未映射');
 if(p.startsWith('Workspace.Prefabs.皮肤.'))return label('服饰、护具与皮肤',p.includes('马头饰')?'马头饰皮肤':p.includes('动物伙伴')?'伙伴皮肤':'道具皮肤',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.巨型怪物.'))return r.class==='Accessory'?label('服饰、护具与皮肤','大型怪物配饰',n,'目录确认'):label('角色、敌人与动物','大型怪物',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.敌人.')){
  if(p.includes('阶段饰品'))return label('服饰、护具与皮肤','敌人阶段配饰',n,'目录确认');
  const lo=enemies.get(n);return label('角色、敌人与动物',lo?.isAnimal?'敌对动物':'敌人角色',n,lo?'配置确认':'目录确认',lo?`EnemySetting #${lo.id}`:'未按名称匹配 EnemySetting');
 }
 if(p.startsWith('Workspace.Prefabs.动物.'))return label('角色、敌人与动物','动物',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.伙伴.'))return label('角色、敌人与动物','动物伙伴',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.马匹.'))return label('角色、敌人与动物',p.includes('马皮肤')?'马匹外观':'马匹或驯鹿',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.UI.'))return label('机关、特效与界面','世界空间界面载体',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.NPC事件.')){
  if(/位置/.test(n))return label('辅助与空对象','NPC事件定位对象',n,'名称推断');
  if(r.humanoids===1&&!/^\d+x\d+,/.test(n))return label('角色、敌人与动物','事件NPC或敌人',n,'结构确认','位于 NPC事件 目录；具体职责待核实');
  return label('建筑与场景组合','NPC事件组合',n,'目录确认','按事件资源包登记；内部可能包含人物、载体与挂点');
 }
 if(p.startsWith('Workspace.Prefabs.圣诞节.')||p.startsWith('Workspace.Prefabs.万圣节.'))return r.class==='Accessory'?label('服饰、护具与皮肤','节日服饰',n,'目录确认'):label('建筑与场景组合','节日场景或控制载体',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.火车大劫案.')||p.startsWith('Workspace.火车大劫案.'))return r.humanoids===1&&/Cowboy/.test(n)?label('角色、敌人与动物','火车事件敌人',n,'目录确认'):label('建筑与场景组合','火车与战场组合',n,'目录确认');
 if(p.startsWith('Workspace.Prefabs.老矿镇.'))return label('建筑与场景组合','老矿镇',n,'目录确认');
 const mapMatch=p.match(/^Workspace\.Prefabs\.(Map|沼泽Map|雪原Map)\.([^.]*)/);
 if(mapMatch){const section=mapMatch[2];
  if(['地块','雪块','树','石头','矿脉','装饰','边缘装饰'].includes(section))return label('地形与植被',/草/.test(n)?'草':/灌木/.test(n)?'灌木':/土地/.test(n)?'地表装饰':section,n,'目录确认',`原目录：${section}`);
  if(section==='雪山'){
   if(/草|雪$/.test(n))return label('地形与植被',/草/.test(n)?'草':'雪山地形部件',n,'名称推断','原目录：雪原Map/雪山');
   if(/控制器|触发/.test(n))return label('机关、特效与界面','雪山控制载体',n,'名称推断');
  }
  if(section==='营火'||section==='制造台')return label('营地与建造设施',section,n,'目录确认');
  if(['保险柜','宝箱','陷阱'].includes(section))return label('机关、特效与界面',section,n,'目录确认');
  if(section==='区域格挡空气墙'||section==='房子尺寸样板')return label('辅助与空对象',section==='房子尺寸样板'?'建筑尺寸样板':'区域边界',n,'目录确认');
  if(section==='MapMarker')return label('机关、特效与界面','地图标记',n,'目录确认');
  if(section==='WantedBoard')return label('营地与建造设施','悬赏牌',n,'目录确认');
  if(section==='Model')return label('待辨认素材','地图未命名组合',n,'待核实');
  return label('建筑与场景组合',section,n,'目录确认');
 }
 if(p.startsWith('Workspace.Prefabs.其他.'))return label('机关、特效与界面','交互或显示载体',n,'目录确认');
 if(p==='Workspace.Prefabs.Effects')return label('机关、特效与界面','特效集合',n,'名称推断');
 if(p==='Workspace.Prefabs.IndiaPosition'||p==='Workspace.Prefabs.IndiaBack')return label('辅助与空对象','定位挂点',n,'名称推断');
 if(p==='Workspace.Prefabs.Trader')return label('角色、敌人与动物','商人NPC',n,'名称推断');
 if(p==='Workspace.Prefabs.ladder')return label('营地与建造设施','梯子',n,'名称推断');
 if(p==='Workspace.Prefabs.双开门')return label('建筑与场景组合','门部件',n,'名称推断');
 if(p==='Workspace.CamSetting')return label('建筑与场景组合','复合场景容器',n,'结构确认',`包含 ${r.parts} 个 BasePart、${r.humanoids} 个 Humanoid，暂不拆分为独立资产；实际用途待核实`);
 if(p.startsWith('Workspace.GemPack.'))return label('资源、食物与消耗品','宝石展示或礼包组合',n,'目录确认','具体用途待核实');
 if(p.startsWith('Workspace.BagStore.'))return label('辅助与空对象','袋子存储容器内对象',n,'目录确认','运行状态与编辑样本关系待核实');
 if(r.rawNameHex)return label('待辨认素材','名称编码异常',n,'待核实','原始名称无法按 UTF-8 序列化；原始字节已保留');
 if(r.class==='Accessory')return label('服饰、护具与皮肤','散放配饰',n,'结构确认','具体职业或佩戴部位未确认');
 if(r.humanoids>0){
  if(['Model','Rig','形象','God'].includes(n))return label('角色、敌人与动物','待辨认角色或Rig',n,'结构确认','检测到 Humanoid，具体角色用途待核实');
  return label('角色、敌人与动物',/Cowboy|Zombie|山羊人|野猪人|猪侄子/.test(n)?'散放敌人或怪物':/Trader/.test(n)?'散放NPC':/马|鹿|Moose|Goat|Lion|Bear|Turkey|Wolf|Buffalo|猪|鱿鱼/.test(n)?'散放生物':'散放角色',n,'名称推断','结构含 Humanoid；不等同于正在启用的预设');
 }
 if(/雪覆盖|雪块|地块/.test(n))return label('地形与植被',/雪覆盖/.test(n)?'积雪覆盖件':'地块样本',n,'名称推断');
 if(/^草\d*$|Tree|树|Cloud/.test(n))return label('地形与植被',/Cloud/.test(n)?'云':/Tree|树/.test(n)?'树':'草',n,'名称推断');
 if(/酿酒配件|管道/.test(n))return label('建筑与场景组合','工坊管道或机械零件',n,'名称推断');
 if(/1x1,|墓地|洞口|衣柜|遮雨棚|铁轨|节日方旗|Light belt|Rocking chair|SaloonDoor/.test(n))return label('建筑与场景组合',/铁轨/.test(n)?'铁路部件':/1x1,|墓地|洞口/.test(n)?'建筑或场景组合':/衣柜|chair/.test(n)?'家具':'场景部件',n,'名称推断');
 if(/Watermelon|Potato|Onion|Carrot|Pumpkin|Chilli Pepper|Meat|SM_Prop_(Tomato|Beetroot|Pepper)/i.test(n))return label('资源、食物与消耗品','食物模型样本',n,'名称推断','仅按模型名称分类，不据此认定为可食用物品');
 if(/Fedora|Pilgrim Hat|Beret|Skull Hat/.test(n))return label('服饰、护具与皮肤','头饰模型样本',n,'名称推断');
 if(/Sword|Blade|Knight|Lancer|Hunter|Shadow|Stick|axe|Revolver|gun|Minigun|Flamethrower|Tommy|鹿角回力镖|Pan|子弹盒/i.test(n))return label('武器与交互工具',/子弹盒/.test(n)?'弹药盒样本':/Pan/.test(n)?'淘金盘样本':'武器或工具样本',n,'名称推断');
 if(/Trap|Spikes/.test(n))return label('营地与建造设施','陷阱或拒马样本',n,'名称推断');
 const children=r.children.join(' ');
 if(/水枪|蒸汽枪/.test(children))return label('武器与交互工具','未命名枪械组装件',/蒸汽枪/.test(children)?'蒸汽长枪组装件（待核实）':'水枪组装件（待核实）','名称推断','依据子对象名称；原对象仍名为 Model');
 if(/酿酒配件/.test(children))return label('建筑与场景组合','未命名工坊组装件','酿酒配件组合（待核实）','名称推断','依据子对象名称');
 if(/淘金屋子/.test(children))return label('建筑与场景组合','未命名建筑组合','淘金屋组合（待核实）','名称推断','依据子对象名称');
 if(/Rear Bolster Wood|Rear Axel|Outer Wheel/.test(children))return label('建筑与场景组合','未命名车辆组装件','马车组装件（待核实）','名称推断','依据子对象名称');
 if(/^\d+$/.test(n))return label('待辨认素材','数字名称命名空间待定',n,'待核实','不能仅凭数字同时套用物品、设施或职业配置');
 return label('待辨认素材',r.class==='Model'?'未命名或未识别组合体':'散放零件',n,'待核实',r.parts>=100?'大型组合体；需要后续单独拆解':'仅凭名称与结构无法确定用途');
}
function theme(r){const s=r.path+' '+r.name;if(/圣诞|Christmas|Santa|Jingle|Snowy/.test(s))return '圣诞';if(/万圣|Pumpkin|Candy/.test(s))return '万圣节或南瓜';if(/雪原|Snow|Ice|Glacial/.test(s))return '雪原或冰系';if(/沼泽|Marsh|Swamp|Toxic/.test(s))return '沼泽或毒系';if(/火车|老矿镇/.test(s))return '铁路或矿镇';return '未指定';}
const rows=raw.map(r=>({...r,...classify(r),id:`AF-${String(r.index).padStart(4,'0')}`,source:r.path.startsWith('Workspace.Prefabs.')?'预设库':'散放与其他容器',theme:theme(r)}));
const geometry=new Map();
for(const r of rows.filter(r=>r.source==='预设库'&&r.parts>0&&r.basis!=='待核实')){const a=geometry.get(r.geometry)??[];a.push(r);geometry.set(r.geometry,a);}
for(const r of rows.filter(r=>r.source!=='预设库'&&r.meshes>0&&r.basis==='待核实'&&!r.rawNameHex)){
 const matches=geometry.get(r.geometry)??[];
 if(matches.length){r.geometryCandidates=matches.map(x=>x.id);r.notes+=`；几何特征候选：${matches.map(x=>`${x.id} ${x.display}`).join('、')}。仅比较零件类型、尺寸和 MeshId，尚未核对布局、颜色、贴图与逻辑。`;}
}
const esc=v=>String(v??'').replaceAll('|','\\|').replace(/\r?\n/g,' ').replace(/\s+/g,' ').trim();
const code=v=>'`'+esc(v).replaceAll('`','ˋ')+'`';
const table=(heads,data)=>'| '+heads.map(esc).join(' | ')+' |\n| '+heads.map(()=>'---').join(' | ')+' |\n'+data.map(row=>'| '+row.map(esc).join(' | ')+' |').join('\n')+'\n';
const countBy=(arr,key)=>Object.entries(arr.reduce((a,r)=>{a[r[key]]=(a[r[key]]??0)+1;return a;},{}));
const positions=r=>r.position?r.position.map(v=>Math.round(v)).join(', '):'未取到';
const group=fn=>{const out=new Map();for(const r of rows){const k=fn(r);const a=out.get(k)??[];a.push(r);out.set(k,a);}return out;};
const pathGroups=group(r=>r.path);
const duplicates=[...pathGroups.entries()].filter(([,v])=>v.length>1);
const noParts=rows.filter(r=>r.parts===0),unknown=rows.filter(r=>r.category==='待辨认素材');
const pending=rows.filter(r=>r.basis==='待核实'||/待核实|待辨认|未映射|未确认/.test(r.notes+' '+r.subcategory+' '+r.display));
const caveat='本清单是编辑态对象快照。预设目录中的存在不代表已被运行逻辑启用。条目以穿过 Folder 后遇到的首个 Model、Tool、Accessory 或 BasePart 为单位，其内部子模型与零件不再重复建行。';
const header=`# After Fall 局内建模素材分类清单\n\n取证日期：2026-11-18（Asia/Shanghai）。Place：${meta.placeId}。编辑态版本：${meta.version}。\n\n`;
let main=header+`本轮先审查文字分类。共登记 **${rows.length} 个候选条目**，其中预设库 **${rows.filter(r=>r.source==='预设库').length}** 条、散放与其他容器 **${rows.filter(r=>r.source!=='预设库').length}** 条。没有复制、移动、改名或修改 Studio 对象，也没有为本清单拍摄素材图。\n\n${caveat}\n\n905 是候选条目数，不是去重后的模型种类数；其中包含零件、复合场景容器和 ${noParts.length} 个未含 BasePart 的对象。\n\n`;
main+='## 分类总览\n\n用途作为一级分类，主题与存放位置分别记录，避免把“雪原”“圣诞”等主题与“建筑”“武器”等用途混在同一级。\n\n';
main+=table(['一级分类','预设库','散放及其他','合计','代表条目'],categories.map(cat=>{const a=rows.filter(r=>r.category===cat);return [cat,a.filter(r=>r.source==='预设库').length,a.filter(r=>r.source!=='预设库').length,a.length,[...new Set(a.map(r=>r.display))].slice(0,4).join('、')];}));
main+=`\n其中 ${unknown.length} 条未能确定用途，放在“待辨认素材”。另有已经分入大类、但具体身份或用途仍不明确的条目；合计 ${pending.length} 条在名称、子类或备注中标记待核实、待辨认、未映射或未确认。这不是外观核验完成度。\n`;
main+='\n## 分类依据\n\n'+table(['标记','含义'],[['配置确认','目录命名空间与配置 ID 或名称相符。识别物品/设施身份，不保证该预设当前被调用。'],['目录确认','依据现有 Prefabs 目录或专用容器分类，未逐一核实运行消费方。'],['结构确认','根据 Humanoid、Accessory、BasePart 或空对象结构判定。不能仅凭结构断定具体用途。'],['名称推断','依据自身或子对象名称推断用途，留待人工审查。'],['待核实','名称、目录或结构不足以确认。保留原名和定位，不强行填入具体资产名称。']] );
main+='\n## 主题线索\n\n主题线索只取目录或名称中的明确关键词，例如圣诞、雪原、毒系。它不表示资产只会在该地区或活动中使用，未逐个核实美术风格。\n\n'+table(['主题线索','条目数'],countBy(rows,'theme'));
main+='\n## 细分类目\n\n';
for(const cat of categories){const a=rows.filter(r=>r.category===cat);main+=`### ${cat}\n\n`;const subs=[...new Set(a.map(r=>r.subcategory))];main+=table(['子类','条目数','示例'],subs.map(sub=>{const b=a.filter(r=>r.subcategory===sub);return [sub,b.length,[...new Set(b.map(r=>r.display))].slice(0,5).join('、')];}));main+='\n';}
main+='## 优先审查项\n\n';
const focus=[
 ['待辨认素材',`${unknown.length} 条`, '未命名组合、数字命名空间不明、散放零件和未映射物品。见散放明细和预设库的“待辨认素材”。'],
 ['名称相同、路径相同',`${duplicates.length} 组，共 ${duplicates.reduce((s,[,a])=>s+a.length,0)} 条`, '同一父级存在同名兄弟，单靠点路径不能唯一定位。用 AF 编号配合 W/... 快照序号、位置区分。'],
 ['未含 BasePart 的对象',`${noParts.length} 条`, '既有空壳，也有带后代的容器；没有把这些对象算成可见模型。'],
 ['数字 ID 重叠','示例 101、206、301、401、502', '物品、设施和职业使用不同配置命名空间。例如 Resources/502 是 Rifle Bullet，蓝图/502 是 Time machine。散放数字对象不直接套表。'],
 ['名称编码异常','AF-0744', 'Workspace 根级 W/112 的 Model 名称含无效 UTF-8 字节，普通 JSON 层级导出会失败。本轮用占位名称登记，原始字节保存在取证数据中。'],
 ['复合场景容器','AF-0899 CamSetting', '该对象含 2,497 个 BasePart 和 13 个 Humanoid，按一个组合容器登记。仅凭名称不能认定为纯相机辅助对象，内部尚未拆成独立条目。'],
 ['暂存、废弃或隐藏项',`${rows.filter(r=>/暂存|废弃/.test(r.path)).length} 条名称带暂存或废弃`, '保留在清单并标注目录；没有据此断定可删除或未启用。']
];main+=table(['事项','范围','说明'],focus);
main+='\n## 散放数字对象的几何候选\n\n这些仅用于辅助下一轮辨认，不计入配置确认。几何特征相同仍可能有不同颜色、贴图、摆放、属性或脚本。\n\n';
main+=table(['条目','原名','候选预设','当前处理'],rows.filter(r=>r.geometryCandidates).map(r=>[r.id,r.name,r.geometryCandidates.map(id=>{const x=rows.find(a=>a.id===id);return `${id} ${x.display}`;}).join('；'),'保留原分类，待核实']));
main+='\n## 原目录覆盖\n\n'+table(['来源目录','候选条目数'],[...group(r=>r.source==='预设库'?r.path.split('.').slice(0,3).join('.'):r.parent==='Workspace'?'Workspace（根级散放）':r.path.split('.').slice(0,2).join('.')).entries()].map(([k,v])=>[code(k),v.length]));
main+='\n## 明细入口与定位方法\n\n- [预设库明细](output/局内素材分类/01_预设库明细.md)：601 条，含配置补名与原始目录。\n- [散放素材明细](output/局内素材分类/02_散放素材明细.md)：304 条，含位置、待核实说明和几何候选。\n- [目录与定位索引](output/局内素材分类/03_目录与定位索引.md)：文件夹覆盖、空目录及同路径对象。\n\nAF-xxxx 是本次扫描编号。W/112 表示 Workspace:GetChildren() 本次快照中的第 112 个子对象，后续数字依次表示子级序号；调整工程层级后序号可能变化。位置为包围盒中心或 Handle 中心，单位 studs，显示到整数。原名空白已在表格中压缩，取证 JSON 保留原始值。\n\n数据来源：Studio Edit DataModel 的对象层级、名称、后代类型、几何尺寸、MeshId、属性与标签；数字身份关联 ReplicatedStorage.src.ExcelConfig 下的 ResourcesItemSetting、CraftItemSetting、CharaterSetting、EnemySetting。未进行截图辨认、运行试玩、引用关系全量审计或资产去重。\n';
await fs.writeFile(path.join(cwd,'局内建模素材分类清单.md'),main,'utf8');
for(const [source,file,title] of [['预设库','01_预设库明细.md','预设库明细'],['散放与其他容器','02_散放素材明细.md','散放素材明细']]){
 const list=rows.filter(r=>r.source===source);let md=`# ${title}\n\n[返回分类总览](../../局内建模素材分类清单.md)\n\n2026-11-18，Place ${meta.placeId}，编辑态版本 ${meta.version}。本表 ${list.length} 条。零件数按 BasePart 计，脚本数包括 Script、LocalScript 和 ModuleScript。\n\n${caveat}\n\n`;
 for(const cat of categories){const group=list.filter(r=>r.category===cat);if(!group.length)continue;md+=`## ${cat}（${group.length} 条）\n\n`;
  if(source==='预设库')md+=table(['编号','子类','识别名称','原名','主题线索','零件','脚本','依据','对象路径与快照序号','备注'],group.map(r=>[r.id,r.subcategory,r.display,r.name,r.theme,r.parts,r.scripts,r.basis,code(r.path)+' · '+code(r.locator),r.notes]));
  else md+=table(['编号','子类','识别名称 / 原名','主题线索','零件','脚本','位置 X,Y,Z','依据','对象路径与快照序号','备注'],group.map(r=>[r.id,r.subcategory,esc(r.display)===esc(r.name)?r.name:`${r.display} / ${r.name}`,r.theme,r.parts,r.scripts,positions(r),r.basis,code(r.path)+' · '+code(r.locator),r.notes]));
  md+='\n';
 }
 await fs.writeFile(path.join(dest,file),md,'utf8');
}
let index=`# 目录与定位索引\n\n[返回分类总览](../../局内建模素材分类清单.md)\n\n## 文件夹覆盖\n\n共 ${meta.folders.length} 个 Folder。直接子对象数包含脚本、子文件夹和非建模对象，不能直接与资产候选条目数相加。\n\n`;
index+=table(['目录','快照序号','直接子对象数','递归候选条目数'],meta.folders.map(f=>[code(f.path),code(f.locator),f.children,rows.filter(r=>r.locator.startsWith(f.locator+'/')).length]));
index+='\n## 同一路径的多个对象\n\n以下是同名兄弟对象，不代表几何相同或可以合并。\n\n'+table(['对象路径','条目数','编号与位置'],duplicates.map(([p,a])=>[code(p),a.length,a.map(r=>`${r.id} ${code(r.locator)} (${positions(r)})`).join('；')]));
index+='\n## 无几何对象\n\n'+table(['编号','原名','后代数','类型','定位'],noParts.map(r=>[r.id,r.name,r.descendants,r.subcategory,code(r.path)+' · '+code(r.locator)]));
index+='\n## 名称编码异常\n\n'+table(['编号','快照序号','原始名称字节（十六进制）'],rows.filter(r=>r.rawNameHex).map(r=>[r.id,code(r.locator),code(r.rawNameHex)]));
await fs.writeFile(path.join(dest,'03_目录与定位索引.md'),index,'utf8');
await fs.writeFile(path.join(evidence,'catalog_classified.json'),JSON.stringify(rows,null,2),'utf8');
const report={total:rows.length,prefabs:rows.filter(r=>r.source==='预设库').length,loose:rows.filter(r=>r.source!=='预设库').length,folders:meta.folders.length,noParts:noParts.length,unknown:unknown.length,pending:pending.length,duplicatePathGroups:duplicates.length,invalidNames:rows.filter(r=>r.rawNameHex).length,categories:categories.map(category=>({category,count:rows.filter(r=>r.category===category).length})),basis:countBy(rows,'basis'),outputs:['局内建模素材分类清单.md',...['01_预设库明细.md','02_散放素材明细.md','03_目录与定位索引.md'].map(f=>'output/局内素材分类/'+f)]};
await fs.writeFile(path.join(evidence,'validation.json'),JSON.stringify(report,null,2),'utf8');
console.log(JSON.stringify(report,null,2));
