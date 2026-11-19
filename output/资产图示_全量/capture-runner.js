async function(ids,inspect=[]){
 const ascii=x=>JSON.stringify(x).replace(/[\u007f-\uffff]/g,c=>"\\u"+c.charCodeAt(0).toString(16).padStart(4,"0"));
 const save=async(rec,im)=>{
  rec.file="images/"+rec.id+".jpg";rec.mimeType=im.mimeType;
  const meta=`var afNewRecord=${ascii(rec)};var afIndex=afCaptureRows.findIndex(r=>r.id===afNewRecord.id);if(afIndex<0)afCaptureRows.push(afNewRecord);else afCaptureRows[afIndex]=afNewRecord;await afFs.writeFile(afRoot+'/capture-records.json',JSON.stringify(afCaptureRows,null,2),'utf8');`;
  const chunkSize=Math.min(48000,Math.floor((56000-meta.length-600)/4)*4);if(chunkSize<4000)throw Error("Metadata too large");
  for(let o=0;o<im.data.length;o+=chunkSize){
   const last=o+chunkSize>=im.data.length;
   const result=await tools.mcp__node_repl__js({code:`await afFs.${o===0?'writeFile':'appendFile'}(afRoot+'/images/${rec.id}.jpg',Buffer.from(${JSON.stringify(im.data.slice(o,o+chunkSize))},'base64'));${last?meta:''}nodeRepl.write({saved:'${rec.id}',complete:${last}});`,title:"保存 Studio 资产配图"});
   if(result.isError)throw Error(JSON.stringify(result));
  }
  const records=load("bulkRecords")??[];const i=records.findIndex(r=>r.id===rec.id);if(i<0)records.push(rec);else records[i]=rec;store("bulkRecords",records);
  text({saved:rec.id,method:rec.method,batchCompleted:records.length});
 };
 let pending=null;
 try{
  for(const id of ids){
   if(!/^AF-\d{4}$/.test(id))throw Error("Invalid asset ID");
   const results=await Promise.allSettled([pending??Promise.resolve(),tools.mcp__Roblox_Studio__execute_luau({studio_id:load("studioId"),datamodel_type:"Edit",code:`return _G.AFPreviewBulk.render('${id}')`})]);
   pending=null;for(const r of results)if(r.status!=="fulfilled")throw r.reason;
   const rendered=results[1].value;if(rendered.isError)throw Error(JSON.stringify(rendered));
   const rec=JSON.parse(rendered.content.find(c=>c.type==="text").text);
   if(rec.renderMode==='Studio ViewportFrame'){
    const warm=await tools.mcp__Roblox_Studio__screen_capture({studio_id:load('studioId'),capture_id:id.replace('-','_')+'_warmup'});
    if(warm.isError)throw Error(JSON.stringify(warm));
   }
   const cap=await tools.mcp__Roblox_Studio__screen_capture({studio_id:load("studioId"),capture_id:id.replace("-","_")+"_bulk"});
   if(cap.isError)throw Error(JSON.stringify(cap));const im=cap.content.find(c=>c.type==="image");if(!im)throw Error("No image "+id);
   if(im.mimeType!=="image/jpeg")throw Error("Unexpected image format "+im.mimeType);
   store("bulkLastCapture",{rec,data:im.data});if(inspect.includes(id))image(im);
   pending=save(rec,im);
  }
 }finally{if(pending)await pending;}
 text({batch:load("bulkSpec")?.id,completed:load("bulkRecords")?.length,last:ids.at(-1)});
}
