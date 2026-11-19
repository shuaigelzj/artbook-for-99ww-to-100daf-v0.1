async function(ids,inspect=[]){
 for(const id of ids)if(!/^AF-\d{4}$/.test(id))throw Error("Invalid asset ID");
 const prepared=await tools.mcp__Roblox_Studio__execute_luau({studio_id:load("studioId"),datamodel_type:"Edit",code:"return _G.AFPreviewBulk.preparePool({"+ids.map(id=>"'"+id+"'").join(",")+"})"});
 if(prepared.isError)throw Error(JSON.stringify(prepared));
 const records=JSON.parse(prepared.content.find(c=>c.type==="text").text);store("poolRecords",records);text({prepared:records.length,first:ids[0],last:ids.at(-1)});
 await(eval("("+load("poolCaptureFn")+")"))(records,inspect);
 const spec=load('bulkSpec');
 const check=await tools.exec_command({cmd:"& 'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe' 'output/资产图示_全量/verify-images.py' 'output/"+spec.directory+"'",max_output_tokens:1200});
 text(check.output);if(check.exit_code!==0)throw Error('White or invalid frame detected; stop capturing and quarantine failures before resuming.');
}
