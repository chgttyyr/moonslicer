# MoonSlicer

<p align="center">
  <b>用纯 MoonBit 实现的 3D 打印切片引擎与工具链</b><br>
  <i>A 3D Printing Slicer Written in Pure MoonBit</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-MoonBit-purple.svg" alt="MoonBit">
  <img src="https://img.shields.io/badge/Zero--FFI-Pure%20MoonBit-brightgreen.svg" alt="Zero FFI">
  <img src="https://img.shields.io/badge/License-Apache--2.0-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Status-Active%20Development-success.svg" alt="Status">
</p>

---

## 1. 项目简介

**MoonSlicer** 是一个使用纯 MoonBit 语言自研的 **3D 打印切片引擎（Slicer）与工具链**。

它不依赖任何外部 C/C++ FFI 库或几何库（如 Clipper 或 CGAL），仅凭借 MoonBit 语言核心能力与紧凑数据结构，独立实现了从 3D 网格模型到 3D 打印机固件执行 G-code 的完整管线：

1. **3D 网格解析与对齐**：支持标准二进制（Binary）和 ASCII 格式 `.stl` 文件解析，计算 3D 轴向包围盒（AABB），并自动将模型底部对齐到打印热床原点；
2. **截面几何求交**：在指定层高平面 $Z = z_i$ 上对三维三角面进行高效线性求交，提取二维相交线段；
3. **拓扑缝合与轮廓闭环**：基于 $\epsilon$-距离邻域匹配，将无序线段流式重组成严格封闭的连续多边形边界环；
4. **多边形壁厚偏置（Perimeter Inward Offsetting）**：基于角平分线法与尖角裁剪，配合边向量反转检验，生成稳定可靠的多层外壁（Perimeters）；
5. **扫描线线性填充（Scanline Infill Generation）**：支持经典 45° 与 135° 奇偶层交替的线性网格填充路径规划；
6. **挤出量物理建模与 G-code 合成**：严格依据扁平跑道截面（Stadium Cross-section）微积分建模计算耗材物理挤出量（E 值），输出 Marlin / RepRap / Klipper 标准 G-code 代码。

项目同时内置交互式 **HTML5 Canvas 刀路可视化工具（Toolpath Visualizer）**，可在浏览器中逐层拖动审视每一层的外壁、内壁、填充与空载移动轨迹。

---

## 2. 核心架构与模块划分

```
moonslicer/
├── types.mbt            # 切片配置参数、错误类型定义
├── geom.mbt             # 2D/3D 空间向量、线段、多边形几何与面积算法
├── stl.mbt              # IEEE 754 float32 解码、Binary/ASCII STL 解析器
├── slice.mbt            # 三角形-截面求交与拓扑线段环链式缝合
├── offset.mbt           # 角平分线向内多边形偏置与边翻转校验
├── infill.mbt           # 奇偶层 45°/135° 扫描线射线求交线性填充生成器
├── gcode.mbt            # 跑道截面挤出量微积分与标准 G-code 代码合成器
├── pipeline.mbt         # 端到端切片流程编排器与模型统计评估
├── cmd/main/            # 命令行工具 CLI (slice / info / help)
├── fixtures/            # 标准 20mm 校准立方体等测试模型
├── examples/            # HTML5 Canvas 交互式刀路切片可视化工具
└── docs/                # 计算几何数学模型与算法白皮书
```

详细数学原理与推导见：[docs/architecture.md](docs/architecture.md)。

---

## 3. 快速上手

### 3.1 环境要求
- [MoonBit 编译器工具链](https://www.moonbitlang.com/)（版本 >= v0.1.20260920）

### 3.2 运行自动化测试
```bash
# 执行全部 14 项白盒与黑盒单元测试
moon test
```

### 3.3 命令行工具 (CLI)

#### 查看 3D 模型元数据与尺寸
```bash
moon run cmd/main -- info -i fixtures/calibration_cube_ascii.stl
```
输出示例：
```
Mesh Inspection Report:
  Triangle Facets:   12
  Bounding Width (X):20 mm
  Bounding Depth (Y):20 mm
  Bounding Height (Z):20 mm
  Z Range:           [0, 20] mm
  Estimated Layers:  99 (at 0.2mm)
```

#### 对模型进行完整切片并输出 G-code
```bash
moon run cmd/main -- slice -i fixtures/calibration_cube_ascii.stl -o output.gcode \
  --layer-height 0.2 \
  --walls 2 \
  --density 0.15 \
  --speed 60.0
```
输出示例：
```
Slicing Completed Successfully!
  Output File:        output.gcode
  Total Layers:       99
  Filament Extruded:  1183.4 mm
  Est. Print Time:    6.3 min
```

---

## 4. 交互式可视化工具 (Visualizer)

在浏览器中直接双击打开 `examples/visualizer.html`，即可：
- 载入生成的 `.gcode` 文件；
- 拖动滑块查看每一层的二维打印刀路；
- 外壁（红色）、内壁（绿色）、网格填充（黄色）与空载移动（灰色虚线）多色分层呈现；
- 支持实时缩放、平移与自动播放切片动画。

---

## 5. 开源协议

本项目采用 [Apache-2.0](LICENSE) 开源协议。
