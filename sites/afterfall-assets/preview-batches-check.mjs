import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {createRequire} from 'node:module';
import {fileURLToPath,pathToFileURL} from 'node:url';
const site=path.dirname(fileURLToPath(import.meta.url)),dist=path.join(site,'dist');
const context=vm.createContext({window:{}});vm.runInContext(await fs.readFile(path.join(dist,'catalog-data.js'),'utf8'),context);
const records=context.window.AF_CATALOG.rows.filter(r=>r.preview);const manifest=JSON.parse(await fs.readFile(path.join(site,'preview-manifest.json'),'utf8'));const initial=records.filter(r=>Number(r.id.slice(3))<=150);const tracked=new Set(execFileSync('git',['ls-tree','-r','--name-only','HEAD','dist/previews/images'],{cwd:site,encoding:'utf8'}).trim().split(/\r?\n/));
assert.equal(records.length,manifest.count);assert.equal(records[0].id,'AF-0001');assert.equal(records.at(-1).id,manifest.last);assert.equal(JSON.stringify(Array.from(records,r=>r.id)),JSON.stringify(Array.from(context.window.AF_CATALOG.rows.slice(0,manifest.count),r=>r.id)));
assert.equal(records.filter(r=>r.preview.batch==='1').length,50);assert.equal(records.filter(r=>r.preview.batch==='2').length,100);
assert.equal(initial.filter(r=>r.preview.method==='原貌截图').length,145);assert.equal(initial.filter(r=>r.preview.method==='辅助可视化').length,4);assert.equal(initial.filter(r=>r.preview.method==='说明卡').length,1);
if(records.length<905)assert.ok(!context.window.AF_CATALOG.rows[records.length].preview);
let additional=0;
for(const r of records){
 const folder=JSON.parse(await fs.readFile(path.join(site,'preview-batches.json'),'utf8')).find(b=>b.id===r.preview.batch).directory;
 const published=await fs.readFile(path.join(dist,r.preview.image)),original=await fs.readFile(path.resolve(site,'../../output',folder,'images',r.id+'.jpg'));
 assert.ok(published.equals(original),r.id+' image changed');
 if(tracked.has('dist/'+r.preview.image))assert.ok(published.equals(execFileSync('git',['show','HEAD:dist/'+r.preview.image],{cwd:site})),r.id+' first-batch image changed');
 for(const view of r.preview.views??[]){additional++;assert.ok((await fs.readFile(path.join(dist,view.image))).equals(await fs.readFile(path.resolve(site,'../../output',folder,view.file))));}
}
assert.equal(additional,manifest.additionalImages);assert.ok(additional>=2);
for(const file of ['previews/review.js','app.js'])new vm.Script(await fs.readFile(path.join(dist,file),'utf8'),{filename:file});
const md=await fs.readFile(path.resolve(site,'../../output/资产图示_第2批100/审查清单.md'),'utf8');assert.equal([...md.matchAll(/^\| AF-\d{4} \|/gm)].length,100);
for(const match of md.matchAll(/\]\(([^)]+)\)/g))await fs.access(path.resolve(site,'../../output/资产图示_第2批100',match[1].split(/[?#]/)[0]));
const require=createRequire(path.resolve(path.dirname(process.execPath),'..','node_modules','__qa_resolver.cjs'));
const {chromium}=require('playwright');const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
const galleryUrl=pathToFileURL(path.join(dist,'previews/index.html')).href,mainUrl=pathToFileURL(path.join(dist,'index.html')).href;
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(galleryUrl+'?batch=2',{waitUntil:'networkidle'});assert.equal(await page.locator('.card').count(),100);assert.equal(await page.locator('.card').first().getAttribute('data-id'),'AF-0051');
 await page.locator('#batch').selectOption('1');assert.equal(await page.locator('.card').count(),50);
 await page.locator('#batch').selectOption('');assert.equal(await page.locator('.card').count(),manifest.count);
 const images=await page.locator('.photo img').evaluateAll(async imgs=>{const selected=imgs.filter((_,i)=>i<20||i>=imgs.length-5);for(const i of selected)i.loading='eager';await Promise.all(selected.map(i=>i.decode()));return selected.map(i=>({w:i.naturalWidth,h:i.naturalHeight}));});assert.ok(images.every(i=>i.w===788&&i.h===392));
 await page.locator('#method').selectOption('辅助可视化');assert.equal(await page.locator('.card').count(),records.filter(r=>r.preview.method==='辅助可视化').length);
 await page.locator('#method').selectOption('');await page.locator('#batch').selectOption('2');await page.locator('#search').fill('AF-0133');await page.locator('.photo').click();
 assert.ok(await page.locator('#viewer').evaluate(d=>d.open));assert.equal(await page.locator('#views button').count(),2);await page.locator('#views [data-view="0"]').click();assert.ok((await page.locator('#viewer-image').getAttribute('src')).includes('-exterior.jpg'));await page.locator('#viewer-image').evaluate(i=>i.decode());
 await page.keyboard.press('Escape');assert.equal(await page.locator('#viewer').evaluate(d=>d.open),false);
 await page.goto(galleryUrl+'?batch=2#asset=AF-0150');await page.waitForFunction(()=>document.querySelector('#viewer-title').textContent.includes('AF-0150'));assert.ok(await page.locator('#next').isDisabled());await page.locator('#previous').click();assert.ok((await page.locator('#viewer-title').textContent()).includes('AF-0149'));await page.locator('#close').click();
 await page.goto(galleryUrl+'?batch=50');assert.equal(await page.locator('.card').count(),50);
 await page.setViewportSize({width:390,height:844});assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 await page.setViewportSize({width:1440,height:1000});await page.goto(mainUrl+'#q=AF-0051');
 assert.equal(await page.locator('#asset-rows .asset-thumb').count(),1);assert.equal(await page.locator('#asset-rows .arrow-open').count(),1);await page.locator('.asset-thumb img').evaluate(i=>i.decode());
 await page.locator('.arrow-open').click();assert.equal(await page.locator('#detail-title').textContent(),'Building1x1');assert.equal(await page.locator('.detail-preview img').count(),1);await page.locator('#close-detail').click();
 await page.locator('.asset-thumb').click();assert.equal(await page.locator('#detail-title').textContent(),'Building1x1');await page.keyboard.press('Escape');
 await page.locator('#search').fill('AF-'+String(Math.min(905,manifest.count+1)).padStart(4,'0'));assert.equal(await page.locator('#asset-rows .asset-thumb').count(),manifest.count===905?1:0);assert.equal(await page.locator('#asset-rows .arrow-open').count(),1);
 await page.setViewportSize({width:390,height:844});assert.ok(await page.locator('.table-wrap').evaluate(e=>e.getBoundingClientRect().right<=innerWidth+1));assert.deepEqual(errors,[]);
 console.log('PASS: completed prefix and source image bytes checked; all previously published images unchanged; both batches and legacy links; all JPEGs decode; gallery filters/navigation/deep links; cave view switch; inline thumbnails and original arrows open the same detail; ungenerated rows keep arrows; mobile bounds; 100-row Markdown. No website screenshots captured.');
}finally{await browser.close();}
