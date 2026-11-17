# 100 Days After Fall｜玩法细化 01 · 营火、扩图与探索

**取证版本**　After Fall 局内 Place `108983613755535`，Studio 编辑态版本 7。以普通模式为基准。数值取自场景预设或实际调用的配置，随机生成数量注明是目标次数还是已成功放置的数量。未运行试玩。

## 1. 营火同时控制三件事

| 玩家看到的变化 | 实际控制值 | 玩家可利用的结果 |
| --- | --- | --- |
| 火亮了、灭了 | 当前热量 `heat > 0` 点亮火焰、灯和范围效果。归零关闭效果。 | 火灭后，普通夜怪的亮火排除、营地回血与灯油补给会失效。地图边界仍取决于等级。 |
| 火边的安全圈变大 | 基础范围 + 火把加成。每个普通火把配方 308 贡献 +5，移除对应对象时减回。 | 可以扩大亮火相关判定。玩家回血按三维距离小于该范围判断，野外刷怪调用的亮火排除按水平距离再加 50，判定半径不同。 |
| 地图外圈打开 | 升级后刷新四面空气墙。墙到地图原点的距离 = 125 + 250 ×（营火等级 − 1）。 | 每次开放一圈大格，灭火后等级和空气墙保持。地图迷雾还要靠探索揭开。 |

代码：`ServerScriptService.Game.CampfireService` 59–94、120–145、178–192、231–259、360–425；`ReplicatedStorage.src.Helpers.GameHelper` 516–522、582–593；`StarterPlayer.StarterCharacterScripts.夜晚刷怪` 18–34。

## 2. 六级数值与可探索面积

场景默认值：小格边长 **50 studs**，5 × 5 小格组成一个边长 **250 studs** 的大格，整张地图 **11 × 11 大格**，即 55 × 55 小格，共 3,025 小格。地图区域等级取 X、Z 到中心大格的最大偏移再加 1，呈同心方圈。表中面积是空气墙围出的理论平面范围，山水、建筑和其他场景限制仍可能影响实际路径。

| 营火等级 | 该档配置起始热量 | 升下一级所需热量 / 最高档上限 | 普通基础每秒耗热 | 基础亮火范围 | 理论边长 | 本次新增大格 / 累计大格 | 升级基础宝石 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 0 | 5 | 0.040 | 30 | 250 | 1 / 1 | 0 |
| 2 | 4 | 11 | 0.036 | 40 | 750 | 8 / 9 | 0 |
| 3 | 13 | 49 | 0.028 | 45 | 1,250 | 16 / 25 | 0 |
| 4 | 23 | 91 | 0.024 | 50 | 1,750 | 24 / 49 | 1 |
| 5 | 27 | 119 | 0.020 | 55 | 2,250 | 32 / 81 | 1 |
| 6 | 121 | 121 | 0.016 | 60 | 2,750 | 40 / 121 | 1 |

- 普通模式场景设置的初始等级是 1，热量需求与热量下降倍率均为 1。开局配置热量为 0，需要先投燃料。投料后比较「原有热量 + 燃料参数」与「本级上限 × 模式需求倍率」。一次触碰最多推进一级，到顶时把热量截在上限。
- 表内起始热量是等级变化回调写入的配置值。燃料触碰处理同样会写计算出的热量，因此不能单凭这列推断每次升级后的屏幕即时数值。
- 热量每秒循环扣减，公式为「基础消耗 × 模式下降倍率 + 基础消耗 × 额外消耗修正」。单人减免回调把修正设为 −0.5，人数超过一人时改为 0。雨天另加 +0.15。以 1 级为例，普通干燥多人的公式结果为 0.040，单人减免生效时为 0.020，雨天多人为 0.046。
- 湿燃料不会被烧掉，最近拖拽者会收到提示。热量降到上限 10% 以下时提示快熄灭，低热提示有 20 秒冷却。亮火范围内，服务每秒向回血逻辑传入 2，并给持灯者补 10 油，油量受上限约束。
- 4、5、6 级各配置 1 基础宝石，等级回调向当时在线的玩家发奖。最终数值经模式宝石倍率计算。

代码：`ReplicatedStorage.DefaultSetting` 的地图大小、格子大小1、格子大小2；`Workspace.GameValue`；`ReplicatedStorage.src.Helpers.MapHelper` 22–37、329–346；`ReplicatedStorage.src.ExcelConfig.CampfireSetting` 4–9；`CampfireService` 120–145、284–359、373–425；`ServerScriptService.Game.WeatherService` 62–86。

## 3. 按环查找内容

下表的动物为普通地块的基础分区配置，生命、伤害也取基础表。地标生成按落点、占地和脚本分支决定，表里的「尝试」表示可以因位置冲突、预设缺失等失败。

| 区域 | 主要内容与分区条件 | 普通地块动物 | 专门的宝箱资源点尝试量 |
| --- | --- | --- | --- |
| **1 · 营地** | 出生点和营火同坐标，工作台、悬赏牌在营地。中央 5 × 5 小格先设为已揭雾营地，其中外围随机一格换成营地池塘。灯库候选可落本圈或 2 区。 | 没有配置 `refreshZone=1` 的常规敌对动物。1–2 区可走野兔判定。 | 0 |
| **2** | 淘金屋在本圈尝试一次。可被抽为医院所在圈，也可尝试一个武器库。普通树干、萝卜和兔子仍符合分区条件。 | Baby Wolf，100 生命、10 基础伤害、20% 地块抽签。 | 5–7 |
| **3** | 第一座悬赏据点。宝石塔候选之一、第一处齿轮资源点、驼鹿巢穴候选。地块萝卜允许到本圈。 | Wolf，100 生命、20 伤害、20%。 | 7–10 |
| **4** | 第二座悬赏据点。宝石塔另一候选。武器工坊只在本圈找可落地位置；第二处齿轮点。1 级铃铛洞穴入口尝试落本圈。沉坑也限定本圈，可能抽到普通坑、雷神锤或老矿镇。 | Bear，250 生命、25 伤害、20%。 | 7–10 |
| **5** | 第三座悬赏据点。第三处齿轮点、2 级铃铛洞穴入口。驼鹿仍可出现。本圈是医院候选上限。 | Cougar，350 生命、25 伤害、20%。 | 7–10 |
| **6** | 第四座悬赏据点，地图外围与最终扩图范围。仍会尝试普通资源点、武器库、随机事件。 | Mad Bear，450 生命、30 伤害、20%。 | 7–10 |

- **跨圈与随机地标。** 宝石塔取 3 或 4 区候选，落点成功才结束重试。医院从 2、3、4、5 区抽出 2–4 个互不重复的圈，每个抽中圈尝试一个 2 × 1 建筑。武器库在 2–6 各圈独立抽 0 或 1 次，且需要预设和落点有效。随机事件对 2–6 区各抽一个预设尝试，化石额外尝试落在 4–6 区。驼鹿巢穴从 3–6 区合法陆地里洗牌，取第一个可用候选。
- **雪原、沼泽是地形层。** 都从小格坐标 (10,45)、(45,10)、(10,10)、(45,45) 选可容纳中心的位置，和分区环叠加。沼泽先生成，之后雪原、铁路、普通地形补齐。普通地形的未占用格有 1/250 的池塘抽签，营地池塘由营地初始化独立放置。
- **特殊目标以生成路径为准。** 营火 3–6 级会解锁对应悬赏牌提示，四座据点本身在地图初始化时已按各自区域放置。武器工坊和铃铛洞穴分别受各自玩法开关控制。当前版本这两个开关均开启。

代码：`ServerScriptService.MapService` 144–325、329–381、468–514、718–784、785–1033、1132–1299、1307–1411；`ReplicatedStorage.src.ExcelConfig.EnemySetting` 4–8；`WantedSetting` 4–7；`GearSourceSetting` 4–39；`Workspace.Prefabs.Map.WantedBoard.Wanted.WantedBoardScript` 40–54。

## 4. 到一个区域时，什么已经存在

| 时机 | 发生的事 | 回到同一个位置会怎样 |
| --- | --- | --- |
| **开局地图初始化** | 定区域等级、地形、营地、特殊地标和普通建筑位置。普通资源点按每个大格尝试 2–5 个，宝箱点各有 10 次找落点机会。 | 地标位置已定。升火移动墙以开放它们。 |
| **地块首次进入客户端串流范围** | 服务端等地图初始化完成，首次处理该地块时生成树石、近圈树干，并在带相应标签的地块尝试马或矿脉。地块进入时也检查萝卜。 | 树石和一般地块矿脉的首次生成有地块标记。萝卜另有标记，雨天事件会清掉该标记，并对每名玩家附近 5 × 5 小格尝试生成。 |
| **玩家接近地块** | 客户端约每 3 秒检查，距离 <150 时请求地块动物判定，服务端使用 175 的距离校验参数。常规动物对合格地块抽一次。 | 被杀后该地块禁止再次生成这一常规动物。模型被销毁时清占用记录，未被禁用的地块仍可响应后续生成请求。 |
| **首次进入普通建筑** | 开启建筑后才生成普通散落物、预设宝箱点及建筑敌人。普通资源点有多个挂点时，先抽 1 到挂点总数的数量，再无重复地选挂点。 | 建筑首次生成只做一次。普通宝箱有单独的玩家开启记录。 |
| **揭开迷雾** | 客户端触碰迷雾或视线命中时触发揭雾。服务器给地块标记并向全体广播。 | 队友共享揭雾进度。打地图标记另有亮火、存活及开放范围的检查。 |

普通陆地与营地生成树的尝试数量按圈减少：1–2 区每格 0–3 棵，3–4 区 0–2 棵，5–6 区 0–1 棵。每次生成树时有 20% 选大树。装饰石头是独立的约 1/3 抽签。树干在 1–2 区的合格陆地或营地每次首次判定有 50% 机会，萝卜在 1–3 区合格地块每次允许判定时有 50% 机会。马地点生成 3–6 匹普通马。带矿脉地块标签的地块在首次生成时以 50% 机会随机克隆一种矿脉预设。

代码：`ServerScriptService.Game.动植物生成` 29–212、213–279、323–377；`ReplicatedFirst.src.动植物生成` 1–37；`ServerScriptService.Game.BuildingServer` 13–53、78–108；`ReplicatedFirst.src.FogService` 31–85、98–114；`ServerScriptService.Game.GameController` 645–649。

## 5. 普通散落物与普通宝箱权重

下表列出六个普通散落物池（101–106）和六个普通宝箱池（1–6）。**分母是池的总权重**，每项后面的数字是合并重复条目后的权重。这个概率针对一次正常抽取。例：2 级建筑散落物池，铁类是 Screw、Horseshoe、Iron barrel，合计 9/14，约 64.3%。4 级宝箱的 Defense BluePrint 配了两次，所以是 2/26，而不是 1/26。

| 等级 | 池 ID | 总权重 | 物品与权重 |
| --- | ---: | ---: | --- |
| 1 | 101 | 11 | Old Lamp 1、Screw 3、Horseshoe 3、BioFuel 1、Coal 3 |
| 1 | 1 | 5 | Old Lamp 1、Knife 1、Medical Kit V1 1、Revolver Bullet 1、Revolver 1 |
| 2 | 102 | 14 | Knife 1、Leather Armor 1、Screw 3、Horseshoe 3、Coal 3、Iron barrel 3 |
| 2 | 2 | 14 | Big bag 1、Old Lamp 1、Good axe 1、Knife 1、Animal fat 3、Medical Kit V1 1、Revolver Bullet 1、Revolver 1、TomatoSoup 1、Iron barrel 3 |
| 3 | 103 | 19 | Big bag 1、Good axe 1、Leather Armor 1、Revolver 1、Screw 3、Horseshoe 3、Revolver Bullet 1、Rifle Bullet 1、Coal 3、Medical Kit V1 1、Iron barrel 3 |
| 3 | 3 | 21 | Big bag 1、Good axe 1、Knife 1、Animal fat 3、Leather Armor 1、Medical Kit V1 1、Revolver Bullet 1、Revolver 1、Oil 3、New Lamp 1、TomatoSoup 1、Iron barrel 3、Iron Rock 3 |
| 4 | 104 | 26 | Big bag 1、Good axe 1、Iron Armor 1、Revolver 1、Rifle 1、Coal 3、Horseshoe 3、Iron barrel 3、Revolver Bullet 1、Rifle Bullet 1、Iron Wheel 3、Medical Kit V1 1、Iron Rock 3、Iron ingot 3 |
| 4 | 4 | 26 | Defense BluePrint 2、Sword 1、Oil 3、Medical Kit V2 1、Rifle Bullet 1、Rifle 1、Horse Riding Guide 1、Iron Armor 1、New Lamp 1、Large bag 1、Power axe 1、Iron Wheel 3、Steam Machine 3、Iron Rock 3、Iron ingot 3 |
| 5 | 105 | 29 | Large bag 1、Sword 1、Iron Armor 1、Medical Kit V1 1、Rifle 1、Coal 3、Animal fat 3、Oil 3、Horseshoe 3、Iron barrel 3、Revolver Bullet 1、Rifle Bullet 1、Shotgun Bullet 1、Iron Wheel 3、Steam Machine 3 |
| 5 | 5 | 18 | Large bag 1、Defense BluePrint 1、Sword 1、Oil 3、Iron Armor 1、Medical Kit V2 1、Rifle Bullet 1、Rifle 1、Horse Riding Guide 1、Power axe 1、Iron Wheel 3、Steam Machine 3 |
| 6 | 106 | 26 | Large bag 1、New Lamp 1、Sword 1、Power axe 1、Iron Armor 1、Medical Kit V2 1、Animal fat 3、Oil 3、Iron ingot 3、Iron trolley 3、Rifle Bullet 1、Shotgun Bullet 1、Iron Wheel 3、Steam Machine 3 |
| 6 | 6 | 5 | Large bag 1、Power axe 1、Iron Armor 1、Medical Kit V2 1、Rifle Bullet 1 |

**怎么读这张表。** 建筑读取的是自身等级，地标出现在哪一圈与实际建筑等级需以该地标的初始化为准。普通宝箱池 1–6 开启时另有 1% 的分支改出 1 宝石。建筑有指定预设名时会先尝试生成该预设，普通宝箱权重表不适用于神器、宝石塔奖励和特殊箱。普通箱每名玩家可各开一次，普通实物生成在世界里，只有宝石掉落实例在抽取函数里保留传入的玩家所有权。枪械产出还会附带额外弹药。

代码：`ReplicatedStorage.src.ExcelConfig.RandomItemsSetting` 4–18；`ResourcesItemSetting` 的物品权重；`ReplicatedStorage.src.framework.CommonFunc` 217–237；`ReplicatedStorage.src.Helpers.ResourcesItemHelper` 16–23、309–342；`ServerScriptService.Game.BuildingServer` 20–52；`ServerScriptService.Game.GameController` 537–591。

## 6. 用规则读一条探索路线

- **火 1→2。** 三件普通木头理论上合计 6 热，足以越过 5 的阈值，实际需扣除搬运中已流失的热。烧掉这三件也等于放弃三单位工作台木料。若已经找到煤或油，用它们烧火可为工作台保留普通木。
- **火 2→3。** 在 2 区建筑里找铁和工具。2 级散落池里铁类权重 9/14，而 2 级普通宝箱还可能出 15 格背包、斧头、手枪和医疗包。分一人搬料、另一人开建筑能减少每次往返被物品容量卡住的概率，属于基于规则的分工推导。
- **火 3→4。** 3 区已有第一条悬赏和首个齿轮候选。4 区新增第二条悬赏、工坊与可能的 1 级铃铛洞穴，并开放高回收值铁料的普通池。单次出门可以选「把战利品带回工作台」或「为悬赏交付搬运目标」，两者会争抢时间和搬运空间。
