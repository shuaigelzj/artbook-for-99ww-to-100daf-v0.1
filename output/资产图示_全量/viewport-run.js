async function(ids,inspect=[]){
 await(eval('('+load('captureFn')+')'))(ids,inspect);
 const spec=load('bulkSpec');
 const check=await tools.exec_command({cmd:"& 'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe' 'output/资产图示_全量/verify-images.py' 'output/"+spec.directory+"'",max_output_tokens:1200});
 text(check.output);if(check.exit_code!==0)throw Error('Invalid or white capture detected.');
 const completed=spec.start+load('bulkRecords').length;
 const progress={completed,total:905,lastCompleted:'AF-'+String(completed).padStart(4,'0'),next:completed<905?'AF-'+String(completed+1).padStart(4,'0'):null,currentBatch:spec.id,studioClean:false,renderMode:'Studio ViewportFrame fallback'};
 const saved=await tools.mcp__node_repl__js({code:"await afFs.writeFile('C:/Users/Leung/vwork/Roblox_100_Days_After_Fall/output/资产图示_全量/progress.json',"+JSON.stringify(JSON.stringify(progress,null,2))+");nodeRepl.write({completed:"+completed+"});",title:'保存续拍进度'});if(saved.isError)throw Error(JSON.stringify(saved));
}
