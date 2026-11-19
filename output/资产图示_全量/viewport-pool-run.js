async function(ids,inspect=[]){
 const r=await tools.mcp__Roblox_Studio__execute_luau({studio_id:load("studioId"),datamodel_type:"Edit",code:"return _G.AFPreviewBulk.prepareViewportPool({"+ids.map(x=>"'"+x+"'").join(",")+"})"});
 if(r.isError)throw Error(JSON.stringify(r));const rec=JSON.parse(r.content.find(x=>x.type==="text").text);text({prepared:rec.length,first:ids[0],last:ids.at(-1)});
 await(eval("("+load("viewportPoolCaptureFn")+")"))(rec,inspect);
 const spec=load("bulkSpec");const qa=await tools.exec_command({cmd:"& 'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe' 'output/资产图示_全量/verify-images.py' 'output/"+spec.directory+"'",max_output_tokens:1000});text(qa.output);if(qa.exit_code!==0)throw Error("Invalid capture");
}