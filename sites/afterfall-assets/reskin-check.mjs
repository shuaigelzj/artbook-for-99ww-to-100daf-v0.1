import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath,pathToFileURL} from 'node:url';
const site=path.dirname(fileURLToPath(import.meta.url)),dist=path.join(site,'dist');
const box=vm.createContext({window:{}});for(const file of ['catalog-data.js','catalog-core.js'])vm.runInContext(await fs.readFile(path.join(dist,file),'utf8'),box);
const data=box.window.AF_CATALOG,core=box.window.AssetCatalogCore;
const assessment=JSON.parse(await fs.readFile(path.resolve(site,'../../output/换皮替换分析/reskin-assessment.json'),'utf8'));
const baseline=JSON.parse(await fs.readFile(path.resolve(site,'../../output/局内素材分类_取证/catalog_classified_v2.json'),'utf8'));
assert.equal(data.rows.length,905);assert.equal(assessment.assessments.length,905);assert.equal(new Set(data.rows.map(x=>x.reskin.id)).size,905);
for(const r of data.rows){const old=baseline.find(x=>x.id===r.id);for(const key of ['role','materialType','path','display','parts'])assert.equal(r[key],old[key],r.id+' original '+key);const a=r.reskin;assert.equal(a.id,r.id);assert.ok(a.reason&&a.subject&&a.unit&&a.plan.length>=3&&a.engineering.length);for(const c of a.companions)assert.ok(data.rows.some(x=>x.id===c.id));assert.equal(a.canDirect,a.decisionKey==='direct'?true:a.decisionKey==='prepare'?false:null);}
const base={q:'',role:'',type:'',source:'',evidence:'',reskin:'',sort:'id'};
for(const [k,n]of Object.entries(assessment.counts))assert.equal(core.filter(data.rows,{...base,reskin:k}).length,n);
for(const [id,key,flow] of [['AF-0002','direct','单体整件'],['AF-0032','prepare','地块铺排'],['AF-0047','prepare','地块铺排'],['AF-0051','none','占地约束'],['AF-0151','direct','单体整件'],['AF-0186','prepare','零件装配'],['AF-0200','prepare','零件装配'],['AF-0242','direct','完整武器'],['AF-0276','prepare','零件装配'],['AF-0353','prepare','角色试穿'],['AF-0604','verify','原型补齐'],['AF-0648','prepare','特效演示'],['AF-0652','direct','单件头饰'],['AF-0733','none','逻辑保留'],['AF-0899','prepare','场景分镜'],['AF-0905','prepare','界面版式']]){const a=data.rows.find(x=>x.id===id).reskin;assert.equal(a.decisionKey,key,id);assert.equal(a.workflow,flow,id);}
assert.ok(data.rows.find(x=>x.id==='AF-0242').reskin.companions.some(c=>c.id==='AF-0161'&&c.relation.includes('param=502')));
assert.ok(data.rows.find(x=>x.id==='AF-0242').reskin.companions.some(c=>c.id==='AF-0186'));
assert.ok(core.filter(data.rows,{...base,reskin:'prepare',q:'地块铺排'}).length>15);
assert.equal(core.filter(data.rows,{...base,q:'AF-0047'}).length,1);
assert.ok(core.filter(data.rows,{...base,q:'配套:AF-0242'}).some(r=>r.id==='AF-0186'));
for(const d of data.documents){const md=await fs.readFile(path.join(dist,'docs',d.file),'utf8');assert.ok(md.includes('可直接出换皮图')&&md.includes('工程保留约束'));assert.equal([...md.matchAll(/^\| AF-\d{4} \|/gm)].length,d.count);}
console.log('PASS: all 905 assessments; complete plans/companions; original classifications preserved; correct unit examples; real config ammo pairing; all Markdown partitions.');
const require=createRequire(path.resolve(path.dirname(process.execPath),'..','node_modules','__qa_resolver.cjs'));
const {chromium}=require('playwright');const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000},acceptDownloads:true}),errors=[];page.on('pageerror',e=>errors.push(e.message));const url=pathToFileURL(path.join(dist,'index.html')).href;
 await page.goto(url,{waitUntil:'networkidle'});assert.equal(await page.locator('#asset-rows .reskin-flag').count(),30);assert.equal(await page.locator('.asset-table th').count(),8);
 await page.locator('#reskin-filter').selectOption('prepare');assert.equal(await page.locator('#result-count').textContent(),'222 条记录');assert.ok(page.url().includes('reskin=prepare'));
 await page.locator('#search').fill('AF-0047');assert.equal(await page.locator('#asset-rows tr').count(),1);await page.locator('.arrow-open').click();assert.ok((await page.locator('.reskin-detail').textContent()).includes('5 × 5'));assert.ok((await page.locator('.reskin-detail').textContent()).includes('50-stud'));await page.keyboard.press('Escape');
 await page.locator('#reset').click();await page.locator('#search').fill('AF-0186');await page.locator('.asset-thumb').click();assert.ok((await page.locator('.reskin-detail').textContent()).includes('枪托')||(await page.locator('.reskin-detail').textContent()).includes('Stock'));
 await page.locator('.reskin-companions [data-open-id="AF-0242"]').click();assert.equal(await page.locator('#detail-title').textContent(),'Iron Verdict Rifle');assert.ok((await page.locator('.reskin-detail').textContent()).includes('Rifle Bullet'));await page.keyboard.press('Escape');
 await page.goto(url+'#reskin=verify&size=50',{waitUntil:'networkidle'});assert.equal(await page.locator('#result-count').textContent(),'46 条记录');assert.equal(await page.locator('#reskin-filter').inputValue(),'verify');
 await page.locator('#reset').click();await page.locator('[data-view="documents"]').click();const pending=page.waitForEvent('download');await page.locator('.document-card a').first().click();const download=await pending;const text=await fs.readFile(await download.path(),'utf8');assert.ok(text.includes('可直接出换皮图')&&text.includes('工程保留约束'));
 await page.setViewportSize({width:390,height:844});await page.locator('.brand').click();await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));const bounds=await page.evaluate(()=>({width:innerWidth,scroll:document.documentElement.scrollWidth,overflow:[...document.querySelectorAll('body *')].filter(e=>e.getBoundingClientRect().right>innerWidth+1&&!e.closest('.table-wrap,.role-nav')).map(e=>({tag:e.tagName,cls:e.className,right:e.getBoundingClientRect().right,text:e.textContent.slice(0,60)})).slice(0,12)}));assert.ok(bounds.scroll<=bounds.width,JSON.stringify(bounds));assert.ok(await page.locator('.table-wrap').evaluate(e=>e.getBoundingClientRect().right<=innerWidth+1));await page.locator('#reskin-filter').selectOption('none');assert.equal(await page.locator('#result-count').textContent(),'30 条记录');assert.deepEqual(errors,[]);
 console.log('PASS: new column; status filter/hash restore; plan detail; companion navigation; original thumbnail/arrow; Markdown fields; mobile containment; no browser errors.');
}finally{await browser.close();}
