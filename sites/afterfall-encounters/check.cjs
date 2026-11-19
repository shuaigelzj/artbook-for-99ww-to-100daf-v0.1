const fs=require('node:fs');
const path=require('node:path');
const cp=require('node:child_process');
const assert=require('node:assert/strict');
const d=require('./dist/data.js');
const seen=new Set(),categories=new Set(d.categories.map(c=>c.id));
for(const e of d.entries){assert(!seen.has(e.id),'duplicate id '+e.id);seen.add(e.id);assert(categories.has(e.category));assert(['enabled','inactive'].includes(e.status));for(const k of ['name','zone','size','trigger','encounter','reward','reset','summary','repeat','design'])assert(typeof e[k]==='string'&&e[k].length>0,e.id+': missing '+k);assert(e.flow.length>=3&&e.flow.every(v=>v.length===2&&v.every(Boolean)),e.id+': incomplete flow');assert(e.combat.length&&e.rewards.length&&e.sources.length,e.id+': missing detail');for(const z of e.zones)assert(z>=2&&z<=6);}
for(const e of d.entries)for(const id of e.relations)assert(seen.has(id),e.id+': broken relation '+id);
assert.equal(d.entries.filter(e=>e.category==='arena').length,6);
assert.equal(d.entries.filter(e=>e.category==='wanted').length,4);
assert.equal(d.entries.filter(e=>e.status==='inactive').length,3);
for(const f of ['app.js','data.js'])cp.execFileSync(process.execPath,['--check',path.join('dist',f)]);
const html=fs.readFileSync('dist/index.html','utf8');
for(const match of html.matchAll(/(?:src|href)="([^"#][^"]*)"/g)){const p=match[1];if(!/^(https?:|data:)/.test(p))assert(fs.existsSync(path.join('dist',p)),'missing asset '+p);}
assert.deepEqual(JSON.parse(fs.readFileSync('dist/docs/catalog.json','utf8')),d,'exported catalog out of sync');
const overview=fs.readFileSync('dist/docs/overview.md','utf8'),details=fs.readFileSync('dist/docs/details.md','utf8');
for(const e of d.entries){assert(overview.includes(e.name));assert(details.includes('## '+e.name));}
const manifest=JSON.parse(fs.readFileSync('.openai/hosting.json','utf8'));assert.equal(manifest.static.directory,'dist');assert(manifest.project_id);
console.log(JSON.stringify({ok:true,entries:d.entries.length,enabled:d.entries.filter(e=>e.status==='enabled').length,inactive:d.entries.filter(e=>e.status==='inactive').length,categories:d.categories.length,checks:['content completeness','unique IDs and relations','JS syntax','static assets','export synchronization','hosting manifest']}));
