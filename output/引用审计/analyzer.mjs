import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

export function tokenize(source){
 const out=[];let i=0,line=1;
 const longStart=at=>source.slice(at).match(/^\[(=*)\[/);
 while(i<source.length){
  const c=source[i];if(/\s/.test(c)){if(c==='\n')line++;i++;continue;}
  if(source.startsWith('--',i)){i+=2;const m=longStart(i);if(m){const stop=source.indexOf(']'+m[1]+']',i+m[0].length);const end=stop<0?source.length:stop+m[1].length+2;line+=(source.slice(i,end).match(/\n/g)||[]).length;i=end;}else{while(i<source.length&&source[i]!=='\n')i++;}continue;}
  const start=i,startLine=line;
  if(c==='"'||c==="'"){
   const quote=c;let value='';i++;
   while(i<source.length&&source[i]!==quote){let ch=source[i++];if(ch==='\n')line++;if(ch!=='\\'){value+=ch;continue;}const next=source[i++];const escapes={a:'\x07',b:'\b',f:'\f',n:'\n',r:'\r',t:'\t',v:'\v'};
    if(next==='z'){while(i<source.length&&/\s/.test(source[i])){if(source[i]==='\n')line++;i++;}}
    else if(next==='x'&&/^[\da-f]{2}$/i.test(source.slice(i,i+2))){value+=String.fromCharCode(parseInt(source.slice(i,i+2),16));i+=2;}
    else if(/\d/.test(next)){let digits=next;while(digits.length<3&&/\d/.test(source[i]||''))digits+=source[i++];value+=String.fromCharCode(Number(digits));}
    else{value+=escapes[next]??next;if(next==='\n')line++;}
   }
   if(source[i]===quote)i++;out.push({kind:'str',value,line:startLine,start,end:i});continue;
  }
  const lm=c==='['?longStart(i):null;
  if(lm){const begin=i+lm[0].length,stop=source.indexOf(']'+lm[1]+']',begin),end=stop<0?source.length:stop+lm[1].length+2;let value=source.slice(begin,stop<0?source.length:stop).replace(/^\r?\n/,'');line+=(source.slice(i,end).match(/\n/g)||[]).length;i=end;out.push({kind:'str',value,line:startLine,start,end});continue;}
  if(c==='`'){i++;let value='';while(i<source.length&&source[i]!=='`'){if(source[i]==='\n')line++;value+=source[i++];}if(source[i]==='`')i++;out.push({kind:value.includes('{')?'template':'str',value,line:startLine,start,end:i});continue;}
  if(/[A-Za-z_\u0080-\uffff]/.test(c)){i++;while(i<source.length&&/[A-Za-z_\d\u0080-\uffff]/.test(source[i]))i++;out.push({kind:'id',value:source.slice(start,i),line,start,end:i});continue;}
  if(/\d/.test(c)){const m=source.slice(i).match(/^(?:0[xX][\da-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/);i+=m[0].length;out.push({kind:'number',value:m[0],line,start,end:i});continue;}
  const op=['...','..','==','~=','<=','>=','+=','-=','*=','/=','::','->','//'].find(s=>source.startsWith(s,i))||c;i+=op.length;out.push({kind:'punct',value:op,line,start,end:i});
 }
 return out;
}
const key=segments=>JSON.stringify(segments);
const prefix=(a,b)=>a.length<=b.length&&a.every((v,i)=>v===b[i]);
const same=(a,b)=>a.length===b.length&&prefix(a,b);
const idLike=/^[A-Za-z_][A-Za-z_\d]*$/;
const ignoredNames=new Set(['Model','Part','Union','MeshPart','Handle','RootPart','Rig','Folder','Attachment','PrimaryPart','Right','Left','Head','Torso','HumanoidRootPart','默认','Default']);
function uniquePaths(paths){const map=new Map();for(const p of paths)map.set(key(p.segments),p);return [...map.values()].slice(0,12);}
function closeAt(tokens,index){const pairs={'(':')','[':']','{':'}'};const stack=[];for(let i=index;i<tokens.length;i++){const v=tokens[i].value;if(pairs[v])stack.push(pairs[v]);else if(stack.length&&v===stack.at(-1)){stack.pop();if(!stack.length)return i;}}return index;}
function firstArg(tokens,begin,end){const args=[];let start=begin,depth=0;for(let i=begin;i<end;i++){const v=tokens[i].value;if(['(','[','{'].includes(v))depth++;if([')',']','}'].includes(v))depth--;if(v===','&&depth===0){args.push(tokens.slice(start,i));start=i+1;}}args.push(tokens.slice(start,end));return args;}
function literal(arg){if(!arg?.length)return undefined;if(arg.length===1&&(arg[0].kind==='str'||arg[0].kind==='number'))return String(arg[0].value);if(arg[0]?.value==='tostring'&&arg[1]?.value==='('&&arg[3]?.value===')'&&(arg[2]?.kind==='str'||arg[2]?.kind==='number'))return String(arg[2].value);return undefined;}

export function analyze(bundle,catalog,tagCatalog=[]){
 const assetByKey=new Map(),nodes=new Map(),assetById=new Map();
 for(const a of bundle.assets){assetById.set(a.id,a);const list=assetByKey.get(key(a.segments))??[];list.push(a);assetByKey.set(key(a.segments),list);for(let i=1;i<=a.segments.length;i++)nodes.set(key(a.segments.slice(0,i)),a.segments.slice(0,i));}
 for(const s of bundle.scripts)for(let i=1;i<=s.segments.length;i++)nodes.set(key(s.segments.slice(0,i)),s.segments.slice(0,i));
 const records=new Map(catalog.map(r=>[r.id,{id:r.id,direct:[],indirect:[],ambiguous:[],nameCandidates:[],internalCount:0,seen:new Set()}]));
 const nameIndex=new Map();
 for(const r of catalog){for(const name of new Set([r.name,r.display])){if(!name||/^\d+$/.test(name)||ignoredNames.has(name)||name.length<2||name.startsWith('[名称'))continue;const a=nameIndex.get(name)??[];a.push(r.id);nameIndex.set(name,a);}}
 const tags=new Map();for(const r of tagCatalog)for(const tag of r.tags){const a=tags.get(tag)??[];a.push(r.id);tags.set(tag,a);}
 const sources=new Map(bundle.sources.map(s=>[s.id,{...s,tokens:tokenize(s.text),lines:s.text.split('\n')}]));
 const tagEnum=new Map();
 for(const script of bundle.scripts.filter(s=>s.path.endsWith('.GameEnum')||s.path.endsWith('.CommonEnum'))){const ts=sources.get(script.sourceId).tokens;for(let i=0;i<ts.length-2;i++)if(ts[i].value==='Tag'&&ts[i+1].value==='='&&ts[i+2].value==='{'){let depth=1;for(let j=i+3;j<ts.length&&depth;j++){if(ts[j].value==='{')depth++;else if(ts[j].value==='}')depth--;if(depth===1&&ts[j].kind==='id'&&ts[j+1]?.value==='='&&ts[j+2]?.kind==='str')tagEnum.set(ts[j].value,ts[j+2].value);}}}
 let skippedBroadTraversals=0,unresolvedGlobalLookups=0;
 function add(id,kind,script,token,reason,target){const r=records.get(id);if(!r)return;if(script.owner===id){r.internalCount++;return;}const line=token?.line??0,stamp=[kind,script.path,line,reason].join('|');if(r.seen.has(stamp))return;r.seen.add(stamp);r[kind].push({script:script.path,line,enabled:script.enabled??null,sourceOwner:script.owner??null,reason,target,excerpt:line?(sources.get(script.sourceId)?.lines[line-1]??'').trim().slice(0,240):''});}
 function targets(segments){for(let i=segments.length;i>0;i--){const list=assetByKey.get(key(segments.slice(0,i)));if(list)return list;}return [];}
 function directory(paths,deep,script,token,reason){for(const p of paths){if(p.segments.length<2){skippedBroadTraversals++;continue;}for(const a of bundle.assets){if(deep?prefix(p.segments,a.segments):same(p.segments,a.segments.slice(0,-1)))add(a.id,'indirect',script,token,reason,p.segments.join('.'));}}}
 function analyzeScript(script){
  const source=sources.get(script.sourceId),ts=source.tokens;
  const aliases=new Map([['workspace',[{segments:['Workspace']}]],['Workspace',[{segments:['Workspace']}]],['game',[{segments:[]}]],['script',[{segments:script.segments}]]]);
  const assignments=[];
  for(let i=0;i<ts.length;i++)if(ts[i].kind==='id'&&ts[i-1]?.value!=='.'&&ts[i-1]?.value!==':'&&ts[i+1]?.value!=='('){let j=i+1;if(ts[j]?.value===':'){let d=0;for(;j<Math.min(i+45,ts.length);j++){if(ts[j].value==='='&&d===0)break;if(ts[j].line>ts[i].line+1)break;if(['{','(','['].includes(ts[j].value))d++;if(['}',')',']'].includes(ts[j].value))d--;}}if(ts[j]?.value==='=')assignments.push({name:ts[i].value,rhs:j+1});}
  function parse(at,emit){const first=ts[at];if(!first)return {paths:[],end:at};let paths=[];let i=at;
   if(first.value==='('){const inner=parse(at+1,emit);if(ts[inner.end]?.value===')'){paths=inner.paths;i=inner.end+1;}else return {paths:[],end:at+1};}
   else if(first.kind==='id'&&aliases.has(first.value)){const values=aliases.get(first.value);paths=values.map(p=>({...p,segments:[...p.segments],ambiguous:p.ambiguous||values.length>1}));i++;}
   else return {paths:[],end:at+1};
   while(i<ts.length&&paths.length){const t=ts[i];
    if(t.value==='.'&&ts[i+1]?.kind==='id'){const name=ts[i+1].value;if(name==='Parent')paths=paths.filter(p=>p.segments.length).map(p=>({...p,segments:p.segments.slice(0,-1)}));else paths=paths.map(p=>({...p,segments:[...p.segments,name]}));i+=2;}
    else if(t.value==='['){const end=closeAt(ts,i),child=literal(ts.slice(i+1,end));if(child===undefined){if(emit)directory(paths,false,script,t,'动态索引访问');paths=[];i=end+1;break;}paths=paths.map(p=>({...p,segments:[...p.segments,child]}));i=end+1;}
    else if(t.value===':'&&ts[i+1]?.kind==='id'&&ts[i+2]?.value==='('){const method=ts[i+1].value,end=closeAt(ts,i+2),args=firstArg(ts,i+3,end),arg=literal(args[0]);
     if(method==='GetService'&&arg!==undefined&&paths.every(p=>p.segments.length===0))paths=paths.map(p=>({...p,segments:[arg]}));
     else if(['FindFirstChild','WaitForChild'].includes(method)){
      if(arg===undefined){if(emit){directory(paths,args[1]?.[0]?.value==='true',script,t,'动态名称查找');if(paths.some(p=>p.segments.length<2))unresolvedGlobalLookups++;}paths=[];}
      else if(method==='FindFirstChild'&&args[1]?.[0]?.value==='true'){const matches=[];for(const p of paths)for(const n of nodes.values())if(prefix(p.segments,n)&&n.length>p.segments.length&&n.at(-1)===arg)matches.push({...p,segments:n,ambiguous:true});paths=uniquePaths(matches);}
      else paths=paths.map(p=>({...p,segments:[...p.segments,arg]}));
     }else if(['GetChildren','GetDescendants'].includes(method)){if(emit)directory(paths,method==='GetDescendants',script,t,method+' 目录枚举');paths=[];}
     else if(['Clone','WaitForChildWhichIsA','FindFirstChildWhichIsA','FindFirstChildOfClass'].includes(method)){if(method!=='Clone')paths=paths.map(p=>({...p,ambiguous:true}));}
     else{paths=[];}
     i=end+1;
    }else break;
    if(emit)for(const p of paths)for(const a of targets(p.segments)){const dup=assetByKey.get(key(a.segments)).length>1;add(a.id,p.ambiguous||dup?'ambiguous':'direct',script,t,dup?'同父级存在同名对象':'解析到对象路径',p.segments.join('.'));}
   }
   return {paths:uniquePaths(paths),end:i};
  }
  for(let pass=0;pass<4;pass++){let changed=false;for(const a of assignments){if(['game','workspace','Workspace','script'].includes(a.name))continue;const result=parse(a.rhs,false);if(!result.paths.length)continue;const prior=aliases.get(a.name)??[],next=uniquePaths([...prior,...result.paths]);if(JSON.stringify(prior)!==JSON.stringify(next)){aliases.set(a.name,next);changed=true;}}if(!changed)break;}
  for(let i=0;i<ts.length;i++){
   if(ts[i].kind==='id'&&aliases.has(ts[i].value)&&!['.',':'].includes(ts[i-1]?.value))parse(i,true);
   if(ts[i].kind==='str')for(const id of nameIndex.get(ts[i].value)??[])add(id,'nameCandidates',script,ts[i],'同名字符串或配置名称候选',ts[i].value);
   if(['GetTagged','GetInstanceAddedSignal','GetInstanceRemovedSignal'].includes(ts[i].value)&&ts[i+1]?.value==='('){const end=closeAt(ts,i+1),arg=firstArg(ts,i+2,end)[0];let tag=literal(arg);if(tag===undefined&&arg?.length===5&&arg[1].value==='.'&&arg[2].value==='Tag'&&arg[3].value==='.')tag=tagEnum.get(arg[4].value);if(tag!==undefined)for(const id of tags.get(tag)??[])add(id,'indirect',script,ts[i],'标签查询覆盖快照对象',tag);}
  }
 }
 for(const script of bundle.scripts)analyzeScript(script);
 for(const property of bundle.properties){const row=records.get(property.target);if(row)row.direct.push({script:property.path,line:0,enabled:null,sourceOwner:property.fromOwner??null,reason:'对象属性引用：'+property.property,target:property.targetPath,excerpt:''});}
 const results=catalog.map(asset=>{const r=records.get(asset.id);const limited=asset.rawNameHex||asset.name.startsWith('[名称含');const key=limited?'limited':r.direct.length?'direct':r.indirect.length?'indirect':r.ambiguous.length?'ambiguous':'none';const labels={limited:'匹配受限',direct:'检出静态引用',indirect:'目录/标签间接引用',ambiguous:'重名或解析候选',none:'未检出静态引用'};const evidence=(r.direct.length?r.direct:r.indirect.length?r.indirect:r.ambiguous).slice(0,5);return {id:asset.id,key,status:labels[key],noStaticReference:key==='none',directCount:r.direct.length,indirectCount:r.indirect.length,ambiguousCount:r.ambiguous.length,nameCandidateCount:r.nameCandidates.length,internalCount:r.internalCount,evidence,nameCandidates:r.nameCandidates.slice(0,3)};});
 return {version:bundle.version,scriptInstances:bundle.scripts.length,uniqueSources:bundle.sources.length,unreadable:bundle.unreadable,sourceEncodingErrors:bundle.sourceEncodingErrors,propertyReferences:bundle.properties.length,skippedBroadTraversals,unresolvedGlobalLookups,results};
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const dir=path.dirname(fileURLToPath(import.meta.url)),workspace=path.resolve(dir,'..','..');
 const chunks=(await fs.readdir(path.join(dir,'chunks'))).filter(f=>f.endsWith('.json')).sort();const parts=[];let offset=1;
 for(const file of chunks){const chunk=JSON.parse(await fs.readFile(path.join(dir,'chunks',file),'utf8'));if(chunk.first!==offset)throw new Error('Missing or overlapping source chunk '+file);parts.push(chunk.text);offset=chunk.nextOffset;}
 if(offset!==0)throw new Error('Source export is incomplete');
 const bundle=JSON.parse(parts.join(''));await fs.writeFile(path.join(dir,'source_snapshot.json'),JSON.stringify(bundle),'utf8');
 const catalog=JSON.parse(await fs.readFile(path.join(workspace,'output','局内素材分类_取证','catalog_classified_v2.json'),'utf8'));
 let tags=[];try{tags=JSON.parse(await fs.readFile(path.join(dir,'asset_tags.json'),'utf8'));}catch{}
 const result=analyze(bundle,catalog,tags);
 await fs.writeFile(path.join(dir,'reference_audit.json'),JSON.stringify(result,null,2),'utf8');
 const summary={...result,results:undefined,counts:result.results.reduce((a,r)=>{a[r.status]=(a[r.status]??0)+1;return a;},{})};
 await fs.writeFile(path.join(dir,'summary.json'),JSON.stringify(summary,null,2),'utf8');console.log(JSON.stringify(summary,null,2));
}
