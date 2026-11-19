import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const site=path.dirname(fileURLToPath(import.meta.url)),dist=path.join(site,'dist'),workspace=path.resolve(site,'..','..');
const context=vm.createContext({window:{}});
vm.runInContext(await fs.readFile(path.join(dist,'catalog-data.js'),'utf8'),context);
vm.runInContext(await fs.readFile(path.join(dist,'catalog-core.js'),'utf8'),context);
const data=context.window.AF_CATALOG,core=context.window.AssetCatalogCore,base={q:'',role:'',type:'',source:'',evidence:'',sort:'id'};
assert.equal(data.rows.length,905);assert.equal(new Set(data.rows.map(r=>r.id)).size,905);
assert.equal(data.roles.length,7);assert.equal(data.types.length,13);assert.equal(data.documents.length,20);
assert.equal(data.referenceAuditSummary.scriptInstances,879);assert.ok(data.rows.every(r=>r.referenceAudit));
assert.equal(core.filter(data.rows,{...base,q:'未检出静态引用'}).length,218);assert.equal(core.filter(data.rows,{...base,q:'无引用'}).length,218);
assert.equal(data.rows.find(r=>r.id==='AF-0603').referenceAudit.key,'direct');assert.equal(data.rows.find(r=>r.id==='AF-0899').referenceAudit.key,'direct');
assert.ok(data.rows.filter(r=>r.referenceAudit.noStaticReference).every(r=>r.source!=='预设库'));
assert.equal(core.filter(data.rows,{...base,source:'outside'}).length,304);
assert.equal(core.filter(data.rows,{...base,source:'inside'}).length,601);
assert.equal(core.filter(data.rows,{...base,role:'用途待确认'}).length,303);
for(const id of ['AF-0601','AF-0645','AF-0648'])assert.equal(data.rows.find(r=>r.id===id).role,'系统辅助与表现对象');
for(const id of ['AF-0678','AF-0727','AF-0734','AF-0786','AF-0787','AF-0809'])assert.equal(data.rows.find(r=>r.id===id).role,'已确认的开发测试与展示素材');
assert.equal(data.rows.find(r=>r.id==='AF-0773').role,'用途待确认');
assert.equal(core.filter(data.rows,{...base,role:'用途待确认'}).filter(r=>r.referenceAudit.key==='direct').length,1);
assert.equal(core.filter(data.rows,{...base,role:'直接使用的玩法场景'})[0].id,'AF-0603');
assert.equal(core.filter(data.rows,{...base,q:'ａｆ－０６０３'})[0].id,'AF-0603');
assert.equal(core.filter(data.rows,{...base,q:'camsetting',evidence:'used'})[0].id,'AF-0899');
assert.equal(core.filter(data.rows,{...base,q:'野猪王战场',source:'outside',role:'直接使用的玩法场景'}).length,1);
assert.equal(core.filter(data.rows,{...base,q:'CamSetting',role:'用途待确认'}).length,0);
assert.ok(core.filter(data.rows,{...base,q:'workspace.prefabs.map 地块'}).length>0);
assert.equal(core.evidence(data.rows.find(r=>r.id==='AF-0603')).key,'used');
assert.equal(core.evidence(data.rows.find(r=>r.id==='AF-0899')).key,'used');
assert.ok(core.filter(data.rows,{...base,sort:'parts'})[0].parts>=core.filter(data.rows,{...base,sort:'parts'})[1].parts);
const empty=core.page([],99,30);assert.equal(empty.totalPages,1);assert.equal(empty.page,1);assert.equal(empty.start,0);
const last=core.page(data.rows,99,30);assert.equal(last.page,31);assert.equal(last.rows.length,5);
const ids=data.rows.map(r=>r.id);for(const dim of ['role','type']){const seen=[];const docs=data.documents.filter(d=>d.dimension===dim);assert.equal(docs.reduce((a,d)=>a+d.count,0),905);for(const d of docs){const md=await fs.readFile(path.join(dist,'docs',d.file),'utf8');const matches=[...md.matchAll(/^\| (AF-\d{4}) \|/gm)].map(m=>m[1]);assert.equal(matches.length,d.count);seen.push(...matches);for(const link of md.matchAll(/\]\(([^)]+)\)/g))await fs.access(path.resolve(dist,'docs',link[1]));}assert.deepEqual([...seen].sort(),[...ids].sort());}
const manifest=JSON.parse(await fs.readFile(path.join(site,'content-manifest.json'),'utf8'));
for(const d of manifest.documents){const file=path.join(workspace,'output','局内素材分类',d.local);const md=await fs.readFile(file,'utf8');for(const link of md.matchAll(/\]\(([^)]+)\)/g))await fs.access(path.resolve(path.dirname(file),link[1]));}
for(const f of ['局内建模素材分类清单.md','output/局内素材分类/分类文件索引.md','output/局内素材分类/00_按程序用途分类明细.md','output/局内素材分类/01_预设库明细.md','output/局内素材分类/02_散放素材明细.md']){const md=await fs.readFile(path.join(workspace,f),'utf8');for(const link of md.matchAll(/\]\(([^)]+)\)/g))await fs.access(path.resolve(path.dirname(path.join(workspace,f)),link[1]));}
const html=await fs.readFile(path.join(dist,'index.html'),'utf8');
const htmlIds=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);assert.equal(htmlIds.length,new Set(htmlIds).size,'Duplicate element IDs');
for(const f of ['catalog-data.js','catalog-core.js','app.js'])new vm.Script(await fs.readFile(path.join(dist,f),'utf8'),{filename:f});
for(const href of html.matchAll(/(?:src|href)="([^"#]+)"/g)){if(href[1].startsWith('data:'))continue;await fs.access(path.resolve(dist,href[1]));}
console.log('PASS: 905 records; 7 role files + 13 type files; exact partitions; search and combined filters; evidence states; empty/last pages; Markdown links; JS syntax.');
