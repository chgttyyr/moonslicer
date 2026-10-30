# MoonSlicer

<p align="center">
  <b>纯 MoonBit 实现的 3D 打印切片与刀路生成引擎 (Zero FFI)</b><br>
  <i>A Pure MoonBit 3D Printing Slicer & Toolpath Engine</i>
</p>

<p align="center">
  <a href="https://mooncakes.io/docs/chgttyyr/moonslicer"><img src="https://img.shields.io/badge/Mooncakes-chgttyyr%2Fmoonslicer-orange.svg" alt="Mooncakes"></a>
  <img src="https://img.shields.io/badge/Language-MoonBit-purple.svg" alt="MoonBit">
  <img src="https://img.shields.io/badge/Architecture-Zero--FFI%20Pure%20MoonBit-brightgreen.svg" alt="Zero FFI">
  <img src="https://img.shields.io/badge/Target-Native%20%7C%20Wasm-blue.svg" alt="Targets">
  <img src="https://img.shields.io/badge/Tests-47%2F47%20Passing-success.svg" alt="Tests">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache--2.0-blue.svg" alt="License"></a>
</p>

---

## 1. 项目概述

**MoonSlicer** 是一个使用纯 [MoonBit](https://www.moonbitlang.com/) 语言开发的现代增材制造 **3D 打印切片与刀路生成引擎**。它能够将三维三角形网格模型（二进制与 ASCII 格式 STL）直接转换生成适用于 3D 打印机固件（Marlin / RepRap / Klipper）的标准 G-code 打印控制指令。

本项目采用**零外部 FFI 依赖（Zero FFI）**的纯原生架构，所有计算几何求交、拓扑闭环、多孔偏置碰撞消解、多元填充几何生成、接缝起针优化、悬垂搭桥识别与物理送丝微积分算法均在 MoonBit 原生内存中自主实现。项目支持同时编译为原生机器码（Native）与 WebAssembly（WASM / Wasm-GC），具备极高的跨平台执行效率与确定性输出保证。

---

## 2. 核心架构与技术特性

### 2.1 三维网格解析与空间归一化
- **流式 STL 解码**：内建 IEEE 754 单精度浮点数解码器，原生支持标准 Binary STL 与文本 ASCII STL 的流式解析。
- **自动对齐与热床居中**：自动计算三维网格轴向包围盒（AABB），将模型底部平贴于 $Z = 0$ 打印平面，并将几何质心自动平移对齐至热床中心 $(100, 100)$。

### 2.2 水平截面切片与拓扑闭环缝合
- **解析平面求交**：在任意层高 $Z = z_i$ 上对三维空间三角形进行线性解析求交，内建自适应 $\epsilon$-微扰机制，杜绝截面恰好切过几何顶点的退化奇异。
- **拓扑线段链式缝合 ($\epsilon$-Chaining)**：针对切片产生的无序二维线段集合，基于空间首尾距离贪心匹配，将其精确重构成连续闭合的二维多边形轮廓环（`Polygon2`）。

### 2.3 ExPolygon 拓扑层级包含树
- **Jordan 奇偶深度判定**：基于射线求交与多边形嵌套关系计算包含深度，偶数深度判定为独立实体外岛（CCW 逆时针，正面积），奇数深度判定为内部空腔内孔（CW 顺时针，负面积）。
- **拓扑树表达**：原生支持单层多独立实体（Multi-Island）与多层嵌套复杂通孔结构的树状表达，与现代主流切片器几何拓扑内核对齐。

### 2.4 间隙感知与偏置碰撞消解引擎
- **角平分线法向量偏置**：实现实体外壁向内收缩与内孔壁向外膨胀的角平分线偏移，内建斜接截断（Miter Limit）与边反转坍塌检查。
- **欧氏间隙场分析 (Clearance Field Analysis)**：在生成多圈外壁前，精确评估孔与孔、孔与外轮廓之间的最小几何间隙，推导最大安全膨胀阈值 $d_{safe}$。
- **自适应截断与重叠抑制 (Clamping & Wall Suppression)**：当特征狭窄时自动截断偏置步长；对于间隙不足以容纳多圈壁厚的狭窄区域，主动**抑制生成重叠内壁**（`WallSuppressed`），彻底杜绝重复挤出造成的喷嘴刮擦与过量溢料。
- **后置几何交叉校验**：轮廓生成后执行穷举线段交叉校验（`edges_intersect`），数学上杜绝自交或相交刀路输出。
- **Ramer-Douglas-Peucker 轮廓化简**：提供 `Polygon2::simplify` 算法，在亚微米尺度下自适应剔除共线噪点与冗余顶点，杜绝高分辨率模型造成的打印机通讯抖动。

### 2.5 跨层表面分类与搭桥冷却控制
- **三维几何覆盖比对**：通过对比当前层与上下相邻层（$Z_{i-1}$ 与 $Z_{i+1}$）的实体投影覆盖关系，精确判定 `TopSolid`（顶面/阶梯屋顶）、`BottomSolid`（底面/悬垂桥接）与 `InternalSparse`（内部区域）。
- **悬垂搭桥风扇控制**：当识别到悬垂搭桥表面时，自动触发高速冷却风扇指令（`M106 S255`）并按比例下调挤出流速（Flow Ratio）与移动速度，搭桥结束后自动恢复常规风速。

### 2.6 多元内部填充几何生成器
引擎支持 4 种经典的增材制造内部轻量化填充模式：
- **Rectilinear (交替线性网格)**：45° 与 135° 奇偶层交替方向，平衡打印速度与层间附着力；
- **Grid (双向正交网格)**：每层同时打印双向正交交叉扫描线，提供刚性支撑骨架；
- **Triangles (等边三角晶格)**：0°、60°、120° 三向交叉成型，具备优异的面内全向抗剪切刚度；
- **Concentric (同心偏置环)**：自外轮廓向内核心逐层偏移同心环，极大减少空载空移，适合圆柱与弹性体材料；
- **内孔全自动避空 (Hole Parity Clipping)**：所有填充模式均内嵌奇偶相交校验，遇到内部空腔自动断针避空。

### 2.7 起针接缝优化策略 (Seam Placement Modes)
- **SharpestCorner (最锐角隐藏)**：计算多边形顶点外角凸度，自动将起笔接缝对齐隐藏于构件最锐利的自然棱角处；
- **Nearest (最短空程)**：基于当前喷头坐标贪心选择最近顶点起跳，显著减少空走距离与拉丝；
- **Aligned (几何对齐)**：将全模型各层外壁起针点向指定空间方位（如热床后方中央）对齐排布；
- **Random (随机打散)**：随机散布各层起针顶点，消除圆柱外壁由于接缝聚集产生的纵向微小凸棱。

### 2.8 真实物理耗材质量与成本估算
- **扁平跑道截面微积分 (Stadium Cross-section)**：严格依据 FDM 熔融挤出物理模型 $A = (W - H)H + \pi (H / 2)^2$ 计算微元体积 $V = A \times L$，精准推导绝对坐标 E 轴送丝进给量。
- **物理材料质量建模**：内建常用 3D 打印耗材密度库（PLA: $1.24\,\text{g/cm}^3$、PETG: $1.27\,\text{g/cm}^3$、ABS: $1.04\,\text{g/cm}^3$、TPU: $1.21\,\text{g/cm}^3$），实时推算总耗材克重与成型原料成本。

### 2.9 交互式刀路可视化工具
- **开箱即用**：提供纯 HTML5 Canvas 架构的轻量级前端刀路查看器（`examples/visualizer.html`），无需本地服务器，双击即可在任意现代浏览器运行。
- **分层与多色审视**：支持拖拽滑块逐层查看、动画播放、以及外壁（红）、孔壁（橙）、内壁（绿）、顶底实心填充（青）、内部稀疏填充（黄）与碰撞消解事件 HUD 实时显示。

---

## 3. 切片处理管线

```
+---------------------------------------------------------------+
| 输入：3D 模型文件 (Binary / ASCII STL)                        |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 1. STL 解码与热床居中对齐 (center_to_bed)                     |
|    流式解析三角面，计算 AABB 包围盒并平移至热床中心 (0,0,0)   |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 2. 截面解析求交 (slice_mesh_at_z)                             |
|    各三角面与平面 Z = z_i 线性求交，引入 epsilon 微扰消奇异   |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 3. 拓扑线段闭环缝合 (stitch_segments_into_loops)              |
|    基于首尾 epsilon 距离贪心重组封闭多边形环 Polygon2         |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 4. ExPolygon 拓扑层级树构建 (build_expolygons)                |
|    Jordan 奇偶深度判定：外岛 CCW (正面积) vs 内孔 CW (负面积)  |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 5. 间隙感知偏置与碰撞消解 (generate_expolygon_perimeters)     |
|    距离场分析、自适应截断、薄壁抑制与后置相交校验             |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 6. 跨层表面分类与多元填充 (infill.mbt / surface.mbt)          |
|    顶底实心识别、4 种填充几何 (Rectilinear/Grid/Triangles/    |
|    Concentric) 与搭桥风扇增强                                 |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 7. 跑道截面挤出量微积分与 G-code 合成 (generate_gcode)        |
|    体积积分计算 E 轴进给量，注入温控、回抽、接缝与分层 G-code |
+---------------------------------------------------------------+
```

---

## 4. 项目结构

```
moonslicer/
├── types.mbt            # 切片配置参数、表面枚举、填充几何模式、材料密度库与接缝策略
├── geom.mbt             # 2D/3D 几何向量、线段求交、Polygon2、RDP 化简、ExPolygon 拓扑树
├── stl.mbt              # IEEE 754 float32 解码、Binary/ASCII STL 流式解析器
├── slice.mbt            # 三角形截面求交与拓扑线段链式闭环重构
├── offset.mbt           # 角平分线偏置算法、多孔间隙分析与碰撞消解引擎
├── surface.mbt          # 跨层表面分类引擎 (TopSolid / BottomSolid / InternalSparse)
├── infill.mbt           # 多元填充生成器 (Rectilinear / Grid / Triangles / Concentric)
├── gcode.mbt            # 跑道截面微积分、起针接缝排布、搭桥风控与 G-code 合成器
├── pipeline.mbt         # 端到端切片流程编排器与模型统计评估
├── cmd/main/            # 独立命令行工具 CLI (slice / info / help)
├── fixtures/            # 标准测试模型库 (校准立方体、薄壁双孔干涉构件等)
├── examples/            # HTML5 Canvas 交互式刀路可视化工具
├── *wbtest.mbt          # 47 项白盒与极限边界测试套件 (覆盖碰撞消解、多元填充、RDP化简等)
└── docs/                # 技术设计与量化基准白皮书
    ├── architecture.md  # 详细算法推导与工程设计文档
    └── BENCHMARKS.md    # 真实量化基准数据与极限边界测试报告
```

---

## 5. 快速上手

### 环境要求
- [MoonBit 编译器工具链](https://www.moonbitlang.com/)（推荐版本 `>= v0.1.20260920`）

### 编译与测试
```bash
# 执行静态类型推导与语法检查
moon check

# 验证 WebAssembly 目标架构兼容性
moon check --target wasm
moon check --target wasm-gc

# 运行全套 47 项白盒、集成与性能基准测试
moon test

# 代码格式化规范检查
moon fmt --check
```

---

## 6. 命令行工具 (CLI)

MoonSlicer 提供了开箱即用的命令行工具，支持三维模型元数据审视与切片代码生成。

### 6.1 模型信息审视 (`info`)

读取 STL 文件并输出面片数量、三维尺寸与预估层数：

```bash
moon run cmd/main -- info -i fixtures/dual_holes_collision.stl
```

输出示例：
```
Reading STL file: fixtures/dual_holes_collision.stl (5597 bytes)...
----------------------------------------
Mesh Inspection Report:
  Triangle Facets:   44
  Bounding Width (X):30 mm
  Bounding Depth (Y):15 mm
  Bounding Height (Z):4 mm
  Z Range:           [0, 4] mm
  Estimated Layers:  19 (at 0.2mm)
----------------------------------------
```

### 6.2 执行高级切片生成 G-code (`slice`)

针对指定模型执行全流程切片，支持自定义填充模式、接缝排布、打印材料与成本参数：

```bash
moon run cmd/main -- slice -i fixtures/dual_holes_collision.stl -o output.gcode \
  --layer-height 0.2 \
  --initial-height 0.28 \
  --line-width 0.4 \
  --walls 2 \
  --bottom-solid 3 \
  --top-solid 3 \
  --density 0.2 \
  --pattern grid \
  --seam sharpest \
  --material pla \
  --cost-per-kg 120.0 \
  --speed 50.0
```

输出示例：
```
Loading model from: fixtures/dual_holes_collision.stl...
Parsing mesh (5597 bytes)...
Mesh: 44 facets, 30x15x4 mm
Slicing layers (height: 0.2 mm, pattern: Grid, seam: SharpestCorner)...
Synthesizing G-code (19 layers)...
----------------------------------------
Slicing Completed Successfully!
  Output File:        output.gcode
  Total Layers:       19
  Collisions Resolved:38
  Filament Extruded:  317.24 mm
  Filament Mass:      0.95 g
  Estimated Cost:     ¥0.11
  Est. Print Time:    5.87 min
----------------------------------------
```

---

## 7. 交互式可视化工具 (Visualizer)

项目在 [`examples/visualizer.html`](examples/visualizer.html) 中内置了基于 HTML5 Canvas 的跨平台刀路可视化工具：

- **零依赖即开即用**：直接双击在任意主流浏览器（Chrome、Edge、Safari、Firefox）中打开，无需配置本地 Web 服务。
- **逐层审视与动画播放**：支持拖拽滑块切换观察任意单层刀路，或以设定速率自动播放打印行进动画。
- **多色分层呈现**：
  - 红色：外壁轮廓（Outer Perimeter）
  - 橙色：内孔轮廓（Hole Perimeter）
  - 绿色：内部外壁（Inner Perimeter）
  - 青色：顶底层密实填充（Solid Infill）
  - 黄色：内部轻量化稀疏填充（Sparse Infill）
  - 灰色虚线：空载快速移动（G0 Travel）
- **实时状态 HUD**：实时显示当前层高、耗材累计消耗、预估耗时以及碰撞消解事件统计。

---

## 8. 开源协议

本项目采用 [Apache-2.0](LICENSE) 开源协议。
