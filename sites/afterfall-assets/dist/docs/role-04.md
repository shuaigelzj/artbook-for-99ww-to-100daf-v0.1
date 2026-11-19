# 过场与演出场景

2026-11-18。第二版分类快照，1 条。[返回分类文件索引](index.md)。

程序用途与素材类型分别记录，Prefabs 内外仅表示位置。目录推断、配置身份、实测生成命中与运行态保留分别标注。未确认不等于未使用。

换皮评估更新于 2026-11-19。可直接出图表示已有完整设计单元；工程替换仍需保留控制接口。配套编号默认是建议演示/对照，具体关系见逐条说明。

| 编号 | 名称 / 原名 | 程序用途 | 素材类型 | 位置 | 引用审计 | 可直接出换皮图 | 制图单元 / 理由 | 配套与替换方案 | 工程保留约束 | 脚本或入口 | 依据 | 备注 | Studio 定位 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| AF-0899 | CamSetting | 过场与演出场景 | 建筑场景 | Prefabs 外 | 检出静态引用 | 否 · 场景分镜（高） | CamSetting 过场场景；整体总览＋子组件/镜头套图；CamSetting 过场场景 是复合空间/演出单元，一张远景不足以约束内部组件与可玩空间的替换。 | AF-0511 火车（建议演示/同题材对照；装配关系需核对）；AF-0407 CowboyGunV1（建议演示/同题材对照；装配关系需核对）；AF-0469 棕色普通马（建议演示/同题材对照；装配关系需核对）；1. 保持「CamSetting 过场场景」原地面、坐标与锚点，按建筑/街区/车厢/洞穴内外或影片镜头分组；已有洞穴内外附图可以直接作首组参考。；2. 先拍完整总览，再对每个实际子场景拍玩家视高和关键侧视；标出入口、通道、刷怪/奖励点、门轴或镜头点。；3. 以套图确定统一主题，按原层级逐组替换美术并回装总场景；保留通行空间、占地、事件挂点与镜头轨迹。 | 根类型 Model、原对象名称/配置身份与原 Pivot 坐标系。；骨骼/动画结构：R6；保留关节层级、原相对变换和动画兼容性。；实际接口节点：Handle [Part]、HumanoidRootPart [Part]、Core [Part]、HumanoidRootPart [UnionOperation]、RootPart [Part]、TakeDamageC2S [RemoteEvent]、Core [UnionOperation]。；实际挂点：FaceCenterAttachment、FaceFrontAttachment、NeckAttachment、BodyFrontAttachment、HairAttachment、HatAttachment、RightShoulderAttachment。；实际控制字段：grid [Vector3Value]、降低寒冷值 [IntValue]、AvatarPartScaleType [StringValue]、OriginalSize [Vector3Value]、ThumbnailCameraValue [CFrameValue]、ThumbnailCameraTarget [ObjectValue]。 | StarterGui.FilmMode.LocalScript（51、67–77、85–86 行） | 脚本与实测确认；运行态保留 5/5 轮 | 镜头脚本直接读取、引用并移动场景；包含演出角色和布景。；包含 2,497 个 BasePart、13 个 Humanoid；内部演出子场景尚未逐个拆分。 | `Workspace.CamSetting` · `W/267` |
