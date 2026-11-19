import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const workspace=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..','..'),site=path.join(workspace,'sites','afterfall-assets');
const file=path.join(site,'dist','app.js');let source=await fs.readFile(file,'utf8');
const replace=(before,after)=>{if(!source.includes(before))throw new Error('Missing UI anchor: '+before);source=source.replace(before,after);};
if(!source.includes('function referenceCell(')){
replace("'位置','脚本或入口'","'位置','引用审计','脚本或入口'");
replace("r.source==='预设库'?'Prefabs 内':'Prefabs 外',r.entry","r.source==='预设库'?'Prefabs 内':'Prefabs 外',r.referenceAudit?.status??'未审计',r.entry");
replace('<td><span class="source-text">','<td>${referenceCell(r)}</td><td><span class="source-text">');
replace('<section class="detail-section"><h3>待核实事项与备注</h3>','${referenceDetail(row)}<section class="detail-section"><h3>待核实事项与备注</h3>');
const helpers=[
 ' function referenceCell(row){const a=row.referenceAudit;return a?`<span class="reference-badge ${escape(a.key)}">${escape(a.status)}</span>`:\'<span class="reference-badge">未审计</span>\';}',
 ' function referenceDetail(row){const a=row.referenceAudit;if(!a)return "";const counts=`精确/属性 ${a.directCount} · 目录/标签 ${a.indirectCount} · 重名或解析候选 ${a.ambiguousCount}`;return `<section class="detail-section"><h3>引用审计</h3><p>${referenceCell(row)}</p><p style="margin-top:9px">${counts}</p><p style="margin-top:6px">${a.noStaticReference?"本轮未解析到外部静态引用，不能据此认定无用。":"静态命中不保证运行执行；可包含模板内、模块内或禁用脚本的引用。"}${a.nameCandidateCount?" 同名字符串或配置名称仅作候选，不据此认定已引用。":""}</p>${a.evidence.length?`<ul class="reference-lines">${a.evidence.map(e=>`<li>${escape(e.script)}${e.line?":"+e.line:""}${e.enabled===false?"（脚本已禁用）":""}<br>${escape(e.reason)}</li>`).join("")}</ul>`:""}</section>`;}',
 ''
].join('\n');
replace(' function renderNav(){',helpers+' function renderNav(){');
await fs.writeFile(file,source,'utf8');
}
const audit=JSON.parse(await fs.readFile(path.join(workspace,'output','引用审计','reference_audit.json'),'utf8'));
const old=JSON.parse(await fs.readFile(path.join(workspace,'output','局内素材分类_取证','catalog_classified_v2.json'),'utf8'));
const counts=audit.results.reduce((a,r)=>{a[r.status]=(a[r.status]??0)+1;return a;},{}),none=audit.results.filter(r=>r.key==='none'),oldBy=new Map(old.map(r=>[r.id,r]));
const usedButMissing=none.filter(r=>{const m=oldBy.get(r.id);return m.observedGenerationRuns.length||['直接使用的玩法场景','过场与演出场景'].includes(m.role);});
let report='# 静态引用审计\n\n2026-11-18，After Fall 编辑态版本 60，905 条资产候选。\n\n';
report+='本轮只新增“引用审计”列，不把资产重新归类为未使用或废弃，也未删除、移动或改写 Studio 对象和正式脚本。\n\n';
report+=`扫描 **${audit.scriptInstances} 个脚本实例**，去重后 **${audit.uniqueSources} 份源码**；没有不可读源码。另检测到 **${audit.propertyReferences} 条跨候选对象的静态属性引用**。\n\n`;
report+='| 引用审计状态 | 条目数 | 含义 |\n| --- | --- | --- |\n';
const meaning={'检出静态引用':'解析到明确对象路径或跨对象属性指向；不保证相应代码在运行时执行。','目录/标签间接引用':'被特定目录动态查找、目录枚举或快照标签查询覆盖；不代表每项都被实际选用。','重名或解析候选':'路径同名或别名解析有歧义，暂不能精确归属。','未检出静态引用':'本轮未解析到外部路径、目录、标签或属性引用；同名字符串不算已确认引用。','匹配受限':'对象名称含无效 UTF-8 字节，常规静态匹配不完整。'};
for(const [label,count] of Object.entries(counts))report+=`| ${label} | ${count} | ${meaning[label]} |\n`;
report+=`\n本轮 ${none.length} 条“未检出静态引用”均来自 Prefabs 之外，与已有五轮测试中的生成使用证据冲突的条目数为 ${usedButMissing.length}。这只是交叉核对，不构成未使用证明。\n\n`;
report+='## 检查范围\n\n- Workspace、ServerScriptService、ReplicatedStorage、ReplicatedFirst、ServerStorage、StarterGui、StarterPlayer、StarterPack 内的 Script、LocalScript、ModuleScript，包括禁用脚本。\n- 字符串、注释与代码分词；忽略注释中的名称。\n- workspace/game/GetService 路径、点和方括号访问、FindFirstChild、WaitForChild、简单局部别名、有限的递归查找。\n- 特定目录下的动态名称查找、GetChildren/GetDescendants，以及快照中已有标签的查询；通用 Workspace 全局枚举不直接算作每个资产都有引用。\n- ObjectValue.Value、Model.PrimaryPart、常见关节/约束/Beam/Trail 的对象指向、界面 Adornee、相机 CameraSubject 等常见 Instance 引用属性。\n- 同一候选资产内部对自身零件的访问不算外部使用入口。\n\n';
report+='## 证据校验\n\n- AF-0603 野猪王战场：命中沼泽服务、GameHelper 等明确路径引用。\n- AF-0899 CamSetting：命中过场镜头脚本的明确路径引用。\n- 注释、同名配置文字、无命名空间的数字 ID，不会单独算成精确引用。\n- 审计器的检查用例覆盖内部引用排除、动态目录边界、暂存子目录、类型标注别名、数字命名空间和已知正式资产。\n\n';
report+=`## 限制\n\n这不是完整的 Luau 编译器或程序可达性证明。复杂作用域、模块函数返回值、动态加标签、运行时拼名、运行时创建引用等可能无法静态求解。扫描中有 ${audit.unresolvedGlobalLookups} 处全局动态名称查找无法据此排除某个特定对象；另跳过 ${audit.skippedBroadTraversals} 处过宽的遍历或索引覆盖，避免把所有资产都认定为有引用。\n\nWorkspace 中未被脚本引用的对象仍可能参与渲染、物理或射线检测。本轮没有做隔离移除回归。\n\n`;
report+='## 查看结果\n\n各分类 Markdown 已新增“引用审计”列。网站同样新增这一列，搜索“未检出静态引用”或“无引用”可定位候选条目；“无引用”只是搜索别名，不是未使用结论。\n\n- [分类文件索引](output/局内素材分类/分类文件索引.md)\n- [本地查询网站](sites/afterfall-assets/dist/index.html)\n';
await fs.writeFile(path.join(workspace,'资产静态引用审计.md'),report,'utf8');
const mainFile=path.join(workspace,'局内建模素材分类清单.md');let main=await fs.readFile(mainFile,'utf8');
const note=`## 静态引用审计（2026-11-18）\n\n已扫描 879 个脚本实例和常见对象引用属性。所有分类表新增“引用审计”列，其中 ${none.length} 条标为“未检出静态引用”；这不等于无用或可删除。详见[静态引用审计](资产静态引用审计.md)。\n\n`;
if(main.includes('## 静态引用审计（2026-11-18）'))main=main.replace(/## 静态引用审计（2026-11-18）[\s\S]*?(?=\n## |$)/,note.trimEnd());else main=main.replace('## 审查入口',note+'## 审查入口');
await fs.writeFile(mainFile,main,'utf8');
console.log(JSON.stringify({counts,noneButObservedInUse:usedButMissing.length,knownLiveChecks:['AF-0603','AF-0899']},null,2));
