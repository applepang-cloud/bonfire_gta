// 중세 판타지 집(외부) + 인테리어 타일을 픽셀아트로 직접 생성.
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const OUT = path.join(__dirname, '..', 'assets', 'images', 'build');
fs.mkdirSync(OUT, { recursive: true });

function canvas(w, h) {
  const p = new PNG({ width: w, height: h });
  p.data.fill(0);
  return p;
}
function px(p, x, y, c) {
  if (x < 0 || y < 0 || x >= p.width || y >= p.height) return;
  const i = (y * p.width + x) * 4;
  p.data[i] = c[0]; p.data[i + 1] = c[1]; p.data[i + 2] = c[2];
  p.data[i + 3] = c.length > 3 ? c[3] : 255;
}
function rect(p, x, y, w, h, c) {
  for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) px(p, x + i, y + j, c);
}
function save(p, name) {
  fs.writeFileSync(path.join(OUT, name), PNG.sync.write(p));
  console.log('wrote build/' + name, p.width + 'x' + p.height);
}
const shade = (c, d) => [
  Math.max(0, Math.min(255, c[0] + d)),
  Math.max(0, Math.min(255, c[1] + d)),
  Math.max(0, Math.min(255, c[2] + d)),
];

// ---------- 집 (48 x 56) ----------
// roof: 지붕색, wall: 벽돌/목재
function house(roof, name) {
  const W = 48, H = 56;
  const p = canvas(W, H);
  const wall = [196, 180, 150];     // 미색 회벽
  const wallDk = shade(wall, -45);
  const beam = [92, 64, 40];        // 목재 빔
  const outline = [40, 28, 20];

  // 벽 (y=22..55, x=5..43)
  rect(p, 5, 22, 38, 33, wall);
  // 벽돌/석재 질감 (가로줄)
  for (let y = 24; y < 54; y += 4) rect(p, 6, y, 36, 1, wallDk);
  // 모서리 목재 기둥
  rect(p, 5, 22, 3, 33, beam);
  rect(p, 40, 22, 3, 33, beam);
  rect(p, 5, 52, 38, 3, beam); // 토대
  // 벽 외곽선
  for (let x = 5; x < 43; x++) { px(p, x, 22, outline); px(p, x, 54, outline); }
  for (let y = 22; y < 55; y++) { px(p, 5, y, outline); px(p, 42, y, outline); }

  // 지붕 (박공). y=2..24, 중앙 24
  const roofDk = shade(roof, -40), roofLt = shade(roof, 35);
  for (let y = 2; y <= 23; y++) {
    const hw = Math.round(((y - 2) / 21) * 25) + 1; // 반폭 1..26
    const x0 = 24 - hw, x1 = 24 + hw;
    for (let x = x0; x <= x1; x++) {
      let c = roof;
      if (x < x0 + 2 || x > x1 - 2) c = roofDk;        // 가장자리 음영
      else if (y < 8) c = roofLt;                       // 위쪽 하이라이트
      else if ((x + y) % 6 === 0) c = roofDk;           // 기와 결
      px(p, x, y, c);
    }
    px(p, x0, y, outline); px(p, x1, y, outline);       // 지붕 외곽선
  }
  rect(p, 2, 23, 44, 2, shade(roof, -60));              // 처마
  px(p, 24, 2, outline);

  // 문 (x=19..29, y=38..55)
  const door = [78, 50, 28];
  rect(p, 19, 38, 10, 17, door);
  rect(p, 19, 38, 10, 1, outline);
  for (let y = 38; y < 55; y++) { px(p, 19, y, outline); px(p, 28, y, outline); px(p, 24, y, shade(door, -30)); }
  rect(p, 23, 38, 2, 6, shade(door, 25)); // 아치 빛
  px(p, 26, 47, [230, 200, 90]);          // 손잡이

  // 창문 2개 (좌/우)
  const glass = [120, 170, 200];
  [9, 33].forEach((wx) => {
    rect(p, wx, 28, 7, 7, glass);
    rect(p, wx, 28, 7, 1, outline); rect(p, wx, 34, 7, 1, outline);
    rect(p, wx, 28, 1, 7, outline); rect(p, wx + 6, 28, 1, 7, outline);
    rect(p, wx + 3, 28, 1, 7, [90, 64, 40]); rect(p, wx, 31, 7, 1, [90, 64, 40]);
  });

  save(p, name);
}

house([170, 60, 50], 'house_red.png');     // 붉은 기와
house([86, 120, 70], 'house_green.png');   // 이끼 초록
house([150, 120, 70], 'house_thatch.png'); // 초가

// ---------- 인테리어 타일 (16x16) ----------
function floorWood() {
  const p = canvas(16, 16);
  const base = [120, 84, 52];
  rect(p, 0, 0, 16, 16, base);
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    let c = base;
    if (y % 5 === 0) c = shade(base, -25);                // 판자 경계
    else if ((x + Math.floor(y / 5) * 7) % 9 === 0) c = shade(base, 14);
    px(p, x, y, c);
  }
  save(p, 'floor_wood.png');
}
function wallStone() {
  const p = canvas(16, 16);
  const base = [110, 110, 120];
  rect(p, 0, 0, 16, 16, base);
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    let c = base;
    if (y % 8 === 0) c = shade(base, -35);
    const off = Math.floor(y / 8) % 2 === 0 ? 0 : 8;
    if ((x + off) % 8 === 0) c = shade(base, -35);
    else if (y % 8 === 1 || (x + off) % 8 === 1) c = shade(base, 20);
    px(p, x, y, c);
  }
  save(p, 'wall_stone.png');
}
function rug() {
  const p = canvas(16, 16);
  rect(p, 1, 2, 14, 12, [140, 50, 50]);
  rect(p, 2, 3, 12, 10, [170, 70, 60]);
  rect(p, 4, 5, 8, 6, [200, 160, 80]);
  save(p, 'rug.png');
}
floorWood();
wallStone();
rug();
console.log('done');
