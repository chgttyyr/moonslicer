///|
/// STL (Stereolithography) 3D mesh parser for binary and ASCII formats.

///|
pub(all) struct Triangle3 {
  normal : Vec3
  v1 : Vec3
  v2 : Vec3
  v3 : Vec3
} derive(Debug, Eq)

///|
pub fn Triangle3::new(
  normal : Vec3,
  v1 : Vec3,
  v2 : Vec3,
  v3 : Vec3,
) -> Triangle3 {
  { normal, v1, v2, v3, }
}

///|
pub fn Triangle3::min_z(self : Triangle3) -> Double {
  let mut min = self.v1.z
  if self.v2.z < min {
    min = self.v2.z
  }
  if self.v3.z < min {
    min = self.v3.z
  }
  min
}

///|
pub fn Triangle3::max_z(self : Triangle3) -> Double {
  let mut max = self.v1.z
  if self.v2.z > max {
    max = self.v2.z
  }
  if self.v3.z > max {
    max = self.v3.z
  }
  max
}

///|
pub(all) struct Mesh3 {
  triangles : Array[Triangle3]
  bounds : BBox3
} derive(Debug, Eq)

///|
/// Helper to compute 2^e for float32 decoding.
fn double_pow2(e : Int32) -> Double {
  let mut res = 1.0
  if e > 0 {
    for _i = 0; _i < e; _i = _i + 1 {
      res = res * 2.0
    }
  } else if e < 0 {
    let neg = -e
    for _i = 0; _i < neg; _i = _i + 1 {
      res = res * 0.5
    }
  }
  res
}

///|
/// Decode little-endian IEEE 754 32-bit float from bytes.
pub fn read_f32_le(data : Bytes, offset : Int32) -> Double {
  if offset + 4 > data.length() {
    return 0.0
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  let b2 = data[offset + 2].to_int()
  let b3 = data[offset + 3].to_int()
  let u = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
  let sign = if (u & (1 << 31)) != 0 { -1.0 } else { 1.0 }
  let exp = (u >> 23) & 0xFF
  let frac = u & 0x7FFFFF
  if exp == 0 {
    if frac == 0 {
      0.0
    } else {
      sign * (frac.to_double() / 8388608.0) * double_pow2(-126)
    }
  } else if exp == 255 {
    0.0
  } else {
    let val = 1.0 + frac.to_double() / 8388608.0
    let e = exp - 127
    sign * val * double_pow2(e)
  }
}

///|
/// Decode little-endian uint32.
pub fn read_u32_le(data : Bytes, offset : Int32) -> Int32 {
  if offset + 4 > data.length() {
    return 0
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  let b2 = data[offset + 2].to_int()
  let b3 = data[offset + 3].to_int()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
/// Construct a Mesh3 from an array of triangles and automatically compute its BBox3.
pub fn Mesh3::from_triangles(triangles : Array[Triangle3]) -> Mesh3 {
  if triangles.is_empty() {
    let zero = Vec3::zero()
    return { triangles, bounds: BBox3::new(zero, zero), }
  }

  let first = triangles[0].v1
  let mut min_x = first.x
  let mut max_x = first.x
  let mut min_y = first.y
  let mut max_y = first.y
  let mut min_z = first.z
  let mut max_z = first.z

  for tri in triangles {
    let vs = [tri.v1, tri.v2, tri.v3]
    for v in vs {
      if v.x < min_x {
        min_x = v.x
      }
      if v.x > max_x {
        max_x = v.x
      }
      if v.y < min_y {
        min_y = v.y
      }
      if v.y > max_y {
        max_y = v.y
      }
      if v.z < min_z {
        min_z = v.z
      }
      if v.z > max_z {
        max_z = v.z
      }
    }
  }

  let bounds = BBox3::new(
    Vec3::new(min_x, min_y, min_z),
    Vec3::new(max_x, max_y, max_z),
  )
  { triangles, bounds, }
}

///|
/// Center the mesh on the print bed: X/Y centered around (0,0), Z grounded at 0.0.
pub fn Mesh3::center_to_bed(self : Mesh3) -> Mesh3 {
  let center = self.bounds.center()
  let min_z = self.bounds.min.z

  let offset_x = -center.x
  let offset_y = -center.y
  let offset_z = -min_z

  let offset = Vec3::new(offset_x, offset_y, offset_z)

  let new_tris : Array[Triangle3] = []
  for tri in self.triangles {
    new_tris.push({
      normal: tri.normal,
      v1: tri.v1.add(offset),
      v2: tri.v2.add(offset),
      v3: tri.v3.add(offset),
    })
  }

  Mesh3::from_triangles(new_tris)
}

///|
/// Parse an STL file (binary or ASCII).
pub fn parse_stl(data : Bytes) -> Result[Mesh3, SlicerError] {
  if data.length() < 84 {
    return Err(InvalidStl("STL file is too short to be valid"))
  }

  // Check if Binary STL: Header (80 bytes) + uint32 triangle count (4 bytes)
  let num_triangles = read_u32_le(data, 80)
  let expected_binary_size = 84 + num_triangles * 50

  if expected_binary_size == data.length() && num_triangles > 0 {
    // Definite Binary STL
    let triangles : Array[Triangle3] = []
    let mut offset = 84

    for _i = 0; _i < num_triangles; _i = _i + 1 {
      let nx = read_f32_le(data, offset)
      let ny = read_f32_le(data, offset + 4)
      let nz = read_f32_le(data, offset + 8)
      let normal = Vec3::new(nx, ny, nz)

      let v1x = read_f32_le(data, offset + 12)
      let v1y = read_f32_le(data, offset + 16)
      let v1z = read_f32_le(data, offset + 20)
      let v1 = Vec3::new(v1x, v1y, v1z)

      let v2x = read_f32_le(data, offset + 24)
      let v2y = read_f32_le(data, offset + 28)
      let v2z = read_f32_le(data, offset + 32)
      let v2 = Vec3::new(v2x, v2y, v2z)

      let v3x = read_f32_le(data, offset + 36)
      let v3y = read_f32_le(data, offset + 40)
      let v3z = read_f32_le(data, offset + 44)
      let v3 = Vec3::new(v3x, v3y, v3z)

      triangles.push({ normal, v1, v2, v3, })
      offset += 50
    }

    Ok(Mesh3::from_triangles(triangles))
  } else {
    // Attempt ASCII STL parsing
    parse_ascii_stl(data)
  }
}

///|
/// Parse an ASCII STL file.
fn parse_ascii_stl(data : Bytes) -> Result[Mesh3, SlicerError] {
  // Convert bytes to string
  let sb = StringBuilder()
  for b in data {
    sb.write_char(b.to_int().unsafe_to_char())
  }
  let text = sb.to_string()
  let lines = text.split("\n")

  let triangles : Array[Triangle3] = []
  let mut normal = Vec3::zero()
  let vertices : Array[Vec3] = []

  for line_view in lines {
    let line = line_view.trim().to_owned()
    if line.has_prefix("facet normal") {
      let parts = line.split(" ")
      let nums : Array[Double] = []
      for p in parts {
        let s = p.trim().to_owned()
        if !s.is_empty() && s != "facet" && s != "normal" {
          match parse_double(s) {
            Some(v) => nums.push(v)
            None => ()
          }
        }
      }
      if nums.length() >= 3 {
        normal = Vec3::new(nums[0], nums[1], nums[2])
      }
    } else if line.has_prefix("vertex") {
      let parts = line.split(" ")
      let nums : Array[Double] = []
      for p in parts {
        let s = p.trim().to_owned()
        if !s.is_empty() && s != "vertex" {
          match parse_double(s) {
            Some(v) => nums.push(v)
            None => ()
          }
        }
      }
      if nums.length() >= 3 {
        vertices.push(Vec3::new(nums[0], nums[1], nums[2]))
      }
    } else if line.has_prefix("endfacet") {
      if vertices.length() >= 3 {
        triangles.push({
          normal,
          v1: vertices[0],
          v2: vertices[1],
          v3: vertices[2],
        })
      }
      vertices.clear()
    }
  }

  if triangles.is_empty() {
    Err(InvalidStl("No valid facets found in ASCII STL"))
  } else {
    Ok(Mesh3::from_triangles(triangles))
  }
}

///|
/// Helper to parse floating point string like "12.34", "-0.5", "1e-3".
fn parse_double(s : String) -> Double? {
  if s.is_empty() {
    return None
  }
  let mut sign = 1.0
  let mut idx = 0
  let chars : Array[Char] = []
  for c in s {
    chars.push(c)
  }

  if chars[0] == '-' {
    sign = -1.0
    idx += 1
  } else if chars[0] == '+' {
    idx += 1
  }

  let mut int_part = 0.0
  let mut frac_part = 0.0
  let mut frac_divisor = 1.0
  let mut in_frac = false
  let mut in_exp = false
  let mut exp_sign = 1.0
  let mut exp_val = 0

  while idx < chars.length() {
    let c = chars[idx]
    if c == '.' {
      in_frac = true
    } else if c == 'e' || c == 'E' {
      in_exp = true
      idx += 1
      if idx < chars.length() {
        if chars[idx] == '-' {
          exp_sign = -1.0
          idx += 1
        } else if chars[idx] == '+' {
          idx += 1
        }
      }
      continue
    } else if in_exp {
      let d = c.to_int() - '0'.to_int()
      if d >= 0 && d <= 9 {
        exp_val = exp_val * 10 + d
      }
    } else if in_frac {
      let d = c.to_int() - '0'.to_int()
      if d >= 0 && d <= 9 {
        frac_divisor = frac_divisor * 10.0
        frac_part = frac_part + d.to_double() / frac_divisor
      }
    } else {
      let d = c.to_int() - '0'.to_int()
      if d >= 0 && d <= 9 {
        int_part = int_part * 10.0 + d.to_double()
      }
    }
    idx += 1
  }

  let base = sign * (int_part + frac_part)
  if in_exp {
    let mut mult = 1.0
    for _i = 0; _i < exp_val; _i = _i + 1 {
      if exp_sign > 0.0 {
        mult = mult * 10.0
      } else {
        mult = mult / 10.0
      }
    }
    Some(base * mult)
  } else {
    Some(base)
  }
}
