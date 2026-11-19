import fs from 'node:fs/promises';
import path from 'node:path';
const cwd=process.cwd(),dir=path.join(cwd,'output','地图来源验证');
const runs=await Promise.all([1,2,3,4,5].map(async n=>({run:n,...JSON.parse(await fs.readFile(path.join(dir,`run_${n}_complete.json`),'utf8'))})));
const cleanup=JSON.parse(await fs.readFile(path.join(dir,'cleanup.json'),'utf8'));
const env=JSON.parse(await fs.readFile(path.join(dir,'environment.json'),'utf8'));
const catalog=JSON.parse(await fs.readFile(path.join(cwd,'output','局内素材分类_取证','catalog_classified.json'),'utf8'));
const byId=new Map(catalog.map(r=>[r.id,r]));
for(const r of runs){if(!r.ready||r.map.parts!==r.map.prefabParts+r.map.looseParts+r.map.externalParts+r.map.unmarkedParts)throw new Error('Invalid completed run '+r.run);if(r.map.looseParts!==0||r.map.externalParts!==0||r.map.unmarkedParts!==1)throw new Error('Unexpected map-source result '+r.run);}
if(new Set(runs.map(r=>r.map.signature)).size!==5)throw new Error('Repeated layout signatures');
if(cleanup.remaining!==0||cleanup.observerRemaining)throw new Error('Cleanup incomplete');
const esc=v=>String(v??'').replaceAll('|','\\|').replace(/\r?\n/g,' ');
const table=(h,rs)=>'| '+h.join(' | ')+' |\n| '+h.map(()=>'---').join(' | ')+' |\n'+rs.map(r=>'| '+r.map(esc).join(' | ')+' |').join('\n')+'\n';
const generatedRootNames=['沼泽','雪原','齿轮资源点','神枪手据点','医院','随机事件','边界','空气墙','火车大劫案'];
const mapSources=new Set(runs.flatMap(r=>Object.keys(r.map.sources)));
const allSources=new Set(runs.flatMap(r=>[r.map,...r.runtimeRoots.filter(x=>generatedRootNames.includes(x.name)).map(x=>x.summary)].flatMap(s=>Object.keys(s.sources))));
let md='# 局内地图素材来源验证\n\n2026-11-18（Asia/Shanghai）。After Fall，Place 108983613755535，编辑态版本 60。当前配置模式 ID 为 '+env.mode+'，沼泽、雪原、火车、武器工坊、铃铛洞穴开启；圣诞节、万圣节关闭。\n\n';
md+='## 结论\n\n**不能把“位于预设库之外”理解为“不会出现在正式运行的游戏中”。** 预设库/散放及其他容器是存放位置分类，不是运行用途分类。\n\n- 连续 5 次独立 Play 启动后，中央 `Workspace.Map` 中有来源标记的几何部件全部来自 `Workspace.Prefabs`。每轮另有 1 个脚本创建的 `CampfireTouchPart`，它不是库外美术模型。\n- 沼泽 Boss 战场是明确例外：`Workspace.沼泽.野猪王战场` 本来就在预设库之外。5 轮均保留 142 个来源部件，脚本还会把原场景移动到随机入口对应的地下位置。\n- `Workspace.CamSetting` 同样在库外。运行态保留，过场镜头脚本直接访问并移动该场景。\n- “美术其他”等容器也没有在启动时整体消失。保留在 DataModel 中并不等于玩家正常视角一定看得到，更不等于已被地图生成器选用。\n\n';
md+='## 测试方法\n\n1. 在编辑态给原清单的 905 个候选对象及其几何后代加临时来源属性，区分 `P:` 预设库与 `L:` 库外对象。另标记 ServerStorage 中的 425 个 BasePart，以识别其他存储来源。\n2. 标记随 Clone 复制，也随原对象移动保留。因此能识别“克隆预设”和“直接移动现有场景”，不依赖同名或外观匹配。\n3. 每轮使用全新 Play 会话。临时普通服务器 Script 读取游戏脚本实际共享的 MapHelper 状态，等待主地图完成，再等 5 秒后开放采集。\n4. 逐个扫描 `Workspace.Map` 的 BasePart，并检查沼泽、雪原、据点、医院等附加容器；同时登记运行态仍存在的库外候选对象。\n5. 完成后停止 Play，移除临时观察器与所有来源属性，验证回到 Edit。没有修改正式脚本源码。\n\n来源粒度是原资产候选条目。统计按 BasePart 数量计，不是按 Mesh 文件数、模型种类数或生成调用次数计。\n\n';
md+='## 五轮中央地图结果\n\n'+table(['轮次','Map 几何部件','预设库来源','库外原场景来源','ServerStorage 来源','无来源标记','预设来源条目数','布局签名'],runs.map(r=>[r.run,r.map.parts,r.map.prefabParts,r.map.looseParts,r.map.externalParts,r.map.unmarkedParts,Object.keys(r.map.sources).length,r.map.signature]));
md+=`\n5 个布局签名各不相同，部件数量也有变化，证明没有把同一张完成后的地图重复计为多次生成。五轮中央地图合计观察到 ${mapSources.size} 个不同的预设来源条目。来源属性不覆盖代码新建部件；未标记项逐轮均为 \`Workspace.Map.CampfireTouchPart\`，对应营火服务用 \`Instance.new("Part")\` 创建的触碰区。\n\n`;
md+='## 库外对象与附加场景\n\n'+table(['检查对象','五轮结果','可以确认什么'],[
 ['AF-0603 / Workspace.沼泽.野猪王战场','5/5 存在；每轮 142 个库外来源 BasePart','属于正式地图附加战场，采用原对象移动；不是从 Prefabs 克隆。'],
 ['AF-0899 / Workspace.CamSetting','5/5 存在','库外过场场景仍在运行态，并有镜头脚本直接引用。'],
 ['Workspace.美术其他','5/5 保留 726 个库外来源 BasePart','该容器未整体被启动清理；不能据此认定里面每项都参与玩法。'],
 ['Workspace.GemPack','5/5 保留 9 个库外来源 BasePart','运行态保留，具体用途本轮未核实。'],
 ['Workspace.火车大劫案.CowboyGunV2','4/5 保留 12 个库外来源 BasePart','铁路生成失败时火车容器可能被删除；保留本身不证明此角色已被使用。']
 ]);
md+='\n运行态仍登记到的库外候选编号数为：'+runs.map(r=>`第 ${r.run} 轮 ${new Set(r.retainedLoose.map(x=>x.origin)).size} 个`).join('，')+'。这个数会受清理、物理掉落或容器移除影响，不能当作“正式使用的资产数”。\n\n';
md+='## 脚本证据\n\n'+table(['位置','机理','证据文件'],[
 ['ServerScriptService.MapService / MapHelper','主生成过程从 Prefabs 中查找地块、地标等来源；营火、工作台等还存在原对象改 Parent 的路径。','[MapService](output/地图来源验证/MapService.luau)、[MapHelper](output/地图来源验证/MapHelper.luau)'],
 ['ServerScriptService.Game.沼泽，第 386–391 行','从 Workspace.沼泽 找现成的野猪王战场，按入口 X/Z 和 CaveY.WildBoarCave 直接 PivotTo。','[沼泽脚本](output/地图来源验证/SwampService.luau)'],
 ['StarterGui.FilmMode.LocalScript，第 51、67–77、85–86 行','直接读取 CamSetting 的 PrimaryPart 和镜头挂点，并调用 PivotTo 恢复场景位置。','[过场脚本前 100 行](output/地图来源验证/FilmMode_excerpt.luau)'],
 ['Workspace.火车大劫案.火车大劫案_server','火车及车厢战场来自 Prefabs；该事实与火车容器中某个库外角色是否被实际调用是两回事。','[火车控制脚本](output/地图来源验证/TrainController.luau)']
 ]);
md+=`\n第五轮中，野猪王战场位置为 \`${env.battle.position}\`，来源为 \`${env.battle.origin}\`。其 Y=-150 对应地下战场层。CamSetting 来源为 \`${env.cam.origin}\`，运行态位置为 \`${env.cam.position}\`。\n\n`;
md+='## 应怎样修正分类理解\n\n建议在“存放位置”之外，再增加“运行用途”字段：\n\n'+table(['运行用途','示例','判断依据'],[
 ['生成模板','Prefabs 中的地块、建筑、资源点','生成脚本查找或克隆；本轮来源标记命中。'],
 ['正式场景实例','野猪王战场','库外原对象被玩法脚本直接定位和移动。'],
 ['过场场景','CamSetting','被镜头脚本直接引用与移动。'],
 ['编辑展示或暂存候选','部分美术其他、未命名 Model/Part','目前只确认目录与运行态保留，不能直接判为未使用。'],
 ['辅助对象','CampfireTouchPart、空气墙根 Part','由程序创建的交互或空间控制几何。']
 ]);
md+='\n原清单中 AF-0603 应补充为“正式沼泽 Boss 战场”，AF-0899 应补充为“过场镜头场景”。“散放及其他容器”仍可保留为位置标签，但不应用作删除或排除正式资产的依据。\n\n';
md+='## 覆盖范围与限制\n\n本轮覆盖当前开关配置下的 5 次随机开局、主地图与启动附加场景。没有遍历所有随机结果、所有模式、节日开关、后续所有建筑进入、Boss 挑战或过场事件。因此“5 次未观察到某来源”不能证明它永远不会被使用。发现一个有效库外来源已足以否定“正式游戏只会使用预设库”的假设。\n\n';
md+='## 清理与复现材料\n\n'+table(['检查','结果'],[['临时来源属性清除',cleanup.removed+' 处'],['残留来源属性',cleanup.remaining],['临时观察器残留',cleanup.observerRemaining?'有':'无'],['Workspace 根级对象数',cleanup.workspaceRoots],['最终 Studio 模式','Edit']]);
md+='\nLua 脚本： [设置来源标记](output/地图来源验证/01_设置临时来源标记.luau)、[运行态就绪观察器](output/地图来源验证/03_运行态就绪观察器.luau)、[采集结果](output/地图来源验证/02_采集运行态结果.luau)、[清除标记](output/地图来源验证/04_清除临时标记.luau)。设置脚本只适用于这次 905 条对象的层级快照，运行前会检查数量。\n\n';
md+='逐轮原始结果：'+runs.map(r=>`[第 ${r.run} 轮](output/地图来源验证/run_${r.run}_complete.json)`).join('、')+'。\n';
await fs.writeFile(path.join(cwd,'局内地图素材来源验证.md'),md,'utf8');
const mainPath=path.join(cwd,'局内建模素材分类清单.md');let main=await fs.readFile(mainPath,'utf8');
const update='## 运行验证补充（2026-11-18）\n\n“预设库 / 散放及其他容器”仅表示存放位置，不能判断是否参与正式运行。5 次开局验证已确认：AF-0603 野猪王战场是库外正式战场实例，AF-0899 CamSetting 是库外过场镜头场景。中央 Workspace.Map 的素材来源均命中预设库，附加场景存在上述例外。详见[地图素材来源验证](局内地图素材来源验证.md)。下方分类表保留初版快照，以上两项以本次运行证据补充用途。\n\n';
if(!main.includes('## 运行验证补充'))main=main.replace('## 分类总览\n',update+'## 分类总览\n');await fs.writeFile(mainPath,main,'utf8');
for(const m of md.matchAll(/\]\(([^)]+)\)/g))await fs.access(path.resolve(cwd,m[1]));
const summary={runs:runs.map(r=>({run:r.run,mapParts:r.map.parts,prefabParts:r.map.prefabParts,looseParts:r.map.looseParts,unmarked:r.map.unmarkedParts,signature:r.map.signature,looseIds:new Set(r.retainedLoose.map(x=>x.origin)).size})),uniqueMainSources:mapSources.size,allGeneratedScopeSources:[...allSources],cleanup};
await fs.writeFile(path.join(dir,'summary.json'),JSON.stringify(summary,null,2),'utf8');
console.log(JSON.stringify({runs:summary.runs,uniqueMainSources:mapSources.size,cleanup,report:'局内地图素材来源验证.md'},null,2));
