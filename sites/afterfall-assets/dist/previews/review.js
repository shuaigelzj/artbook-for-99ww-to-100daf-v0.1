(()=>{
 'use strict';
 const $=id=>document.getElementById(id);
 const rows=window.AF_CATALOG.rows.filter(r=>r.preview).sort((a,b)=>a.index-b.index);
 const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const kind=m=>m==='辅助可视化'?'aux':m==='说明卡'?'empty':'';
 const requested=new URLSearchParams(location.search).get('batch');
 const summary=window.AF_CATALOG.previewSummary; const batchIds=new Set(summary.batches.map(b=>b.id)); $('batch').innerHTML=[...summary.batches].reverse().map(b=>`<option value="${b.id}">${esc(b.label)} · ${b.first}～${b.last}</option>`).join('')+`<option value="">全部 · ${rows.length} 条</option>`; $('batch').value=requested==='50'?'1':requested==='all'?'':batchIds.has(requested)?requested:summary.latestBatch; $('generation-state').textContent=summary.complete?'全量完成 · 可审查':'持续生成中'; $('preview-range').textContent='AFTER FALL / STUDIO PREVIEWS / 0001–'+summary.last.slice(3); $('preview-progress').textContent=`已完成 AF-0001 至 ${summary.last}，共 ${summary.count} / ${summary.total} 条。${summary.complete?'全部资产已有图示。':`余下 ${summary.total-summary.count} 条正在分批生成。`}`;
 const image=p=>'../'+p.image;
 let current=null,navigation=[],active=-1;
 const counts=rows.reduce((a,r)=>(a[r.preview.method]=(a[r.preview.method]||0)+1,a),{});
 $('total').textContent=rows.length; $('method').innerHTML='<option value="">全部方式</option>'+Object.keys(counts).map(k=>`<option value="${esc(k)}">${esc(k)}</option>`).join('');
 $('methods').textContent=Object.entries(counts).map(([k,v])=>`${k} ${v}`).join(' · ');
 function batchRows(){return rows.filter(r=>!$('batch').value||r.preview.batch===$('batch').value);}
 function render(){
  const q=$('search').value.normalize('NFKC').toLocaleLowerCase().trim(),method=$('method').value,group=batchRows();
  const filtered=group.filter(r=>(!method||r.preview.method===method)&&[r.id,r.name,r.path].join(' ').normalize('NFKC').toLocaleLowerCase().includes(q));
  $('count').textContent=`${filtered.length} / ${group.length} 条`;
  $('empty').hidden=filtered.length>0;
  $('gallery').innerHTML=filtered.map(r=>`<article class="card" data-id="${r.id}"><button class="photo" data-open="${r.id}" aria-label="放大 ${esc(r.id+' '+r.name)}"><img src="${image(r.preview)}" alt="${esc(r.name+' · '+r.preview.method)}" loading="lazy" width="788" height="392"></button><div class="card-copy"><div class="card-top"><span class="id">${r.id}</span><span class="badge ${kind(r.preview.method)}">${r.preview.method}</span></div><h2>${esc(r.name)}</h2><p>${esc(r.role)} · ${esc(r.materialType)} · 第 ${r.preview.batch} 批</p><span class="path">${esc(r.path)}</span></div></article>`).join('');
 }
 function showView(index){
  const p=current.preview,view=index<0?{image:p.image,label:'主图',note:p.note}:p.views[index];
  if(!view)return;
  $('viewer-image').src=image(view);$('viewer-image').alt=current.name+' · '+view.label;$('viewer-note').textContent=view.note;
  for(const button of $('views').querySelectorAll('button'))button.classList.toggle('selected',Number(button.dataset.view)===index);
 }
 function open(id){
  current=rows.find(r=>r.id===id);if(!current)return;
  if($('batch').value&&current.preview.batch!==$('batch').value){$('batch').value=current.preview.batch;render();}
  navigation=batchRows();active=navigation.findIndex(r=>r.id===id);
  $('viewer-title').textContent=current.id+'  '+current.name;
  $('viewer-method').className='badge '+kind(current.preview.method);$('viewer-method').textContent=current.preview.method;
  $('viewer-path').textContent=current.path;$('record-link').href='../index.html#asset='+current.id;
  $('position').textContent=`${active+1} / ${navigation.length}`;$('previous').disabled=active===0;$('next').disabled=active===navigation.length-1;
  $('views').innerHTML=current.preview.views?.length?'<button data-view="-1">主图</button>'+current.preview.views.map((v,i)=>`<button data-view="${i}">${esc(v.label)}</button>`).join(''):'';
  showView(-1);if(!$('viewer').open)$('viewer').showModal();
  history.replaceState(null,'',location.pathname+location.search+'#asset='+current.id);
 }
 function close(){$('viewer').close();history.replaceState(null,'',location.pathname+location.search);}
 function restore(){const id=new URLSearchParams(location.hash.slice(1)).get('asset');if(id)open(id);else if($('viewer').open)$('viewer').close();}
 $('search').addEventListener('input',render);$('method').addEventListener('change',render);
 $('batch').addEventListener('change',()=>{render();history.replaceState(null,'',location.pathname+'?batch='+($('batch').value||'all'));});
 $('gallery').addEventListener('click',e=>{const b=e.target.closest('[data-open]');if(b)open(b.dataset.open);});
 $('views').addEventListener('click',e=>{const b=e.target.closest('[data-view]');if(b)showView(Number(b.dataset.view));});
 $('close').addEventListener('click',close);$('viewer').addEventListener('cancel',e=>{e.preventDefault();close();});
 $('viewer').addEventListener('click',e=>{if(e.target===$('viewer')){const r=e.target.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)close();}});
 $('previous').addEventListener('click',()=>{if(active>0)open(navigation[active-1].id);});$('next').addEventListener('click',()=>{if(active<navigation.length-1)open(navigation[active+1].id);});
 document.addEventListener('keydown',e=>{if(!$('viewer').open)return;if(e.key==='ArrowRight'&&active<navigation.length-1){e.preventDefault();open(navigation[active+1].id);}if(e.key==='ArrowLeft'&&active>0){e.preventDefault();open(navigation[active-1].id);}});
 window.addEventListener('hashchange',restore);render();restore();
})();
