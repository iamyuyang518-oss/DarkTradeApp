// Generate a simple DarkTrade favicon as PNG (64x64)
// Uses only Node.js built-in modules — no external deps needed.

import { deflateSync } from 'node:zlib';
import { writeFileSync } from 'node:fs';

const SIZE = 64;
const R = 14; // corner radius

function createPNG(pixels, imgSize) {
  // Build raw filtered scanlines (filter byte 0 = None)
  const raw = Buffer.alloc(imgSize * (1 + imgSize * 4));
  for (let y = 0; y < imgSize; y++) {
    const offset = y * (1 + imgSize * 4);
    raw[offset] = 0; // filter: None
    for (let x = 0; x < imgSize; x++) {
      const pi = (y * imgSize + x) * 4;
      const ro = offset + 1 + x * 4;
      raw[ro] = pixels[pi];       // R
      raw[ro + 1] = pixels[pi + 1]; // G
      raw[ro + 2] = pixels[pi + 2]; // B
      raw[ro + 3] = pixels[pi + 3]; // A
    }
  }

  // Deflate
  const idat = deflateSync(raw, { level: 9 });

  // Chunk helper
  function chunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const typeB = Buffer.from(type, 'ascii');
    const crcInput = Buffer.concat([typeB, data]);

    // CRC32
    let crc = 0xFFFFFFFF;
    for (let i = 0; i < crcInput.length; i++) {
      crc ^= crcInput[i];
      for (let j = 0; j < 8; j++) {
        crc = (crc >>> 1) ^ (crc & 1 ? 0xEDB88320 : 0);
      }
    }
    crc = (crc ^ 0xFFFFFFFF) >>> 0;

    const crcB = Buffer.alloc(4);
    crcB.writeUInt32BE(crc);
    return Buffer.concat([len, typeB, data, crcB]);
  }

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(imgSize, 0);  // width
  ihdr.writeUInt32BE(imgSize, 4);  // height
  ihdr[8] = 8;   // bit depth
  ihdr[9] = 6;   // color type: RGBA
  ihdr[10] = 0;  // compression
  ihdr[11] = 0;  // filter
  ihdr[12] = 0;  // interlace

  // PNG signature
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
}

// Helper: is point inside rounded rectangle?
function inRoundedRect(x, y, w, h, r) {
  // Check if inside the main rectangle minus corners
  if (x >= r && x < w - r) return y >= 0 && y < h;
  if (y >= r && y < h - r) return x >= 0 && x < w;

  // Check four corners
  let cx, cy;
  if (x < r && y < r) { cx = r; cy = r; }
  else if (x >= w - r && y < r) { cx = w - r - 1; cy = r; }
  else if (x < r && y >= h - r) { cx = r; cy = h - r - 1; }
  else if (x >= w - r && y >= h - r) { cx = w - r - 1; cy = h - r - 1; }
  else return true;

  const dx = x - cx, dy = y - cy;
  return dx * dx + dy * dy <= r * r;
}

function blendRGBA(bg, fg) {
  const a = fg[3] / 255;
  return [
    Math.round(fg[0] * a + bg[0] * (1 - a)),
    Math.round(fg[1] * a + bg[1] * (1 - a)),
    Math.round(fg[2] * a + bg[2] * (1 - a)),
    255
  ];
}

// Draw
const pixels = new Uint8Array(SIZE * SIZE * 4);
const BG = [0xD4, 0xA8, 0x53, 255]; // #D4A853 amber gold
const BG_DARK = [0xC4, 0x96, 0x3E, 255]; // slightly darker
const WHITE = [255, 255, 255, 242]; // slightly transparent white

// Fill background with gradient (top to bottom)
for (let y = 0; y < SIZE; y++) {
  const t = y / SIZE;
  const bg = [
    Math.round(BG[0] * (1 - t) + BG_DARK[0] * t),
    Math.round(BG[1] * (1 - t) + BG_DARK[1] * t),
    Math.round(BG[2] * (1 - t) + BG_DARK[2] * t),
    255
  ];
  for (let x = 0; x < SIZE; x++) {
    const idx = (y * SIZE + x) * 4;
    if (inRoundedRect(x, y, SIZE, SIZE, R)) {
      pixels[idx] = bg[0];
      pixels[idx + 1] = bg[1];
      pixels[idx + 2] = bg[2];
      pixels[idx + 3] = 255;
    } else {
      pixels[idx] = 0;
      pixels[idx + 1] = 0;
      pixels[idx + 2] = 0;
      pixels[idx + 3] = 0;
    }
  }
}

// Draw candlestick icon
const cx = 32, cy = 32;
// Candle body: centered, about 14px tall, 8px wide
const bodyTop = 22, bodyBottom = 38, bodyLeft = 28, bodyRight = 36;

// Upper wick (vertical line above body)
for (let y = 8; y < bodyTop; y++) {
  for (let x = cx - 2; x <= cx + 2; x++) {
    if (x >= 0 && x < SIZE && y >= 0 && y < SIZE) {
      const idx = (y * SIZE + x) * 4;
      const blended = blendRGBA([pixels[idx], pixels[idx+1], pixels[idx+2], pixels[idx+3]], WHITE);
      pixels[idx] = blended[0];
      pixels[idx + 1] = blended[1];
      pixels[idx + 2] = blended[2];
      pixels[idx + 3] = blended[3];
    }
  }
}

// Lower wick (vertical line below body)
for (let y = bodyBottom; y < 48; y++) {
  for (let x = cx - 2; x <= cx + 2; x++) {
    if (x >= 0 && x < SIZE && y >= 0 && y < SIZE) {
      const idx = (y * SIZE + x) * 4;
      const blended = blendRGBA([pixels[idx], pixels[idx+1], pixels[idx+2], pixels[idx+3]], WHITE);
      pixels[idx] = blended[0];
      pixels[idx + 1] = blended[1];
      pixels[idx + 2] = blended[2];
      pixels[idx + 3] = blended[3];
    }
  }
}

// Candle body (green/positive candle = white body)
for (let y = bodyTop; y < bodyBottom; y++) {
  for (let x = bodyLeft; x <= bodyRight; x++) {
    if (x >= 0 && x < SIZE && y >= 0 && y < SIZE) {
      const idx = (y * SIZE + x) * 4;
      pixels[idx] = 255;
      pixels[idx + 1] = 255;
      pixels[idx + 2] = 255;
      pixels[idx + 3] = 245;
    }
  }
}

// Small upward arrow above the wick
const arrowTip = [cx, 4];
const arrowLeft = [cx - 8, 14];
const arrowRight = [cx + 8, 14];
const arrowBotCenter = [cx, 11];

// Simple triangle fill for the arrow
function fillTriangle(x1, y1, x2, y2, x3, y3) {
  // Bounding box
  const minX = Math.max(0, Math.min(x1, x2, x3));
  const maxX = Math.min(SIZE - 1, Math.max(x1, x2, x3));
  const minY = Math.max(0, Math.min(y1, y2, y3));
  const maxY = Math.min(SIZE - 1, Math.max(y1, y2, y3));

  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      if (pointInTriangle(x, y, x1, y1, x2, y2, x3, y3)) {
        const idx = (y * SIZE + x) * 4;
        const blended = blendRGBA([pixels[idx], pixels[idx+1], pixels[idx+2], pixels[idx+3]], [255, 255, 255, 230]);
        pixels[idx] = blended[0];
        pixels[idx + 1] = blended[1];
        pixels[idx + 2] = blended[2];
        pixels[idx + 3] = blended[3];
      }
    }
  }
}

function pointInTriangle(px, py, x1, y1, x2, y2, x3, y3) {
  const d1 = sign(px, py, x1, y1, x2, y2);
  const d2 = sign(px, py, x2, y2, x3, y3);
  const d3 = sign(px, py, x3, y3, x1, y1);
  const hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
  const hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
  return !(hasNeg && hasPos);
}

function sign(x1, y1, x2, y2, x3, y3) {
  return (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3);
}

fillTriangle(arrowTip[0], arrowTip[1], arrowLeft[0], arrowLeft[1], arrowRight[0], arrowRight[1]);

// Generate PNG
const png = createPNG(pixels, SIZE);

// Write to both locations
writeFileSync('web/favicon.png', png);
writeFileSync('build/web/favicon.png', png);

// Also generate 192x192 and 512x512 versions for PWA icons
function scalePixels(src, srcSize, dstSize) {
  const dst = new Uint8Array(dstSize * dstSize * 4);
  const scale = srcSize / dstSize;
  for (let y = 0; y < dstSize; y++) {
    for (let x = 0; x < dstSize; x++) {
      const sx = Math.floor(x * scale);
      const sy = Math.floor(y * scale);
      const si = (sy * srcSize + sx) * 4;
      const di = (y * dstSize + x) * 4;
      dst[di] = src[si];
      dst[di + 1] = src[si + 1];
      dst[di + 2] = src[si + 2];
      dst[di + 3] = src[si + 3];
    }
  }
  return dst;
}

// 192x192
const p192 = scalePixels(pixels, SIZE, 192);
writeFileSync('web/icons/Icon-192.png', createPNG(p192, 192));
writeFileSync('web/icons/Icon-maskable-192.png', createPNG(p192, 192));

// 512x512
const p512 = scalePixels(pixels, SIZE, 512);
writeFileSync('web/icons/Icon-512.png', createPNG(p512, 512));
writeFileSync('web/icons/Icon-maskable-512.png', createPNG(p512, 512));

console.log('✅ Favicon and icons generated successfully!');
console.log('  web/favicon.png (64x64)');
console.log('  web/icons/Icon-192.png (192x192)');
console.log('  web/icons/Icon-512.png (512x512)');
console.log('  web/icons/Icon-maskable-192.png');
console.log('  web/icons/Icon-maskable-512.png');
