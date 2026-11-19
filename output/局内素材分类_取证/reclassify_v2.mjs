import fs from 'node:fs/promises';
import path from 'node:path';
const cwd=process.cwd(),base=path.join(cwd,'output','局内素材分类'),evidence=path.join(cwd,'output','局内素材分类_取证');
const old=JSON.parse(await fs.readFile(path.join(evidence,'catalog_classified.json'),'utf8'));
const reviewed=JSON.parse(await fs.readFile(path.join(evidence,'reviewed_role_overrides.json'),'utf8'));
const overrides=new Map(reviewed.map(r=>[r.id,r]));
if(overrides.size!==reviewed.length||reviewed.some(r=>!old.some(x=>x.id===r.id)))throw new Error('Invalid reviewed override IDs');
const runs=await Promise.all([1,2,3,4,5].map(async n=>({n,...JSON.parse(await fs.readFile(path.join(cwd,'output','地图来源验证',`run_${n}_complete.json`),'utf8'))})));
const roles=['地图生成模板','实体与物品模板','直接使用的玩法场景','过场与演出场景','系统辅助与表现对象','已确认的开发测试与展示素材','用途待确认'];
const definitions=[
 '供地图系统克隆、组合或放置，构成地形、建筑和地图内容。',
 '供战斗、掉落、制作、职业或外观系统创建的实体、物品与设施模板。',
 '已有实例被玩法脚本直接引用、定位、移动或激活。',
 '服务于镜头、剧情及演出，不作为普通地图生成模板。',
 '承担交互、边界、定位、界面或特效功能的对象。',
 '明确的测试入口、尺寸样板或动画保存对象指针确认开发制作用途。',
 '目前证据不足以判断程序使用方式；不等于未使用或可删除。'
];
const usage=new Map(),retained=new Map();
for(const run of runs){
 const ids=new Set([run.map,...run.runtimeRoots.map(x=>x.summary)].flatMap(s=>Object.keys(s.sources)).filter(x=>x.startsWith('P:')).map(x=>x.slice(2)));
 for(const id of ids){const a=usage.get(id)??[];a.push(run.n);usage.set(id,a);}
 for(const id of new Set(run.retainedLoose.map(x=>x.origin.slice(2)))){const a=retained.get(id)??[];a.push(run.n);retained.set(id,a);}
}
function classify(r){
 const reviewed=overrides.get(r.id);
 if(reviewed)return [reviewed.role,reviewed.basis,reviewed.entry,reviewed.note];
 const p=r.path,n=r.name,hasPrefab=r.source==='预设库';
 if(r.id==='AF-0603')return [roles[2],'脚本与实测确认','ServerScriptService.Game.沼泽:initBossEntrance（386–391 行）','原场景 PivotTo 到随机入口对应的地下战场位置。'];
 if(r.id==='AF-0899')return [roles[3],'脚本与实测确认','StarterGui.FilmMode.LocalScript（51、67–77、85–86 行）','镜头脚本直接读取、引用并移动场景；包含演出角色和布景。'];
 if(/房子尺寸样板/.test(p))return [roles[5],'目录确认','Prefabs.Map.房子尺寸样板','建筑占地尺寸样板，未将其视为已进入正式玩法。'];
 if((r.scriptNames??[]).some(n=>/动画测试|跟随测试|测试脚本|TestScript/.test(n)))return [roles[5],'内嵌脚本名称确认',(r.scriptNames??[]).filter(n=>/测试|TestScript/.test(n)).join('、'),'确认包含开发测试入口；不据此断定该模型只能用于测试。'];
 if(r.class==='Terrain'||r.class==='SpawnLocation'||n==='Baseplate')return [roles[4],'结构确认',r.class==='SpawnLocation'?'Workspace.SpawnLocation':r.class,'系统场景对象；不是模板调用证据。'];
 if(!hasPrefab)return [roles[6],'用途未确认','尚未核实正式调用入口',r.parts===0?'没有 BasePart，不能据此断定无用途。':'位置、名称、几何候选和运行态保留均不能单独证明正式用途。'];
 if(r.parts===0)return [roles[6],'用途未确认','尚未核实调用入口','未含 BasePart 的对象单独保留，不强行认定为系统辅助。'];
 if(r.category==='待辨认素材')return [roles[6],'用途未确认','所在目录不足以确认身份',r.notes];
 if(p.startsWith('Workspace.Prefabs.UI.')||p==='Workspace.Prefabs.Effects'||p.startsWith('Workspace.Prefabs.其他.')||p==='Workspace.Prefabs.IndiaPosition'||p==='Workspace.Prefabs.IndiaBack'||r.subcategory==='区域边界'||r.subcategory==='地图标记'||r.subcategory==='雪山控制载体'||r.subcategory==='NPC事件定位对象')return [roles[4],r.basis==='名称推断'?'名称推断':'目录或结构确认','相关界面、交互、定位或特效入口尚未逐项审计',r.notes];
 if(p.startsWith('Workspace.Prefabs.NPC事件.')&&r.category==='角色、敌人与动物')return [roles[1],'目录推断','ServerScriptService.Game.NPC事件','属于开局 NPC 事件资源包；具体实体身份沿用初版识别。'];
 if(/^Workspace\.Prefabs\.(Map|沼泽Map|雪原Map|老矿镇|火车大劫案|NPC事件)\./.test(p)||(/^Workspace\.Prefabs\.(圣诞节|万圣节)\./.test(p)&&r.class!=='Accessory'))return [roles[0],'目录推断','MapService / MapHelper / 对应地区或事件生成服务',r.notes];
 if(/^Workspace\.Prefabs\.(Resources|蓝图|敌人|动物|伙伴|巨型怪物|马匹|皮肤|CharacterHat|CharacterAccessory)\./.test(p)||r.class==='Accessory'||p==='Workspace.Prefabs.Trader'||p==='Workspace.Prefabs.ladder')return [roles[1],r.basis==='配置确认'?'配置身份确认，调用方式推断':'目录推断','对应实体、物品、建造或角色外观服务；未逐项追踪',r.notes];
 if(r.category==='机关、特效与界面')return [roles[4],'目录或名称推断','相关表现或交互服务；未逐项追踪',r.notes];
 if(r.category==='建筑与场景组合')return [roles[0],'目录或名称推断','地图或场景构建入口；未逐项追踪',r.notes];
 return [roles[6],'用途未确认','尚未核实调用入口',r.notes];
}
function type(r){
 if(overrides.get(r.id)?.materialType)return overrides.get(r.id).materialType;
 if(r.id==='AF-0603'||r.id==='AF-0899')return '建筑场景';
 if(r.category==='地形与植被')return '地形植被';
 if(r.category==='建筑与场景组合')return '建筑场景';
 if(r.category==='营地与建造设施')return '营地设施';
 if(r.category==='资源、食物与消耗品')return '资源与食物';
 if(r.category==='武器与交互工具')return '武器工具';
 if(r.category==='服饰、护具与皮肤')return '服饰护具';
 if(r.category==='机关、特效与界面')return /界面|特效|显示/.test(r.subcategory)?'特效与界面':'机关';
 if(r.category==='角色、敌人与动物')return /大型怪物|山羊人|野猪人|猪侄子|Zombie|僵尸|幽灵/.test(r.subcategory+' '+r.name)?'怪物与Boss':/动物|马匹|驯鹿|生物|伙伴/.test(r.subcategory)?'动物与坐骑':'人形角色';
 if(r.category==='辅助与空对象'&&r.parts>0)return '辅助零件';
 return '类型待确认';
}
const rows=old.map(r=>{const [role,basis,entry,note]=classify(r);const hits=usage.get(r.id)??[],kept=retained.get(r.id)??[];let evidence=basis;
 if(r.source==='预设库'&&hits.length)evidence+=`；运行态生成来源命中 ${hits.length}/5 轮`;
 if(r.source!=='预设库'&&kept.length)evidence+=`；运行态保留 ${kept.length}/5 轮`;
 const notes=r.id==='AF-0899'?'包含 2,497 个 BasePart、13 个 Humanoid；内部演出子场景尚未逐个拆分。':r.notes;
 return {...r,notes,role,materialType:type(r),roleBasis:evidence,entry,roleNote:note,observedGenerationRuns:hits,retainedRuns:kept};});
if(rows.length!==905||new Set(rows.map(x=>x.id)).size!==905)throw new Error('Inventory missing or duplicated');
const esc=v=>String(v??'').replaceAll('|','\\|').replace(/\r?\n/g,' ').replace(/\s+/g,' ').trim();
const code=v=>'`'+esc(v).replaceAll('`','ˋ')+'`';
const table=(h,rs)=>'| '+h.join(' | ')+' |\n| '+h.map(()=>'---').join(' | ')+' |\n'+rs.map(r=>'| '+r.map(esc).join(' | ')+' |').join('\n')+'\n';
const sourceText=r=>r.source==='预设库'?'Prefabs 内':'Prefabs 外';
const knownUsage=rows.filter(r=>r.role===roles[6]);
let main='# After Fall 局内建模素材分类清单\n\n第二版：按程序使用方式分类。整理日期：2026-11-18（Asia/Shanghai）。依据编辑态版本 60 的 905 条素材快照及 5 次运行验证。\n\n';
main+='一级分类改为程序使用方式，二级分类描述素材类型。`Prefabs 内/外` 仅作为原始位置字段。**目录推断、已确认身份、实测来源命中和运行态保留分别标注，不能互相替代。**\n\n';
main+=table(['一级分类','条目数','定义','示例'],roles.map((role,i)=>{const list=rows.filter(r=>r.role===role);return [role,list.length,definitions[i],[...new Set(list.map(r=>r.display))].slice(0,4).join('、')];}));
main+=`\n合计 **905 条**，编号沿用 AF-0001 至 AF-0905。${knownUsage.length} 条仍为“用途待确认”；已有的名称或素材类型识别不会因此丢失。\n\n`;
main+='## 审查入口\n\n- [按程序用途分类的完整明细](output/局内素材分类/00_按程序用途分类明细.md)：905 条，按上述七类排列。\n- [地图素材来源验证](局内地图素材来源验证.md)：五轮结果、库外正式场景的脚本证据及测试范围。\n- [目录与定位索引](output/局内素材分类/03_目录与定位索引.md)：处理同名对象、无几何对象及定位问题。\n\n原位置视图仍保留，内容已同步为第二版：\n\n- [Prefabs 内条目](output/局内素材分类/01_预设库明细.md)：601 条，仅按原始位置筛选。\n- [Prefabs 外条目](output/局内素材分类/02_散放素材明细.md)：304 条，包含正式玩法场景、过场场景及未确认素材。\n\n';
main+='## 已确认的重要修正\n\n'+table(['编号','原对象','新一级分类','素材类型','依据'],[['AF-0603','Workspace.沼泽.野猪王战场',roles[2],'建筑场景','沼泽脚本直接移动原场景，5/5 轮保留 142 个来源部件。'],['AF-0899','Workspace.CamSetting',roles[3],'建筑场景','镜头脚本直接读取和移动，5/5 轮运行态保留。']]);
main+='\n2026-11-18 引用审计复核：从原 312 条待确认中归类 9 条，现剩 **303 条**。3 条归入系统辅助与表现对象，6 条归入开发测试与展示素材（动画制作）。AF-0773 Meat 的精确读取没有后续消费，仍待确认。[查看逐项调整依据](资产引用复核与分类调整.md)。\n';
main+='\n## 分类与证据的读法\n\n- 地图模板和实体物品模板中，有些只确认了目录或配置身份，尚未逐一追踪调用入口。明细会注明“推断”。\n- “运行态生成来源命中”表示部件的来源标记在地图或其他运行容器中被观察到；未命中不代表不会使用。\n- “运行态保留”仅表示对象仍存在，不证明其玩法已触发或玩家视角可见。\n- “已确认的开发测试与展示素材”包含尺寸样板、测试脚本及动画保存记录精确关联的制作模型，普通 Rig、Model、Part 不会仅凭名称被判为测试或废弃。制作模型也可能有正式用途。\n- 每条记录使用一个主要类别，其他用途写入备注；不重复增加资产行。\n\n';
const types=[...new Set(rows.map(r=>r.materialType))];main+='## 素材类型\n\n'+table(['素材类型','条目数'],types.map(t=>[t,rows.filter(r=>r.materialType===t).length]));
main+='\n## 快照口径\n\n本表不是去重后的模型种类数。穿过 Folder 后遇到的首个 Model、Tool、Accessory 或 BasePart 作为一条候选对象；其内部子模型与零件不重复建行。AF 编号保持不变。W/... 是当时 GetChildren 的层级序号，工程结构改变后可能变化。\n\n本次整理未新增 Studio 操作或截图。已有运行验证的临时标记与观察器已清除。\n';
await fs.writeFile(path.join(cwd,'局内建模素材分类清单.md'),main,'utf8');
const views=[['00_按程序用途分类明细.md','按程序用途分类的完整明细',rows],['01_预设库明细.md','Prefabs 内条目（位置筛选）',rows.filter(r=>r.source==='预设库')],['02_散放素材明细.md','Prefabs 外条目（位置筛选）',rows.filter(r=>r.source!=='预设库')]];
for(const [file,title,list] of views){let md=`# ${title}\n\n第二版，2026-11-18。共 ${list.length} 条。[返回分类总览](../../局内建模素材分类清单.md)。\n\n一级分类按程序使用方式；位置字段不表示正式或非正式。“运行态保留”与“生成来源命中”分开标注。\n\n`;
 for(const role of roles){const group=list.filter(r=>r.role===role);if(!group.length)continue;md+=`## ${role}（${group.length} 条）\n\n`;
 md+=table(['编号','识别名称 / 原名','素材类型','原始位置','使用脚本或入口','确认依据','待核实事项与备注','定位'],group.map(r=>[r.id,esc(r.display)===esc(r.name)?r.display:`${r.display} / ${r.name}`,r.materialType,sourceText(r),r.entry,r.roleBasis,[r.roleNote,r.notes!==r.roleNote?r.notes:''].filter(Boolean).join('；'),code(r.path)+' · '+code(r.locator)]));md+='\n';}
 await fs.writeFile(path.join(base,file),md,'utf8');
}
await fs.writeFile(path.join(evidence,'catalog_classified_v2.json'),JSON.stringify(rows,null,2),'utf8');
const report={total:rows.length,roles:roles.map(role=>({role,count:rows.filter(r=>r.role===role).length})),sourceCounts:{prefabs:601,outside:304},outputs:['局内建模素材分类清单.md',...views.map(x=>'output/局内素材分类/'+x[0])]};
for(const file of report.outputs){const text=await fs.readFile(path.join(cwd,file),'utf8');for(const m of text.matchAll(/\]\(([^)]+)\)/g))await fs.access(path.resolve(path.dirname(path.join(cwd,file)),m[1]));for(const block of text.split(/\n\s*\n/)){const lines=block.split('\n').filter(l=>l.startsWith('| '));if(lines.length>1){const n=lines[0].split(/(?<!\\)\|/).length;for(const l of lines)if(l.split(/(?<!\\)\|/).length!==n)throw new Error('Malformed table: '+file);}}}
const detail=await fs.readFile(path.join(base,views[0][0]),'utf8');const ids=[...detail.matchAll(/^\| (AF-\d{4}) \|/gm)].map(x=>x[1]);if(ids.length!==905||new Set(ids).size!==905)throw new Error('Detailed inventory mismatch');
await fs.writeFile(path.join(evidence,'validation_v2.json'),JSON.stringify(report,null,2),'utf8');console.log(JSON.stringify(report,null,2));
