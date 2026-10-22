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

给定一个 3D 网格模型文件（支持二进制与 ASCII 格式的 `.stl` 文件），MoonSlicer 能够在纯内存中执行以下完整计算几何切片管线：
1. **3D 三角面相交求交**：在指定层高平面 $Z = z_i$ 上计算相交线段；
2. **拓扑缝合与轮廓闭环**：将无序线段自动链式缝合成连续封闭多边形轮廓环（Loop Stitching）；
3. **轮廓内外层级树与奇偶校验**：自动识别区分外壁（Counter-Clockwise）与内孔洞（Clockwise）；
4. **多边形壁厚偏置（Perimeter Inward Offsetting）**：基于角平分线法与尖角裁剪生成 1~N 层打印外壁；
5. **扫描线线性填充（Scanline Infill Generation）**：支持经典 45°/135° 交替线性填充路径规划；
6. **挤出量体积微积分与 G-code 合成**：严格依据喷嘴孔径、层高与线宽计算物理挤出量（E 值），输出符合 Marlin / RepRap / Klipper 标准的可执行 G-code 代码。
