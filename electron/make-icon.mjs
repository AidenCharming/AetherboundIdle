// Draws the PLACEHOLDER app icon and writes electron/assets/icon.ico (16 to 256 px) and icon.png (512 px).
//   node electron/make-icon.mjs
// It is generated maths, nothing traced or borrowed: a violet-to-teal rounded tile, a glowing "aether" orb, a thin ring
// and three small motes. Replace the two files (and stop using this script) when the designer has real art.
// No dependency: PNG is written with node's zlib, and an .ico can carry PNG images directly.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import zlib from 'node:zlib'

const outDir = path.join(path.dirname(fileURLToPath(import.meta.url)), 'assets')

const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t)
const clamp01 = (v) => Math.min(1, Math.max(0, v))
const smooth = (edge0, edge1, v) => {
  const t = clamp01((v - edge0) / (edge1 - edge0))
  return t * t * (3 - 2 * t)
}

const VIOLET = [43, 31, 92]
const TEAL = [15, 107, 115]
const GLOW = [232, 250, 255]
const RING = [140, 150, 255]

/** Colour of the icon at (u, v) in 0..1, as [r, g, b, a] with a in 0..1. */
function shade(u, v) {
  // Rounded tile.
  const r = 0.2
  const qx = Math.abs(u - 0.5) - (0.5 - r)
  const qy = Math.abs(v - 0.5) - (0.5 - r)
  const dist = Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r
  const alpha = 1 - smooth(-0.004, 0.004, dist)
  if (alpha <= 0) return [0, 0, 0, 0]

  let color = mix(VIOLET, TEAL, clamp01((v * 0.8 + u * 0.4) / 1.2))
  const dx = u - 0.5
  const dy = v - 0.5
  const d = Math.hypot(dx, dy)

  // Soft halo, then the orb itself.
  color = mix(color, GLOW, 0.35 * (1 - smooth(0.05, 0.42, d)))
  color = mix(color, GLOW, 1 - smooth(0.17, 0.215, d))
  // A ring around it, and three motes on the ring.
  color = mix(color, RING, 0.85 * (1 - smooth(0.012, 0.03, Math.abs(d - 0.33))))
  for (const angle of [-0.9, 1.9, 3.7]) {
    const md = Math.hypot(u - (0.5 + 0.33 * Math.cos(angle)), v - (0.5 + 0.33 * Math.sin(angle)))
    color = mix(color, GLOW, 1 - smooth(0.028, 0.045, md))
  }
  return [color[0], color[1], color[2], alpha]
}

/** RGBA pixels for a size x size icon, each averaged over a 4x4 grid so the edges are smooth. */
function render(size) {
  const samples = 4
  const px = Buffer.alloc(size * size * 4)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let r = 0
      let g = 0
      let b = 0
      let a = 0
      for (let sy = 0; sy < samples; sy++) {
        for (let sx = 0; sx < samples; sx++) {
          const c = shade((x + (sx + 0.5) / samples) / size, (y + (sy + 0.5) / samples) / size)
          r += c[0] * c[3]
          g += c[1] * c[3]
          b += c[2] * c[3]
          a += c[3]
        }
      }
      const n = samples * samples
      const o = (y * size + x) * 4
      px[o] = a > 0 ? Math.round(r / a) : 0
      px[o + 1] = a > 0 ? Math.round(g / a) : 0
      px[o + 2] = a > 0 ? Math.round(b / a) : 0
      px[o + 3] = Math.round((a / n) * 255)
    }
  }
  return px
}

const crcTable = Array.from({ length: 256 }, (_, n) => {
  let c = n
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
  return c >>> 0
})
const crc32 = (buf) => {
  let c = 0xffffffff
  for (const byte of buf) c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8)
  return (c ^ 0xffffffff) >>> 0
}

function png(size) {
  const chunk = (type, data) => {
    const head = Buffer.alloc(8)
    head.writeUInt32BE(data.length, 0)
    head.write(type, 4, 'ascii')
    const crc = Buffer.alloc(4)
    crc.writeUInt32BE(crc32(Buffer.concat([head.subarray(4), data])), 0)
    return Buffer.concat([head, data, crc])
  }
  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(size, 0)
  ihdr.writeUInt32BE(size, 4)
  ihdr[8] = 8 // bit depth
  ihdr[9] = 6 // RGBA
  const pixels = render(size)
  const rows = Buffer.alloc((size * 4 + 1) * size)
  for (let y = 0; y < size; y++) pixels.copy(rows, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4)
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(rows, { level: 9 })), chunk('IEND', Buffer.alloc(0))])
}

function ico(sizes) {
  const images = sizes.map(png)
  const header = Buffer.alloc(6)
  header.writeUInt16LE(1, 2) // type: icon
  header.writeUInt16LE(sizes.length, 4)
  const dir = Buffer.alloc(16 * sizes.length)
  let offset = header.length + dir.length
  sizes.forEach((size, i) => {
    dir[i * 16] = size === 256 ? 0 : size
    dir[i * 16 + 1] = size === 256 ? 0 : size
    dir.writeUInt16LE(1, i * 16 + 4) // colour planes
    dir.writeUInt16LE(32, i * 16 + 6) // bits per pixel
    dir.writeUInt32LE(images[i].length, i * 16 + 8)
    dir.writeUInt32LE(offset, i * 16 + 12)
    offset += images[i].length
  })
  return Buffer.concat([header, dir, ...images])
}

fs.mkdirSync(outDir, { recursive: true })
fs.writeFileSync(path.join(outDir, 'icon.ico'), ico([16, 32, 48, 64, 128, 256]))
fs.writeFileSync(path.join(outDir, 'icon.png'), png(512))
console.log(`Wrote ${path.join(outDir, 'icon.ico')} and icon.png`)
