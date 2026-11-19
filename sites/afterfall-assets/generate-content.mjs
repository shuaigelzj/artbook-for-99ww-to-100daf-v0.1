import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const site=path.dirname(fileURLToPath(import.meta.url));
const workspace=path.resolve(site,'..','..');
const source=path.join(workspace,'output','局内素材分类_取证','catalog_classified_v2.json');
const rows=JSON.parse(await fs.readFile(source,'utf8'));
const reskin=JSON.parse(await fs.readFile(path.join(workspace,'output/换皮替换分析/reskin-assessment.json'),'utf8'));
const reskinById=new Map(reskin.assessments.map(r=>[r.id,r]));
for(const row of rows){if(!reskinById.has(row.id))throw new Error('Missing reskin assessment: '+row.id);row.reskin=reskinById.get(row.id);}
let previews=null;
try{previews=JSON.parse(await fs.readFile(path.join(site,'preview-manifest.json'),'utf8'));}catch(error){if(error.code!=='ENOENT')throw error;}
if(previews){for(const preview of previews.previews){const row=rows.find(r=>r.id===preview.id);if(!row)throw new Error('Unknown preview ID');row.preview=preview;}}
let referenceAudit=null;
try{referenceAudit=JSON.parse(await fs.readFile(path.join(workspace,'output','引用审计','reference_audit.json'),'utf8'));}catch(error){if(error.code!=='ENOENT')throw error;}
if(referenceAudit){const audits=new Map(referenceAudit.results.map(r=>[r.id,r]));for(const row of rows){const audit=audits.get(row.id);if(!audit)throw new Error('Missing reference audit: '+row.id);row.referenceAudit={...audit,evidence:audit.evidence.map(({excerpt,...e})=>e),nameCandidates:audit.nameCandidates.map(({excerpt,...e})=>e)};}}
const roles=['地图生成模板','实体与物品模板','直接使用的玩法场景','过场与演出场景','系统辅助与表现对象','已确认的开发测试与展示素材','用途待确认'];
const types=['地形植被','建筑场景','营地设施','人形角色','怪物与Boss','动物与坐骑','资源与食物','武器工具','服饰护具','机关','特效与界面','辅助零件','类型待确认'];
const esc=v=>String(v??'').replaceAll('|','\\|').replace(/\r?\n/g,' ').replace(/\s+/g,' ').trim();
const table=(h,rs)=>'| '+h.join(' | ')+' |\n| '+h.map(()=>'---').join(' | ')+' |\n'+rs.map(r=>'| '+r.map(esc).join(' | ')+' |').join('\n')+'\n';
const dist=path.join(site,'dist'),docs=path.join(workspace,'output','局内素材分类');
const roleDir=path.join(docs,'按程序用途'),typeDir=path.join(docs,'按素材类型');
for(const d of [dist,path.join(dist,'docs'),roleDir,typeDir])await fs.mkdir(d,{recursive:true});
const documentList=[];
for(const [dimension,values,field,outDir] of [['role',roles,'role',roleDir],['type',types,'materialType',typeDir]]){
 for(let i=0;i<values.length;i++){
  const name=values[i],items=rows.filter(r=>r[field]===name);
  const file=`${String(i+1).padStart(2,'0')}_${name}.md`,webFile=`${dimension}-${String(i+1).padStart(2,'0')}.md`;
  let text=`# ${name}\n\n2026-11-18。第二版分类快照，${items.length} 条。[返回分类文件索引](../分类文件索引.md)。\n\n`;
  text+='程序用途与素材类型分别记录，Prefabs 内外仅表示位置。目录推断、配置身份、实测生成命中与运行态保留分别标注。未确认不等于未使用。\n\n';
  text+='换皮评估更新于 2026-11-19。可直接出图表示已有完整设计单元；工程替换仍需保留控制接口。配套编号默认是建议演示/对照，具体关系见逐条说明。\n\n';
  text+=table(['编号','名称 / 原名','程序用途','素材类型','位置','引用审计','可直接出换皮图','制图单元 / 理由','配套与替换方案','工程保留约束','脚本或入口','依据','备注','Studio 定位'],items.map(r=>[r.id,esc(r.display)===esc(r.name)?r.display:`${r.display} / ${r.name}`,r.role,r.materialType,r.source==='预设库'?'Prefabs 内':'Prefabs 外',r.referenceAudit?.status??'未审计',`${r.reskin.decision} · ${r.reskin.workflow}（${r.reskin.confidence}）`,`${r.reskin.subject}；${r.reskin.unit}；${r.reskin.reason}`,[r.reskin.companions.map(c=>`${c.id} ${c.name}（${c.relation}）`).join('；'),...r.reskin.plan.map((p,i)=>`${i+1}. ${p}`)].filter(Boolean).join('；'),r.reskin.engineering.join('；'),r.entry,r.roleBasis,[r.roleNote,r.notes!==r.roleNote?r.notes:''].filter(Boolean).join('；'),`\`${esc(r.path)}\` · \`${r.locator}\``]));
  await fs.writeFile(path.join(outDir,file),text,'utf8');
  await fs.writeFile(path.join(dist,'docs',webFile),text.replace('[返回分类文件索引](../分类文件索引.md)','[返回分类文件索引](index.md)'),'utf8');
  documentList.push({dimension,name,count:items.length,file:webFile,local:`${dimension==='role'?'按程序用途':'按素材类型'}/${file}`});
 }
}
let index='# 素材分类文件索引\n\n905 条记录。按程序用途分为 7 个文件，按素材类型分为 13 个文件；两组是同一批记录的不同查看方式，不能相加计数。\n\n[打开资产查询网站](../../sites/afterfall-assets/dist/index.html) · [返回分类总览](../../局内建模素材分类清单.md)\n\n';
for(const dimension of ['role','type']){index+=`## ${dimension==='role'?'按程序用途':'按素材类型'}\n\n`;index+=table(['分类','条目数','明细文件'],documentList.filter(d=>d.dimension===dimension).map(d=>[d.name,d.count,`[查看明细](${d.local})`]));index+='\n';}
await fs.writeFile(path.join(docs,'分类文件索引.md'),index,'utf8');
await fs.writeFile(path.join(dist,'docs','index.md'),index.replace(/\[打开资产查询网站\][^\n]*/,'[返回资产查询网站](../index.html)').replaceAll(/\((按程序用途|按素材类型)\/([^)]*)\)/g,(full,dir,file)=>{const doc=documentList.find(d=>d.local===`${dir}/${file}`);return doc?`(${doc.file})`:full;}),'utf8');
const redirect='# 按程序用途分类明细索引\n\n原完整大表已拆分，以下文件共包含全部 905 条记录。\n\n[打开资产查询网站](../../sites/afterfall-assets/dist/index.html) · [全部分类文件索引](分类文件索引.md)\n\n'+table(['程序用途','条目数','文件'],documentList.filter(d=>d.dimension==='role').map(d=>[d.name,d.count,`[查看](${d.local})`]));
await fs.writeFile(path.join(docs,'00_按程序用途分类明细.md'),redirect,'utf8');
for(const [file,sourceLabel,title] of [['01_预设库明细.md','预设库','Prefabs 内条目位置索引'],['02_散放素材明细.md','散放与其他容器','Prefabs 外条目位置索引']]){
 const subset=rows.filter(r=>r.source===sourceLabel);
 await fs.writeFile(path.join(docs,file),`# ${title}\n\n${subset.length} 条。位置筛选请使用[资产查询网站](../../sites/afterfall-assets/dist/index.html)，明细文件按用途拆分。\n\n`+table(['程序用途','当前位置条目数','分类文件'],documentList.filter(d=>d.dimension==='role').map(d=>[d.name,subset.filter(r=>r.role===d.name).length,`[查看分类](${d.local})`])),'utf8');
}
const mainFile=path.join(workspace,'局内建模素材分类清单.md');let main=await fs.readFile(mainFile,'utf8');
const marker='## 网站与分类型文件';
if(!main.includes(marker))main=main.replace('## 审查入口',`${marker}\n\n- [资产查询网站](sites/afterfall-assets/dist/index.html)：搜索、筛选、分页与单条详情。\n- [分类文件索引](output/局内素材分类/分类文件索引.md)：7 个程序用途文件、13 个素材类型文件。\n\n## 审查入口`);
main=main.replace('按程序用途分类的完整明细','按程序用途分类明细索引').replace('905 条，按上述七类排列。','905 条，已拆成七个分类文件。');
await fs.writeFile(mainFile,main,'utf8');
const keep=['id','index','display','name','path','locator','role','materialType','roleBasis','entry','roleNote','source','notes','parts','meshes','scripts','position','theme','observedGenerationRuns','retainedRuns','geometryCandidates','referenceAudit','preview','reskin'];
const catalog={date:'2026-11-18',version:60,placeId:'108983613755535',roles,types,previewSummary:previews?{count:previews.count,total:rows.length,last:previews.last,latestBatch:previews.latestBatch,complete:previews.complete,methods:previews.methods,batches:previews.batches}:null,referenceAuditSummary:referenceAudit?{scriptInstances:referenceAudit.scriptInstances,uniqueSources:referenceAudit.uniqueSources,counts:referenceAudit.results.reduce((a,r)=>{a[r.status]=(a[r.status]??0)+1;return a;},{})}:null,documents:documentList.map(({local,...d})=>d),rows:rows.map(r=>Object.fromEntries(keep.filter(k=>r[k]!==undefined).map(k=>[k,r[k]])))};
catalog.reskinSummary={date:reskin.date,version:reskin.version,counts:reskin.counts,workflows:reskin.workflowCounts,definition:reskin.definition,pairingPolicy:reskin.pairingPolicy,method:reskin.method};
await fs.writeFile(path.join(dist,'catalog-data.js'),'window.AF_CATALOG = '+JSON.stringify(catalog).replaceAll('<','\\u003c')+';\n','utf8');
const reskinGuide=await fs.readFile(path.join(workspace,'output/换皮替换分析/README.md'),'utf8');
await fs.writeFile(path.join(dist,'docs/reskin-guide.md'),reskinGuide.replace('[分类文件索引](../局内素材分类/分类文件索引.md)','[分类文件索引](index.md)'),'utf8');
await fs.writeFile(path.join(site,'content-manifest.json'),JSON.stringify({total:rows.length,documents:documentList},null,2),'utf8');
console.log(JSON.stringify({records:rows.length,roleDocuments:roles.length,typeDocuments:types.length,site:dist,index:path.join(docs,'分类文件索引.md')}));
