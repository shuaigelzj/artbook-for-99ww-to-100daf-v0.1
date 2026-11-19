import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const site=path.dirname(fileURLToPath(import.meta.url)),workspace=path.resolve(site,'../..');
const catalog=JSON.parse(await fs.readFile(path.join(workspace,'output/局内素材分类_取证/catalog_classified_v2.json'),'utf8'));
const specifications=JSON.parse(await fs.readFile(path.join(site,'preview-batches.json'),'utf8'));
const previews=[],batches=[];let additionalImages=0;
const target=path.join(site,'dist/previews/images');await fs.mkdir(target,{recursive:true});
const escape=v=>String(v).replaceAll('|','\\|').replaceAll('\n',' ');
async function copyImage(directory,file){
 const source=path.join(directory,file),image=await fs.readFile(source);
 assert.ok(image.length>1000&&image[0]===255&&image[1]===216&&image.at(-2)===255&&image.at(-1)===217,'Invalid JPEG: '+source);
 const relative='previews/images/'+path.basename(file);await fs.copyFile(source,path.join(site,'dist',relative));return relative;
}
for(const spec of specifications){
 const directory=path.join(workspace,'output',spec.directory);
 let rows,cleanup;
 try{rows=JSON.parse(await fs.readFile(path.join(directory,'capture-records.json'),'utf8')).sort((a,b)=>a.id.localeCompare(b.id));cleanup=JSON.parse(await fs.readFile(path.join(directory,'cleanup.json'),'utf8'));}catch(error){if(error.code==='ENOENT')break;throw error;}
 if(rows.length!==spec.end-spec.start)break;
 assert.deepEqual(rows.map(r=>r.id),catalog.slice(spec.start,spec.end).map(r=>r.id));
 assert.equal(cleanup.sourcesIntact,rows.length);for(const key of ['cleaned','guiRestored','cameraRestored','lightingRestored'])assert.equal(cleanup[key],true);
 const entries=[];
 for(const row of rows){
  const image=await copyImage(directory,'images/'+row.id+'.jpg');
  const views=[];for(const view of row.additionalViews??[]){views.push({...view,image:await copyImage(directory,view.file)});additionalImages++;}
  const preview={id:row.id,image,method:row.method,note:row.note,width:row.viewport[0],height:row.viewport[1],batch:spec.id,...(views.length?{views}:{})};
  previews.push(preview);entries.push(preview);
 }
 const methods=entries.reduce((a,r)=>(a[r.method]=(a[r.method]||0)+1,a),{});
 const batch={id:spec.id,label:spec.label,first:rows[0].id,last:rows.at(-1).id,count:rows.length,methods,reviewPending:true};batches.push(batch);
 {
  let md=`# ${spec.label}资产图示\n\n更新于 2026-11-19。按编号完成 **${batch.first} 至 ${batch.last}**，本批 ${rows.length} 条。[查看全量批次索引](../资产图示_全量/图示批次索引.md)。\n\n`;
  md+=`[打开本批网站审查页](../../sites/afterfall-assets/dist/previews/index.html?batch=${spec.id})\n\n全部图片在 Roblox Studio 中生成，使用临时展示副本；未演示玩法交互。原貌截图、静态视窗、辅助可视化、界面或效果演示、说明卡按各条备注区分。静态视窗通过 ViewportFrame 渲染，实时阴影和动态特效未完整呈现，部分材质显示有差异；大型对象可对展示副本等比缩放。\n\n`;
  md+=Object.entries(methods).map(([k,v])=>`- ${k}：${v} 条`).join('\n')+'\n\n';
  md+=`临时展台已清除，${rows.length} 个源对象路径或原始名称字节定位及部件数核对通过，相机、灯光、HUD 已恢复。\n\n| 编号 | 名称 | 图示方式 | 配图 | 说明 |\n| --- | --- | --- | --- | --- |\n`;
  for(const p of entries){const r=catalog.find(r=>r.id===p.id);const links=[`[主图](images/${p.id}.jpg)`,...(p.views??[]).map(v=>`[${v.label}](${v.file})`)];md+=`| ${p.id} | ${escape(r.name)} | ${p.method} | ${links.join(' · ')} | ${escape(p.note)} |\n`;}
  await fs.writeFile(path.join(directory,'审查清单.md'),md,'utf8');
  await fs.writeFile(path.join(directory,'summary.json'),JSON.stringify({...batch,cleanup,additionalImages:entries.reduce((n,p)=>n+(p.views?.length??0),0)},null,2),'utf8');
 }
}
const methods=previews.reduce((a,r)=>(a[r.method]=(a[r.method]||0)+1,a),{});
const manifest={date:'2026-11-19',placeId:'108983613755535',first:previews[0]?.id,last:previews.at(-1)?.id,count:previews.length,total:catalog.length,complete:previews.length===catalog.length,latestBatch:batches.at(-1)?.id,reviewPending:true,methods,batches,additionalImages,previews};
await fs.writeFile(path.join(site,'preview-manifest.json'),JSON.stringify(manifest,null,2),'utf8');
let index=`# 905 条资产图示批次索引\n\n当前已完成 ${previews.length} / ${catalog.length} 条。[网站图示审查页](../../sites/afterfall-assets/dist/previews/index.html?batch=all)。\n\n| 批次 | 编号范围 | 条目数 | 清单 |\n| --- | --- | --- | --- |\n`;
for(const b of batches){const spec=specifications.find(s=>s.id===b.id);index+=`| ${b.label} | ${b.first}～${b.last} | ${b.count} | [查看](../${spec.directory}/审查清单.md) |\n`;}
await fs.writeFile(path.join(workspace,'output/资产图示_全量/图示批次索引.md'),index,'utf8');
console.log(JSON.stringify({assets:previews.length,additionalImages,batches:batches.map(b=>({id:b.id,count:b.count})),methods}));
