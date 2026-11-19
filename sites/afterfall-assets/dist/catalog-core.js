(function(global){
 'use strict';
 const normalize=value=>String(value??'').normalize('NFKC').toLocaleLowerCase();
 const text=row=>normalize([row.id,row.display,row.name,row.path,row.locator,row.role,row.materialType,row.entry,row.roleBasis,row.roleNote,row.notes,row.theme,row.referenceAudit?.status,row.referenceAudit?.noStaticReference?'无引用':'',row.reskin?.decision,row.reskin?.workflow,row.reskin?.subject,row.reskin?.unit,row.reskin?.reason,row.reskin?.plan?.join(' '),row.reskin?.companions?.map(c=>c.id+' '+c.name).join(' ')].join(' '));
 const hasUse=row=>row.observedGenerationRuns.length>0||row.role==='直接使用的玩法场景'||row.role==='过场与演出场景';
 function evidence(row){if(hasUse(row))return {key:'used',label:'有使用证据',secondary:row.observedGenerationRuns.length?`生成命中 ${row.observedGenerationRuns.length}/5 轮`:'脚本引用与运行确认'};if(row.retainedRuns.length)return {key:'retained',label:'运行态保留',secondary:`保留 ${row.retainedRuns.length}/5 轮`};return {key:'unobserved',label:'本轮未观察到',secondary:'目录或结构线索见详情'};}
 function filter(rows,state){
  const query=normalize(state.q).trim(),tokens=query.split(/\s+/).filter(Boolean),exactId=/^af-\d{4}$/.test(query);
  const matches=(r,t)=>/^配套[:：]af-\d{4}$/.test(t)?r.reskin?.companions?.some(c=>normalize(c.id)===t.slice(3)):text(r).includes(t);
  return rows.filter(r=>(!state.role||r.role===state.role)&&(!state.type||r.materialType===state.type)&&(!state.source||(state.source==='inside'?r.source==='预设库':r.source!=='预设库'))&&(!state.evidence||evidence(r).key===state.evidence)&&(!state.reskin||r.reskin?.decisionKey===state.reskin)&&(exactId?normalize(r.id)===query:tokens.every(t=>matches(r,t)))).sort((a,b)=>state.sort==='parts'?b.parts-a.parts||a.index-b.index:state.sort==='name'?a.display.localeCompare(b.display,'zh-Hans-CN')||a.index-b.index:a.index-b.index);
 }
 function page(rows,page,size){const totalPages=Math.max(1,Math.ceil(rows.length/size));const current=Math.max(1,Math.min(Number(page)||1,totalPages));const start=(current-1)*size;return {rows:rows.slice(start,start+size),page:current,totalPages,start:rows.length?start+1:0,end:Math.min(start+size,rows.length),total:rows.length};}
 global.AssetCatalogCore={normalize,filter,page,evidence,hasUse};
})(typeof window!=='undefined'?window:globalThis);
