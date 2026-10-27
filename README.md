# MoonSlicer

<p align="center">
  <b>用纯 MoonBit 实现的 3D 打印切片引擎与工具链</b><br>
  <i>A PrusaSlicer-Aligned 3D Printing Slicer Written in Pure MoonBit</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-MoonBit-purple.svg" alt="MoonBit">
  <img src="https://img.shields.io/badge/Zero--FFI-Pure%20MoonBit-brightgreen.svg" alt="Zero FFI">
  <img src="https://img.shields.io/badge/Tests-26%20Passed-brightgreen.svg" alt="Tests">
  <img src="https://img.shields.io/badge/License-Apache--2.0-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Status-Active%20Development-success.svg" alt="Status">
</p>

---

## 1. 项目简介

**MoonSlicer** 是一个使用纯 MoonBit 语言自研的 **3D 打印切片引擎（Slicer）与工具链**。

本项目**不依赖任何外部 C/C++ 动态链接库或 FFI 绑定**，严格参考工业级切片引擎（PrusaSlicer / Slic3r）的架构体系，在纯 MoonBit 内存中完整实现了现代增材制造核心算法：

1. **3D 网格解析与对齐**：支持标准二进制（Binary）和 ASCII 格式 `.stl` 文件解析，计算 3D 轴向包围盒（AABB），并自动将模型底部对齐到打印热床原点；
2. **截面几何求交**：在任意层高平面 $Z = z_i$ 上对三维三角面进行高效线性求交，提取二维相交线段；
3. **拓扑缝合与闭环重构**：基于 $\epsilon$-距离邻域匹配，将无序线段流式重组成严格封闭的连续多边形边界环；
4. **多岛屿与内孔层级树 (ExPolygon Hierarchy)**：基于 Jordan 曲线奇偶深度判定（Even-Odd Containment Tree），自动识别独立外岛（CCW）与内孔洞（CW），构建完整的拓扑包含树；
5. **偏置碰撞处理机制 (Offset Collision Resolution)**：针对相邻孔壁与薄壁区域，自研**间隙距离场分析 + 自适应偏置截断（Clamping）+ 壁厚抑制（Wall Suppression）+ 后置线段交叉校验**，彻底消除了相邻内孔偏置交叠和过量挤出风险；
6. **跨层表面识别 (Cross-layer Surface Classification)**：通过对比当前层与上下相邻层几何覆盖关系，精准判定 **BottomSolid (底面/悬垂桥接)**、**TopSolid (顶面/阶梯屋顶)** 与 **InternalSparse (内部稀疏填充)**；
7. **内孔感知扫描线填充**：实现 45° 与 135° 奇偶层交替扫描线网格填充，支持顶底层 100% 密集实心填充与内部层稀疏填充，自动剔除内孔避空走针；
8. **挤出量物理建模与 G-code 合成**：严格依据扁平跑道截面（Stadium Cross-section）微积分建模计算耗材物理挤出量（E 值），输出 Marlin / RepRap / Klipper 标准分类 G-code 代码。

项目内置基于 **HTML5 Canvas 的交互式刀路可视化工具（Toolpath Visualizer）**，可直观区分并逐层审视外壁（红）、孔壁（橙）、内壁（绿）、实心填充（青）、内部稀疏填充（黄）、消解碰撞点与空载移动（灰色虚线）。

---

## 2. 核心架构与模块划分

```
moonslicer/
├── types.mbt            # 切片配置参数、SurfaceType 表面枚举、错误定义
├── geom.mbt             # 2D/3D 向量、线段求交、Polygon2、ExPolygon 拓扑多边形树
├── stl.mbt              # IEEE 754 float32 解码、Binary/ASCII STL 解析器
├── slice.mbt            # 三角形-截面求交与拓扑线段闭环缝合
├── offset.mbt           # 双向角平分线偏置、多孔碰撞消解与间隙自适应截断
├── surface.mbt          # 跨层表面识别引擎 (TopSolid / BottomSolid / InternalSparse)
├── infill.mbt           # 奇偶层 45°/135° 扫描线射线求交与内孔剔除填充生成器
├── gcode.mbt            # 跑道截面挤出量微积分、碰撞日志与分类 G-code 合成器
├── pipeline.mbt         # 端到端切片流程编排器与模型统计评估
├── cmd/main/            # 命令行工具 CLI (slice / info / help)
├── fixtures/            # 校准立方体、带通孔方块、多岛屿、双孔碰撞等标准测试模型
├── examples/            # HTML5 Canvas 交互式多岛屿、内孔与碰撞消解刀路可视化工具
└── docs/                # 计算几何数学模型、碰撞消解算法与 PrusaSlicer 对比白皮书
```

详细数学推导、碰撞消解原理与 PrusaSlicer 全维度对比见：[docs/architecture.md](docs/architecture.md)。

---

## 3. 快速上手

### 3.1 环境要求
- [MoonBit 编译器工具链](https://www.moonbitlang.com/)（版本 >= v0.1.20260920）

### 3.2 运行自动化测试
```bash
# 执行全部 26 项白盒、黑盒及碰撞消解单元测试
moon test
```

### 3.3 命令行工具 (CLI) 与碰撞消解案例

#### 案例 1：查看 1.2mm 薄壁双孔碰撞模型元数据
```bash
moon run cmd/main -- info -i fixtures/dual_holes_collision.stl
```
输出示例：
```
Mesh Inspection Report:
  Triangle Facets:   44
  Bounding Width (X):30 mm
  Bounding Depth (Y):15 mm
  Bounding Height (Z):4 mm
  Z Range:           [0, 4] mm
  Estimated Layers:  19 (at 0.2mm)
```

#### 案例 2：切片执行与多孔偏置碰撞消解
```bash
moon run cmd/main -- slice -i fixtures/dual_holes_collision.stl -o output.gcode \
  --layer-height 0.4 \
  --walls 2 \
  --bottom-solid 2 \
  --top-solid 2 \
  --density 0.2
```
输出示例：
```
Slicing Completed Successfully!
  Output File:        output.gcode
  Total Layers:       10
  Collisions Resolved:20
  Filament Extruded:  412.5 mm
  Est. Print Time:    2.6 min
```
生成的 G-code 中将自动注入碰撞消解溯源信息：
```gcode
; [COLLISION RESOLVED] Hole 0 - WallSuppressed (clearance: 1.200 mm)
; [COLLISION RESOLVED] Hole 1 - WallSuppressed (clearance: 1.200 mm)
```

---

## 4. 交互式可视化工具 (Visualizer)

在浏览器中直接双击打开 `examples/visualizer.html`，即可：
- 载入生成的 `.gcode` 切片代码文件；
- 拖动滑块查看每一层的二维打印刀路；
- **色彩分层呈现**：外壁（红色）、孔壁（橙色）、内壁（绿色）、顶底实心填充（青色）、内部稀疏填充（黄色）与消解事件计数；
- 支持实时缩放、平移与自动播放切片动画。

---

## 5. 开源协议

本项目采用 [Apache-2.0](LICENSE) 开源协议。
