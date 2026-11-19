import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
import reviewed from './reviewed-visuals.mjs';
const root=path.dirname(fileURLToPath(import.meta.url)),workspace=path.resolve(root,'../..');
const rows=JSON.parse(await fs.readFile(path.join(workspace,'output/局内素材分类_取证/catalog_classified_v2.json'),'utf8'));
const structures=JSON.parse(await fs.readFile(path.join(root,'structure.json'),'utf8'));
const facts=new Map(structures.map(x=>[x.id,x])),catalog=new Map(rows.map(x=>[x.id,x]));
const preview=JSON.parse(await fs.readFile(path.join(workspace,'sites/afterfall-assets/preview-manifest.json'),'utf8'));
const photos=new Map(preview.previews.map(x=>[x.id,x]));
const config=JSON.parse(await fs.readFile(path.join(workspace,'output/局内素材分类_取证/config_parsed.json'),'utf8'));
const resourceConfig=new Map(config.ResourcesItemSetting.map(r=>[Number(r.id),r]));
const resourceAssets=new Map(rows.filter(r=>r.path.startsWith('Workspace.Prefabs.Resources.')&&/^\d+$/.test(r.name)).map(r=>[Number(r.name),r]));
const id=n=>typeof n==='number'?'AF-'+String(n).padStart(4,'0'):n;
const nums=s=>s.split(',').flatMap(t=>{const [a,b]=t.split('-').map(Number);return Array.from({length:(b??a)-a+1},(_,i)=>a+i);});
const member=(r,s)=>nums(s).includes(r.index);
const labels={direct:'是',prepare:'否',verify:'待确认',none:'不适用'};
const routes={prop:'单体整件',weapon:'完整武器',building:'完整建筑',creature:'完整角色',tree:'景观单体',hat:'单件头饰',sign:'实体与牌面',tile:'地块铺排',overlay:'地表叠层',vegetation:'植被铺排',landform:'地形组装',module:'模块装配',assembly:'零件装配',wearable:'角色试穿',face:'面部装配',saddle:'骑乘试装',state:'状态演示',ui:'界面版式',effect:'特效演示',scene:'场景分镜',collection:'集合拆分',logic:'逻辑保留',prototype:'原型补齐',empty:'空对象保留',unknown:'用途与宿主确认',banner:'悬挂装配',boundary:'边界景观',controller:'控制器配套',farm:'种植状态板',terrain:'地形测试场',template:'占地约束'};
const directProfiles=new Set(['prop','weapon','building','creature','tree','hat','sign']);
function choose(r,f,p){
 if(reviewed[r.id])return {...reviewed[r.id]};
 const text=[r.name,r.display,r.path,r.subcategory].join(' ');
 if(member(r,'433,434,441'))return {profile:'prop',subject:r.display+' 平面图标',uiIcon:true};
 if(member(r,'435-440,150,577,578,820,905'))return {profile:'ui',subject:r.display+' 界面/提示'};
 if(r.id==='AF-0648')return {profile:'effect',subject:'潮湿木材 Highlight 效果',companions:[221,264],note:'WeatherService 将露天木材移入 WetModel；原结构只有 Highlight，没有自身造型。'};
 if(r.id==='AF-0663')return {profile:'terrain',subject:'Terrain 全局容器',note:'前次图示取证 CountCells=0；目前没有现成体素地形表面供单体改图。'};
 if(r.id==='AF-0598')return {profile:'collection',subject:'Effects 特效库',note:'实际结构含 80 个 ParticleEmitter、11 个 Beam 和 6 个 Trail；库是多效果集合。',companions:[158,267,278]};
 if(r.id==='AF-0601')return {profile:'collection',subject:'Others 混合资源包',note:'包含虫洞入口/出口、雪球、拖拽物、塔防中心等，不能视为同一个完整物品。',companions:[157,230,294]};
 if(r.parts===0)return {profile:'empty',subject:r.display,companions:r.id==='AF-0001'?[762]:[]};
 if(/地块|Grassland/.test(text))return {profile:'tile',subject:r.display,note:f.visibleParts===0?'默认地块完全透明；组合时标出透明/留空范围，保留原可见性和废弃标记，不默认补成实体地面。':''};
 if(member(r,'49-53'))return {profile:'template',subject:r.display+' 占地样板'};
 if(member(r,'559,572,645,580,596,597'))return {profile:'logic',subject:r.display,note:r.roleNote};
 if(r.id==='AF-0418')return {profile:'prototype',subject:'移动机器人的控制壳',note:'只含透明 RootPart、ControllerManager 与传感/运动控制节点，没有默认可见机器人外壳。',companions:[416,419]};
 if(f.visibleParts===0){
  if(r.role==='系统辅助与表现对象'||/RootPart|Position|位置|出生点/.test(text))return {profile:'logic',subject:r.display};
  return {profile:'prototype',subject:r.display,uncertain:true,note:'原件默认全透明，当前图示使用辅助可视化；真实显示状态与宿主尚未确认。'};
 }
 if(r.id==='AF-0025')return {profile:'controller',subject:'宝石塔事件控制/奖励组件',companions:[24],note:'顶层含刷怪点、奖励点、CDPart、TriggerPart 与 RootPart，虽然有可见件，也不是独立整塔。'};
 if(r.id==='AF-0147')return {profile:'boundary',subject:'地图边界墙与土丘',companions:[32,47]};
 if(r.id==='AF-0899')return {profile:'scene',subject:'CamSetting 过场场景',companions:[511,407,469],note:'包含 2497 个 BasePart、角色、火车、环境与镜头点；影片脚本直接读取并移动场景。'};
 if(member(r,'24,133,135-137,414,510,511,557,560-563,568-571,573,574,603'))return {profile:'scene',subject:r.display};
 if(/控制器/.test(text))return {profile:'controller',subject:r.display};
 if(/地块|Grassland/.test(text))return {profile:'tile',subject:r.display};
 if(/雪块|雪覆盖|雪山地形部件|地表装饰/.test(r.subcategory)||/BOSS雪|牛牛战败雪/.test(r.name))return {profile:'overlay',subject:r.display};
 if(/草|灌木|Cloud/.test(r.subcategory)||r.name==='Cloud')return {profile:'vegetation',subject:r.display};
 if(/树/.test(r.subcategory))return {profile:'tree',subject:r.display};
 if(/武器零件/.test(r.subcategory))return {profile:'assembly',subject:r.display,companions:[186,200,276,242],note:'ResourcesItemSetting 明确区分 Iron Verdict 枪托、枪身、枪管和完整步枪。'};
 if(/铁路部件/.test(r.subcategory))return {profile:'module',subject:r.display,companions:[38,39,511]};
 if(/积雪覆盖/.test(r.subcategory))return {profile:'overlay',subject:r.display};
 if(/工坊管道|机械零件/.test(r.subcategory))return {profile:'assembly',subject:r.display,companions:[503,89,674],note:'按文件名和形状属于机械配件线索；最终装配位置需与原宿主逐件比对。'};
 if(/护甲|围巾|鞋靴|面罩|敌人阶段配饰|职业配饰|马头饰/.test(r.subcategory))return {profile:'wearable',subject:r.display};
 if(r.subcategory==='大型怪物配饰')return {profile:'hat',subject:r.display,companions:[416]};
 if(r.class==='Accessory'||/职业头饰|头饰模型样本|节日服饰/.test(r.subcategory))return {profile:'hat',subject:r.display};
 if(f.classes.Humanoid||f.classes.AnimationController||/人形角色|怪物与Boss|动物与坐骑/.test(r.materialType))return {profile:'creature',subject:r.display};
 if(/Farm Plot/.test(r.display))return {profile:'farm',subject:r.display,companions:[226,223,252]};
 if(/Wall|Wire|Abatis|Sheet|Door|双开门|围栏|门部件|梯子/.test(text)&&r.class!=='Tool')return {profile:'module',subject:r.display};
 if(r.materialType==='武器工具'||r.class==='Tool')return {profile:'weapon',subject:r.display};
 if(r.materialType==='资源与食物')return {profile:'prop',subject:r.display};
 if(/场景部件/.test(r.subcategory))return {profile:'module',subject:r.display};
 if(r.materialType==='建筑场景')return {profile:'building',subject:r.display};
 if(r.materialType==='营地设施'||r.materialType==='机关')return {profile:'prop',subject:r.display};
 if(r.materialType==='地形植被')return {profile:'prop',subject:r.display};
 return {profile:'unknown',subject:r.display,note:'现有名称、结构和引用线索不足以确认完整设计单元。'};
}
function dimensions(r){return r.size?.length===3?r.size.map(n=>Number(n.toFixed(2))).join(' × ')+' studs':'原对象实际包围盒';}
function companionIds(r,c){
 if(c.companions?.length)return c.companions;
 switch(c.profile){
 case 'tile':return /铁轨/.test(r.name)?[38,39,47]:/雪/.test(r.path)?[40,43,44,547]:/沼泽/.test(r.path)||/沼泽/.test(r.name)?[29,34,35,496]:[32,33,47,18];
 case 'overlay':case 'vegetation':case 'landform':return /雪/.test(r.path)||/雪/.test(r.name)?[40,43,561,547]:/沼泽/.test(r.path)?[35,496,488]:[47,18,78,493];
 case 'wearable':return /小牛2阶段/.test(r.path)?[363,353,354,355]:/头饰皮肤|驯鹿/.test(r.subcategory)?[469,474]:[761,668];
 case 'hat':case 'face':return [761,668];
 case 'module':return /Sheet/.test(r.display)?[511,330,319]:/梯子|ladder/i.test(r.subcategory+' '+r.name)?[333,599,316]:[318,332,60];
 case 'building':return [47,51];
 case 'creature':return /^Mounted/.test(r.name)?[469,407,377]:/小牛/.test(r.name)?[376,363,353,355]:[];
 case 'farm':return [226,223,252];
 case 'controller':return /雪山/.test(r.name)?[557,560,561,562,563]:/圣诞/.test(r.name)?[568,569,571]:[];
 case 'ui':return /Health|Die|驯服/.test(r.name)?[761,469]:/Store|ItemDesc/.test(r.name)?[595,263]:[761];
 case 'banner':return [150,619];
 default:return [];
 }
}
function plans(r,f,c){
 const s=c.subject,d=dimensions(r),key=c.profile;
 if(c.uiIcon)return {key:'direct',unit:'独立图标/徽记',reason:'原有图示已经提供完整平面图形，可以直接作为换皮设计底图。',steps:[`以「${s}」原图保持透明边界、长宽比和识别轮廓，生成新风格图标。`,'补一张挂到原 BillboardGui 宿主上的尺度/明暗对照；这张用于校验，不改变单体出图判定。','把新图形作为独立贴图接回原控件，保留布局、数据绑定与交互。']};
 switch(key){
 case 'tile':return {key:'prepare',unit:'5 × 5 地块样区与接缝板',reason:`${s} 是铺排系统中的地块，孤立 ${d} 主图不表达重复、邻接和高差。`,steps:[`在隔离展示区按当前 50-stud 小格规则搭 5 × 5 样区，以「${s}」为主样；事件/池塘地块只在中心放一份，外围配相邻普通地块。`,'沿用原合法旋转和地表高度，地块按四个 90° 朝向测试；拍俯视、45°整体、边缘接缝与高差近景。','基于样区图生成整套地表效果，再拆回对应单格顶面、侧面、覆盖层与装饰；保留格宽、原格类型和脚本/标签锚点。']};
 case 'terrain':return {key:'prepare',unit:'地形材质/高差测试场',reason:'全局 Terrain 是系统容器，空容器截图不包含可替换的独立模型造型。',steps:['先确认新主题继续使用体素 Terrain，还是由现有 Part 地块承担地表；两条路线分别记录。','若使用 Terrain，在可还原测试区建立约 250 × 250 studs 的高差、坡面、水边和材质过渡样区；用统一高度基准拍整体及接缝。','由样区效果确定材质/色调后回填地形参数，保留水位、碰撞与角色通行；不替换 Terrain 容器实例本身。']};
 case 'overlay':return {key:'prepare',unit:'宿主地面＋覆盖层',reason:`「${s}」只是地表/积雪覆盖层，孤立轮廓无法说明附着高度、穿插与过渡。`,steps:[`把「${s}」副本按原局部坐标放回对应雪山、屋顶或地块；先核对宿主，保留覆盖前后两套图。`,'以 3 × 3 相邻区域或完整宿主构成展示单元，拍俯视、斜视及覆盖边缘，检查边缘厚度与纹理尺度。','按组合效果生成新覆盖层，再单独导出覆盖网格/贴图；保留碰撞、隐藏状态与宿主空间关系。']};
 case 'vegetation':return {key:'prepare',unit:'地面＋植被密度样区',reason:`${s} 的视觉依赖地面、密度或生长状态，单件图不能约束整片环境的比例。`,steps:[`将「${s}」按原尺度分布到 5 × 5 地块样区，配置稀疏、常规、密集三小区；植株类补空地/成熟/收获状态。`,'加入同区域树、石或建筑作尺度参照，拍玩家视高和俯视；保留原落点、可通行区与生长中心。','按样区风格回拆植被簇/贴片/植株与材质，保留分布规则，避免把连续地表做成一个不可复用的大模型。']};
 case 'landform':return {key:'prepare',unit:'尖锥簇＋地形宿主',reason:'单个尖锥只是景观构件，缺少朝向、簇间距和地表接合的约束。',steps:[`先确认「${s}」是冰棱、山体或装饰尖锥，按原局部坐标装回宿主；用途未核实时建立注明为建议的地形测试簇。`,'做单簇、与地面相交及相邻簇三张比例图，再生成同主题景观效果。','回拆单件网格与材料，保持原轴向、尖端/根部位置、碰撞与布置密度。']};
 case 'module':return {key:'prepare',unit:'完整连接组件/安装样板',reason:`${s} 是局部连接模块，需要看到接缝、端点或承载结构才能约束换皮。`,steps:[`克隆「${s}」并与原宿主分组：墙板做直段＋转角＋门洞；梯段接上下平台；铁路接连续轨与出入口；车甲装到原车厢。`,'模块按原尺度、Pivot 和连接面组装，不做破坏节点的布尔合并；拍完整组件、接合近景及必要的开关状态。','用完整组件图生成新主题，再回拆每段/门扇/轨道/护板，保持连接尺寸、旋转轴和原控制节点。']};
 case 'assembly':return {key:'prepare',unit:'宿主整机＋拆件对照',reason:`「${s}」是零件或未完成工程包装的组装件，当前图不能代表可替换的完整宿主。`,steps:[`先从原配置、父级和图示对照确定「${s}」的宿主；Iron Verdict 零件与 AF-0242 整枪对照，其他候选配套需逐件验证。`,'把原部件副本按局部 CFrame 装入临时完整组件，保留单件分组；拍装配整体、侧视和标注本件范围的拆分图。','基于整体效果设计后回拆本件，保留原接口/端点/挂点；外观样本若不是 Tool，接回正式 Tool 时保留 Handle 与握持结构。']};
 case 'wearable':case 'face':case 'saddle':{
  const host=key==='face'?'原脸部和头部':key==='saddle'?'原马背、骑手与骑乘位':'与原对象 Rig 类型和身材相符的完整角色';
  return {key:'prepare',unit:key==='face'?'头部＋成对面部件':key==='saddle'?'坐骑＋马鞍＋骑手':'整套试穿角色',reason:`${s} 的位置、贴合或左右配对依赖${host}，悬空零件图无法验证。`,steps:[`把「${s}」按原 Attachment/局部坐标装到${host}；成对部件与同系列护甲同步装入。`,'拍正、侧、背及活动姿态，给本条资产加独立分件标记；检查遮挡、穿插、关节活动和视角识别。','生成完整穿戴/骑乘效果后单独回拆本配件，保留 Attachment 名称与相对变换、左右归属及原碰撞/骑乘点。']};}
 case 'state':return {key:'prepare',unit:'同机位多状态板',reason:`${s} 含需共同表达的显示/激活/生长状态，单个静态姿态不能约束状态切换后的效果。`,steps:[`整理「${s}」已有控制值和子组件，在隔离演示载体中明确默认、激活/成熟、结束/损坏等实际存在的状态；不虚构不存在的状态。`,'固定相机和比例，各状态分别截图，并保留零件/效果归属；必要时补角色或安装环境作参照。','按整套状态板生成换皮效果，分别回填实体外壳、材质与特效，保持原状态字段和切换时序。']};
 case 'farm':return {key:'prepare',unit:'农田＋作物生长板',reason:'空农田沟槽不表达种植后的主要视觉，应把土地、种植点和作物一起设计。',steps:[`以「${s}」的实际种植槽位放入原脚本支持的作物，制作空地、种下、成熟三种布局；表中蔬果只是建议比例参考。`,'在小块营地地面上拍俯视及玩家视高，标出槽位、收获交互和周边通行范围。','生成完整种植设施效果后拆回土地、作物及交互表现，保持产物配置、收获点和生长时序。']};
 case 'ui':return {key:'prepare',unit:'真实内容版式/宿主状态板',reason:`${s} 受数据、宿主和排版空间约束，默认标签或孤立载体不是最终换皮效果。`,steps:[`提取「${s}」原控件与锚点，填入真实长度的示例文字/图标；血条、冷却、驯服等按现有逻辑做满/中/空或对应实际状态。`,'做固定像素画板，并在实际角色、商人、道具或场景标签上挂回展示；拍原比例和缩小可读性对照。','按版式出图后分离背景、图标、字体和可伸缩条，保留控件名、AnchorPoint、Size/Position、宿主和数据绑定。']};
 case 'effect':return {key:'prepare',unit:'实体载体＋效果时序板',reason:'资产主要是效果参数或光束/轮廓组件，缺少可独立替换的静态实体主体。',steps:[`把「${s}」挂回实际载体或注明为建议的标准载体：光束连接两端 Attachment；Highlight 附着原木材/角色；拖尾提供运动路径。`,'在支持相应效果的原生场景或运行态演示区，以同机位采集启动、峰值和消散；补暗/亮背景对照，静态视窗只作结构参考。','根据效果板制作贴图/材质/颜色与时间曲线，保留 Attachment、Adornee、发射与生命周期/触发逻辑。']};
 case 'scene':return {key:'prepare',unit:'整体总览＋子组件/镜头套图',reason:`${s} 是复合空间/演出单元，一张远景不足以约束内部组件与可玩空间的替换。`,steps:[`保持「${s}」原地面、坐标与锚点，按建筑/街区/车厢/洞穴内外或影片镜头分组；已有洞穴内外附图可以直接作首组参考。`,'先拍完整总览，再对每个实际子场景拍玩家视高和关键侧视；标出入口、通道、刷怪/奖励点、门轴或镜头点。','以套图确定统一主题，按原层级逐组替换美术并回装总场景；保留通行空间、占地、事件挂点与镜头轨迹。']};
 case 'collection':return {key:'prepare',unit:'按子对象拆分的制图任务',reason:`${s} 是多种资源/模板的集合，不能作为一个物体生成并替换。`,steps:[`先按「${s}」实际顶层子对象列子任务，区分完整实体、UI、特效和逻辑点，记录每个子对象的路径。`,'完整实体单独取图；特效放回对应载体并做时序板；面板/零件先恢复组件关系；保持相同主题色和尺度参照。','分别生成并回填各子资源，再回到集合检查命名、配置入口和组合效果；保留容器本身与控制结构。']};
 case 'banner':return {key:'prepare',unit:'旗面/灯带＋悬挂结构',reason:`${s} 的设计依赖悬挂跨度、朝向、正反面及场景比例。`,steps:[`把「${s}」放到原旗杆、屋檐或跨度支架上，保留原局部坐标；缺少宿主时明确标为建议演示。`,'分别拍整体、正反平面及发光前后（若有光源）；对灯带核对灯泡间距，对旗帜核对图形朝向。','生成整体装饰效果后拆回旗面贴图、灯带网格/材质，保留悬挂点、跨度和可读性。']};
 case 'boundary':return {key:'prepare',unit:'地面＋边界完整剖段',reason:'空气墙与可见土丘混在同一边界资产里，碰撞边界和美术轮廓必须分开。',steps:['在隔离样区拼至少两段边界并接到原地块，标出不可见阻挡面和可见土丘/墙壳。','拍玩家视高、斜视与侧剖边缘，基于完整边界段设计新的视觉遮挡。','只替换可见景观壳，保留实际阻挡高度、连续性、碰撞和地图外缘定位。']};
 case 'controller':return {key:'prepare',unit:'控制器＋实际被控场景',reason:`${s} 的主要设计单元是其被控对象，不能把控制载体方块当成独立美术。`,steps:[`依据「${s}」子节点和实际引用，把被控场景/奖励箱/刷怪区一起纳入临时展示组；控制点仅用辅助标记显示。`,'拍无辅助标记的完整场景作为换皮底图，另拍控制点叠加图作为工程约束。','按被控可见子对象实施换皮，保留根节点、触发体积、阶段值、奖励与刷怪/显示入口。']};
 case 'prototype':return {key:c.uncertain?'verify':'prepare',unit:'先确认显示状态/补齐外观原型',reason:c.note||'当前只有控制壳或透明结构，缺少可用于直接换皮的默认实体外观。',steps:[`先确认「${s}」由哪个配置、脚本或宿主提供显示状态/外观；读取真实引用，不以蓝色辅助图认定原始材质。`,'若已有宿主，挂回原载体并设置实际显示状态后取图；若确实没有外观，先制定角色/道具原型尺寸与主题设计，再用完整原型出效果图。','生成后把可见外观作为原控制结构的子模型接回，保留定位、传感、配置键与可见性逻辑。']};
 case 'logic':return {key:'none',unit:'保留逻辑节点，换皮其可见宿主',reason:c.note||'这条是定位、存放、出生或根节点结构，默认没有独立美术目标。',steps:[`保留「${s}」原定位/存放/Root 结构，沿引用入口确定实际可见宿主。`,'在宿主效果图中以临时轮廓标出该节点的不可侵入区域，生成宿主的新外观。','替换宿主的可见网格/贴图；本条保留位置、范围、名称和逻辑，不单独生成实体造型。']};
 case 'template':return {key:'none',unit:'占地样板用于约束真实建筑',reason:'该条已确认为开发占地样板，方块代表尺寸而不是正式建筑造型。',steps:[`把 ${r.name} 的原 ${d} 样板作为透明占地框，叠到同占格真实建筑或拟制的新建筑上。`,'为真实建筑补入口、底座和玩家视高后截图出效果图，另保留俯视占地框。','回装实际建筑模板，按正方形/长方形的原旋转和放置规则检验；占地样板本身继续保留。']};
 case 'empty':return {key:'none',unit:'先补齐缺失的可见内容',reason:'当前结构没有 BasePart 造型，不能从空容器截图生成可替换外观。',steps:[`检查「${s}」原父级、引用和历史/外部来源，确认是预留容器还是丢失的部件。`,'预留容器继续保留；若确实缺失造型，先恢复参考或建立完整组件，并与其宿主组合后再截图设计。','对恢复后的可见子模型实施替换，保留原空容器的路径、配置键和控制职责。']};
 case 'unknown':return {key:'verify',unit:'先确认宿主，再做组件或材质板',reason:`当前只确认 ${r.class}、${r.parts} 个几何件与 ${d} 范围，无法可靠判定完整设计单元。`,steps:[`从「${r.path}」的父级、引用审计和同位置装配关系确认宿主；数字名只在命名空间确认后匹配配置。`,'若为建筑零件，按原连接面装成墙角/门洞/完整构件；若为地块，按 50-stud 网格搭 5 × 5 样区；若只是材质样本，建立带尺度参照的平面/转角/曲面材质板。','给宿主取整体与局部对照图再设计，回拆到本件；宿主未确认前保留待确认标记，不将任意方块推定为正式建筑。']};
 default:{
 const kind=key==='building'?'建筑':key==='creature'?'角色/生物':key==='weapon'?'武器/工具':key==='tree'?'树木':key==='hat'?'头饰':key==='sign'?'牌体与牌面':'完整物件';
 return {key:'direct',unit:kind+'完整单体',reason:`现有 ${f.visibleParts} 个可见部件已组成「${s}」的完整可辨认外观，无需先补齐其他组件才能画主效果图。`,steps:[`以「${s}」当前完整造型取正侧背或 45° 主图，使用原 ${d} 范围作尺度参照，生成同主题效果。`,key==='creature'?'补站姿/移动或骑乘等实际姿态对照，确认头身比例、装备归属与关节活动范围。':key==='hat'?'可另挂到匹配头型做试戴校验，保留脸部视线、帽檐高度与原挂点。':key==='building'?'补入口、门轴与内部通道视角；同主题相邻建筑/地块作为配套参照。':key==='sign'?'牌面文字/图案做同长宽比平面稿，再合回实体木框查看可读性。':'必要时补打开/使用等原有状态或安装比例，保持与同系列物件的视觉一致。','按现有可见子件回填新网格/材质，原根节点、配置身份及控制接口继续保留。']};}
 }
}
function engineering(r,f,c){
 const a=[`根类型 ${r.class}、原对象名称/配置身份与原 Pivot 坐标系。`];
 if(['tile','terrain','overlay','vegetation','landform','boundary'].includes(c.profile))a.push('原格宽 50 studs、地表/水位高度、碰撞与通行边界；覆盖件保持宿主局部变换。');
 if(c.profile==='building')a.push('占格与入口净空；正方形建筑可四向 90° 放置，长方形遵循原长宽轴与 180° 规则。');
 if(r.class==='Tool')a.push('Tool/Handle、Grip、握持尺度和使用/装备逻辑；外观变化不自动重建功能。');
 if((r.class==='Part'||r.class==='MeshPart')&&c.profile==='weapon')a.push('本条是外观 Part/MeshPart 样本；接回正式 Tool 时沿用目标 Tool 的 Handle/Grip 和控制结构。');
 if(f.rigTypes.length||f.classes.Motor6D||f.classes.AnimationController)a.push(`骨骼/动画结构：${f.rigTypes.join('/')||'AnimationController/关节结构'}；保留关节层级、原相对变换和动画兼容性。`);
 if(f.interfaces.length)a.push('实际接口节点：'+f.interfaces.slice(0,7).join('、')+'。');
 if(f.attachments.length)a.push('实际挂点：'+f.attachments.slice(0,7).join('、')+'。');
 if(f.values.length)a.push('实际控制字段：'+f.values.slice(0,6).join('、')+'。');
 if(r.tags?.length)a.push('原标签：'+r.tags.slice(0,6).join('、')+'。');
 if(r.rawNameHex)a.push('原名含无效 UTF-8 字节；使用已核对的实例定位/唯一标识对照，名称修复需另评估引用。');
 return a;
}
function family(name){
 const n=name.replace(/\s+/g,'');
 return /CowboyGun|Gunslinger/i.test(n)?'gunCowboy':/CowboyMelee/i.test(n)?'meleeCowboy':/Alligator/i.test(n)?'alligator':/Wolf/i.test(n)?'wolf':/Bear/i.test(n)?'bear':/Turkey/i.test(n)?'turkey':/山羊人/.test(n)?'goatBoss':/小牛/.test(n)?'bullBoss':/Moose|Elk/i.test(n)?'deer':/Boar|猪/.test(n)?'boar':null;
}
const assessments=rows.map(r=>{
 const f=assert.ok(facts.has(r.id))||facts.get(r.id);assert.equal(f.parts,r.parts,r.id);
 const p=photos.get(r.id),c=choose(r,f,p),pplan=plans(r,f,c);
 const confidence=pplan.key==='verify'?'待核实':c.visualReviewed?'中':r.basis.includes('确认')||r.role==='地图生成模板'?'高':'中';
 const companions=[];
 function addCompanion(x,relation){x=id(x);if(x!==r.id&&catalog.has(x)&&!companions.some(c=>c.id===x))companions.push({id:x,name:catalog.get(x).display,relation});}
 const cfg=resourceConfig.get(Number(r.name));
 if(r.path.startsWith('Workspace.Prefabs.Resources.')&&cfg){
  const ammo=resourceConfig.get(Number(cfg.param));
  if(ammo&&/Bullet/.test(ammo.ItemType||'')&&resourceAssets.has(Number(ammo.id)))addCompanion(resourceAssets.get(Number(ammo.id)).id,`配置配套：ResourcesItemSetting #${cfg.id}.param=${ammo.id}，目标类型 ${ammo.ItemType}`);
 }
 if(r.id==='AF-0242')for(const x of [186,200,276])addCompanion(x,'ResourcesItemSetting 明确命名的 Iron Verdict 同系列枪械零件；按整枪对照装配');
 if(r.subcategory==='职业头饰'){
  const role=config.CharaterSetting.find(x=>r.display===x.Name+' 头饰');
  if(role&&resourceAssets.has(Number(role.startToolUI)))addCompanion(resourceAssets.get(Number(role.startToolUI)).id,`职业配置对照：CharaterSetting #${role.id}.startToolUI=${role.startToolUI}，不代表头饰装配到该工具`);
 }
 for(const x of [...new Set(companionIds(r,c).map(id))])addCompanion(x,([186,200,276,242].includes(r.index)&&[186,200,276,242].includes(catalog.get(x)?.index))?'配置同系列/装配对照':r.id==='AF-0648'?'代码确认木材类载体；本编号为建议样本':r.parent===catalog.get(x)?.parent&&r.source==='预设库'?'同目录配套参考；非装配引用证明':'建议演示/同题材对照；装配关系需核对');
 if(c.profile==='creature'&&family(r.display))for(const peer of rows.filter(x=>x.id!==r.id&&family(x.display)===family(r.display)&&x.materialType!=='服饰护具'&&(/角色、敌人与动物/.test(x.category)||x.id==='AF-0687'||x.id==='AF-0702')).slice(0,3))addCompanion(peer.id,'同类角色/生物的美术风格对照；不表示共用骨骼或实际装配');
 if(c.profile==='prop'&&r.materialType==='资源与食物'&&/蔬果|汤|食材|蘑菇|医疗|消耗/.test(r.subcategory))addCompanion(324,'建议的营地/食物陈列比例参照；不是已确认配方');
 if(c.profile==='weapon'&&((f.classes.ParticleEmitter||0)+(f.classes.Beam||0)>0))addCompanion(598,'建议另出武器特效板；Effects 为效果库，具体子效果需按脚本确认');
 if(c.profile==='prop'&&r.subcategory==='营火')for(const x of [4,5,6,7,8,9,10])addCompanion(x,'同目录营火等级外观对照，保持升级轮廓和主题一致');
 companions.splice(6);
 const structural=`${r.class}；${r.parts} BasePart / ${f.visibleParts} 默认可见；${f.classes.Motor6D??0} Motor6D；${f.classes.ParticleEmitter??0} 粒子、${f.classes.Beam??0} Beam；${(f.classes.SurfaceGui??0)+(f.classes.BillboardGui??0)} 世界界面。`;
 const evidence=[structural,`原分类线索：${r.subcategory}；${r.basis}。`,...(c.note?[c.note]:[]),...(c.visualReviewed?['已有主图已复核，视觉身份不代替正式用途证明。']:[])];
 return {id:r.id,decisionKey:pplan.key,decision:labels[pplan.key],canDirect:pplan.key==='direct'?true:pplan.key==='prepare'?false:null,workflow:routes[c.profile],subject:c.subject,unit:pplan.unit,reason:pplan.reason,plan:pplan.steps,companions,companionNote:companions.length?'具体关系范围逐项记录；建议搭配不等于已确认装配。':pplan.key==='direct'?'完整单体主图无需额外装配资产；保留工程接口并按需要补比例/状态参照。':'尚无证据支持具体配套编号，先按方案追查实际宿主；不指定任意资产为正式配套。',engineering:engineering(r,f,c),confidence,evidence,visualReviewed:!!c.visualReviewed,profile:c.profile,existingPreview:p.method};
});
assert.equal(assessments.length,905);assert.equal(new Set(assessments.map(x=>x.id)).size,905);
for(const a of assessments){assert.ok(a.workflow&&a.subject&&a.reason&&a.plan.length>=3&&a.engineering.length);for(const x of a.companions)assert.ok(catalog.has(x.id));}
const counts=Object.fromEntries(Object.keys(labels).map(k=>[k,assessments.filter(a=>a.decisionKey===k).length]));
const workflowCounts=assessments.reduce((a,r)=>(a[r.workflow]=(a[r.workflow]||0)+1,a),{});
const reviewedIds=new Set([...JSON.parse(await fs.readFile(path.join(root,'visual-triage.json'),'utf8')),...JSON.parse(await fs.readFile(path.join(root,'primitive-triage.json'),'utf8'))].map(r=>r.id));
const result={date:'2026-11-19',version:1,total:905,scope:'是否可直接制作换皮效果图；不等于工程模型可直接替换。',definition:'是：已有完整可辨认设计单元，无需先补装配或显示状态即可生成主概念图；否：需先完成明确的组合、铺排、试穿、状态或分镜准备；待确认：宿主/显示语义不足；不适用：当前是空对象、纯逻辑或开发占地结构。',pairingPolicy:'配套编号默认是建议演示或对照，不是已经证实的正式装配/运行引用；只有条目明确说明代码、配置或层级依据时才按该范围确认。',method:{liveStructures:905,visualTriageReviewed:reviewedIds.size,mode:'Studio 只读结构采集＋既有分类/配置和引用审计＋疑难图示逐项复核＋按设计单元规则判定',gameMutated:false,screenshotsAdded:0},mapRules:{gridSize:50,demonstrationPatch:[5,5],patchSpanStuds:[250,250],groundRotations:[0,90,180,270],buildingRotationRule:'正方形四向 90°；长方形以长宽轴作 0/180°，必要时加 90°。',evidence:['当前 DefaultSetting：格子大小1=50、格子大小2=5、地图大小=11','MapService:CreateNormalLand（快照98–114行）','MapHelper:CreateBuilding（快照377–436行）'],note:'5×5 是建议演示样区，不代表完整运行地图尺寸；只取原规则的局部样区。'},counts,workflowCounts,assessments};
await fs.writeFile(path.join(root,'reskin-assessment.json'),JSON.stringify(result,null,2),'utf8');
await fs.writeFile(path.join(root,'validation.json'),JSON.stringify({total:905,idsUnique:true,structuresMatched:905,plansComplete:905,companionIdsValid:true,counts,workflowCounts,visualTriageReviewed:reviewedIds.size,verifyIds:assessments.filter(r=>r.decisionKey==='verify').map(r=>r.id)},null,2),'utf8');
console.log(JSON.stringify({total:905,counts,workflowCounts,visualTriageReviewed:reviewedIds.size,verifyIds:assessments.filter(r=>r.decisionKey==='verify').map(r=>r.id)}));
