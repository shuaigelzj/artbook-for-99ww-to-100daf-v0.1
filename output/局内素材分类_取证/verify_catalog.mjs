import fs from 'node:fs/promises';
import path from 'node:path';
const cwd=process.cwd();
const report=JSON.parse(await fs.readFile('output/局内素材分类_取证/validation.json','utf8'));
const records=JSON.parse(await fs.readFile('output/局内素材分类_取证/catalog_classified.json','utf8'));
if(report.categories.reduce((n,x)=>n+x.count,0)!==905)throw new Error('Category total mismatch');
const detailFiles=report.outputs.slice(1,3);
const seen=[];
for(const file of report.outputs){
 const md=await fs.readFile(file,'utf8');
 if(md.includes('\uFFFD'))throw new Error('Unexpected replacement character in '+file);
 for(const m of md.matchAll(/\]\(([^)]+\.md)\)/g))await fs.access(path.resolve(path.dirname(path.join(cwd,file)),m[1]));
 for(const block of md.split(/\n\s*\n/)){
  const lines=block.split('\n').filter(x=>x.startsWith('| '));if(lines.length<2)continue;
  const cells=s=>s.split(/(?<!\\)\|/).length;
  const expected=cells(lines[0]);
  for(const line of lines)if(cells(line)!==expected)throw new Error('Malformed Markdown table in '+file+': '+line.slice(0,60));
 }
 if(detailFiles.includes(file))for(const m of md.matchAll(/^\| (AF-\d{4}) \|/gm))seen.push(m[1]);
 console.log(file+' : '+md.split('\n').length+' lines');
}
if(seen.length!==905||new Set(seen).size!==905)throw new Error('Missing or duplicate detail records');
const ids=new Set(records.map(x=>x.id));for(const id of seen)if(!ids.has(id))throw new Error('Unknown record '+id);
for(const r of records)if(!r.category||!r.subcategory||!r.basis||!r.path||!r.locator)throw new Error('Missing classification field '+r.id);
console.log('Validated: 905 unique records, category reconciliation, Markdown tables, local document links.');
