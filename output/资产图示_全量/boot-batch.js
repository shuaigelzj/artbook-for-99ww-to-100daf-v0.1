async function(batchId){
 const plan=load("bulkPlan"),spec=plan.find(s=>s.id===String(batchId));if(!spec)throw Error("Unknown batch");
 const js=`const fs=require('fs');const spec=${JSON.stringify(spec)};const map=new Map(JSON.parse(fs.readFileSync('output/资产图示_全量/live-locators-20261119.json','utf8')).matches.map(x=>[x.id,x]));const c=JSON.parse(fs.readFileSync('output/局内素材分类_取证/catalog_classified_v2.json','utf8'));const rows=c.slice(spec.start,spec.end).map(({id,name,path,locator,parts,class:cl,materialType,rawNameHex})=>({id,name,path,originalLocator:locator,locator:map.get(id).locator,parts,class:cl,materialType,rawNameHex}));fs.writeFileSync('output/'+spec.directory+'/source-rows-20261119.json',JSON.stringify(rows,null,2));console.log(JSON.stringify(rows));`;
 const result=await tools.exec_command({cmd:"@'\n"+js+"\n'@ | node",max_output_tokens:18000});if(result.exit_code!==0)throw Error(result.output);const rows=JSON.parse(result.output);
 store("bulkRows",rows);store("bulkSpec",spec);store("bulkRecords",[]);
 const files=load("bulkLuaFiles"),payload=JSON.stringify(rows);let eq="==";while(payload.includes("]"+eq+"]"))eq+="=";
 const s=await tools.mcp__Roblox_Studio__execute_luau({studio_id:load("studioId"),datamodel_type:"Edit",code:`local AF_PREVIEW_ROWS=game:GetService('HttpService'):JSONDecode([${eq}[${payload}]${eq}])\n`+files.setup});if(s.isError)throw Error(JSON.stringify(s));
 for(const n of ["render","adapters",...(files.viewport?["viewport"]:[]),"pool",...(files.vpool?["vpool"]:[])]){const a=await tools.mcp__Roblox_Studio__execute_luau({studio_id:load("studioId"),datamodel_type:"Edit",code:files[n]});if(a.isError)throw Error(n+": "+JSON.stringify(a));}
 const node=await tools.mcp__node_repl__js({code:"var afRoot="+JSON.stringify("C:/Users/Leung/vwork/Roblox_100_Days_After_Fall/output/"+spec.directory)+";var afCaptureRows=[];nodeRepl.write({ready:"+batchId+"});",title:"准备下一批资产图示"});if(node.isError)throw Error(JSON.stringify(node));
 text({batch:batchId,first:rows[0].id,last:rows.at(-1).id,ready:true});return rows;
}
