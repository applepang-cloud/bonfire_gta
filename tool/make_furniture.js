// 집 내부 가구를 픽셀아트로 생성: 침대, 벽난로, 의자, 화분.
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const OUT = path.join(__dirname, '..', 'assets', 'images', 'build');
fs.mkdirSync(OUT, { recursive: true });

function canvas(w, h) { const p = new PNG({ width: w, height: h }); p.data.fill(0); return p; }
function px(p, x, y, c) {
  if (x < 0 || y < 0 || x >= p.width || y >= p.height) return;
  const i = (y * p.width + x) * 4;
  p.data[i] = c[0]; p.data[i + 1] = c[1]; p.data[i + 2] = c[2]; p.data[i + 3] = c.length > 3 ? c[3] : 255;
}
function rect(p, x, y, w, h, c) { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) px(p, x + i, y + j, c); }
function save(p, n) { fs.writeFileSync(path.join(OUT, n), PNG.sync.write(p)); console.log('build/' + n, p.width + 'x' + p.height); }
const sh = (c, d) => [Math.max(0, Math.min(255, c[0] + d)), Math.max(0, Math.min(255, c[1] + d)), Math.max(0, Math.min(255, c[2] + d))];
const OUTL = [40, 28, 20];

// 침대 28x18 (가로). 머리판 왼쪽.
function bed() {
  const p = canvas(28, 18);
  const wood = [120, 80, 46];
  rect(p, 0, 2, 28, 15, wood);            // 프레임
  rect(p, 0, 2, 4, 15, sh(wood, -20));    // 머리판
  rect(p, 24, 4, 4, 13, sh(wood, -20));   // 발판
  const sheet = [225, 220, 210];
  rect(p, 4, 4, 20, 11, sheet);           // 매트리스
  const blanket = [120, 60, 70];
  rect(p, 12, 4, 12, 11, blanket);        // 이불
  rect(p, 12, 4, 12, 2, sh(blanket, 25));
  const pillow = [245, 245, 250];
  rect(p, 5, 5, 6, 8, pillow);            // 베개
  // 외곽선
  for (let x = 0; x < 28; x++) { px(p, x, 2, OUTL); px(p, x, 16, OUTL); }
  for (let y = 2; y < 17; y++) { px(p, 0, y, OUTL); px(p, 27, y, OUTL); }
  save(p, 'bed.png');
}

// 벽난로 16x22 (위쪽 벽에 붙임). 돌 + 불.
function hearth() {
  const p = canvas(16, 22);
  const stone = [120, 120, 130];
  rect(p, 0, 0, 16, 22, stone);
  for (let y = 0; y < 22; y += 4) rect(p, 0, y, 16, 1, sh(stone, -30));
  rect(p, 3, 9, 10, 11, [20, 16, 14]);     // 아궁이
  // 장작
  rect(p, 4, 17, 8, 2, [90, 60, 36]);
  // 불꽃
  rect(p, 5, 13, 6, 5, [230, 120, 30]);
  rect(p, 6, 11, 4, 5, [250, 190, 60]);
  rect(p, 7, 10, 2, 3, [255, 240, 160]);
  // 외곽선
  for (let x = 0; x < 16; x++) { px(p, x, 0, OUTL); px(p, x, 21, OUTL); }
  for (let y = 0; y < 22; y++) { px(p, 0, y, OUTL); px(p, 15, y, OUTL); }
  save(p, 'hearth.png');
}

// 의자 10x12.
function chair() {
  const p = canvas(10, 12);
  const wood = [122, 84, 48];
  rect(p, 1, 1, 8, 3, sh(wood, -10)); // 등받이
  rect(p, 1, 4, 8, 3, wood);          // 좌석
  rect(p, 1, 7, 2, 4, sh(wood, -25)); // 다리
  rect(p, 7, 7, 2, 4, sh(wood, -25));
  save(p, 'chair.png');
}

// 화분 12x14.
function plant() {
  const p = canvas(12, 14);
  rect(p, 3, 9, 6, 5, [150, 90, 60]);     // 화분
  rect(p, 3, 9, 6, 1, [180, 110, 75]);
  rect(p, 2, 2, 8, 8, [70, 130, 70]);     // 잎
  rect(p, 4, 0, 4, 6, [90, 160, 90]);
  save(p, 'plant.png');
}

bed(); hearth(); chair(); plant();
console.log('done');
