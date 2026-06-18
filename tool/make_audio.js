// 중세 판타지 게임용 오디오 합성기 (외부 의존성 없음, 순수 PCM WAV).
// BGM 루프 + 효과음(검 휘두름/타격/획득/경보)을 assets/audio 로 생성.
const fs = require('fs');
const path = require('path');

const SR = 44100;
const OUT = path.join(__dirname, '..', 'assets', 'audio');
fs.mkdirSync(OUT, { recursive: true });

function writeWav(name, samples) {
  const n = samples.length;
  const buf = Buffer.alloc(44 + n * 2);
  buf.write('RIFF', 0);
  buf.writeUInt32LE(36 + n * 2, 4);
  buf.write('WAVE', 8);
  buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20); // PCM
  buf.writeUInt16LE(1, 22); // mono
  buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write('data', 36);
  buf.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    let s = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE((s * 32767) | 0, 44 + i * 2);
  }
  fs.writeFileSync(path.join(OUT, name), buf);
  console.log('wrote', name, (n / SR).toFixed(2) + 's');
}

const noise = () => Math.random() * 2 - 1;
// 1극 로우패스
function lp(arr, a) {
  let y = 0;
  for (let i = 0; i < arr.length; i++) {
    y += a * (arr[i] - y);
    arr[i] = y;
  }
  return arr;
}

// 음 이름 → 주파수
const A4 = 440;
function note(semisFromA4) {
  return A4 * Math.pow(2, semisFromA4 / 12);
}

// ---------- BGM: 중세풍 류트 아르페지오 + 패드 (Am–F–C–G) ----------
function makeBgm() {
  const bpm = 92;
  const beat = 60 / bpm;
  const bars = 8;
  const total = Math.round(bars * 4 * beat * SR);
  const out = new Float32Array(total);

  // 코드(반음, A4 기준): Am, F, C, G — 각 2박씩 두 번 = 8마디
  const prog = [
    [-12, -9, -5], // Am (A2 C3 E3 단순화)
    [-16, -9, -4], // F
    [-9, -5, 0], // C
    [-14, -10, -3], // G
  ];

  // 패드(부드러운 화음)
  for (let i = 0; i < total; i++) {
    const t = i / SR;
    const barLen = 4 * beat;
    const chordIdx = Math.floor(t / (barLen * 2)) % prog.length;
    const ch = prog[chordIdx];
    let s = 0;
    for (const semi of ch) {
      const f = note(semi) / 2; // 한 옥타브 낮게
      s += Math.sin(2 * Math.PI * f * t);
    }
    s /= ch.length;
    // 부드러운 비브라토 + 전체 페이드 인/아웃 루프 매끄럽게
    s *= 0.10;
    out[i] += s;
  }

  // 류트 아르페지오(플럭, 지수 감쇠)
  const arpStep = beat / 2; // 8분음
  const steps = Math.floor(total / SR / arpStep);
  for (let k = 0; k < steps; k++) {
    const tStart = k * arpStep;
    const barLen = 4 * beat;
    const chordIdx = Math.floor(tStart / (barLen * 2)) % prog.length;
    const ch = prog[chordIdx];
    const semi = ch[k % ch.length] + 12; // 한 옥타브 위
    const f = note(semi);
    const dur = arpStep * 1.6;
    const start = Math.floor(tStart * SR);
    const len = Math.floor(dur * SR);
    for (let j = 0; j < len && start + j < total; j++) {
      const tt = j / SR;
      const env = Math.exp(-tt * 6.5);
      // 삼각파 비슷하게 (홀수 배음)
      const v =
        Math.sin(2 * Math.PI * f * tt) +
        0.3 * Math.sin(2 * Math.PI * f * 2 * tt) +
        0.15 * Math.sin(2 * Math.PI * f * 3 * tt);
      out[start + j] += (v / 1.45) * env * 0.16;
    }
  }

  // 루프 경계 크로스페이드(앞/뒤 0.05초)
  const fade = Math.floor(0.06 * SR);
  for (let i = 0; i < fade; i++) {
    const g = i / fade;
    out[i] *= g;
    out[total - 1 - i] *= g;
  }
  writeWav('bgm.wav', out);
}

// ---------- 검 휘두름 (whoosh) ----------
function makeSwing() {
  const len = Math.floor(0.22 * SR);
  const out = new Float32Array(len);
  const n = new Float32Array(len);
  for (let i = 0; i < len; i++) n[i] = noise();
  lp(n, 0.10);
  for (let i = 0; i < len; i++) {
    const t = i / len;
    const env = Math.sin(Math.PI * t) * Math.exp(-t * 1.5);
    out[i] = n[i] * env * 0.7;
  }
  writeWav('swing.wav', out);
}

// ---------- 타격 (thud + clink) ----------
function makeHit() {
  const len = Math.floor(0.16 * SR);
  const out = new Float32Array(len);
  for (let i = 0; i < len; i++) {
    const t = i / SR;
    const env = Math.exp(-t * 28);
    const low = Math.sin(2 * Math.PI * 140 * t);
    const clink = Math.sin(2 * Math.PI * 900 * t) * Math.exp(-t * 60);
    out[i] = (low * 0.8 + clink * 0.5 + noise() * 0.3) * env;
  }
  writeWav('hit.wav', out);
}

// ---------- 획득 (coin) ----------
function makeCoin() {
  const out = new Float32Array(Math.floor(0.26 * SR));
  const blips = [988, 1319]; // B5, E6
  blips.forEach((f, bi) => {
    const start = Math.floor(bi * 0.07 * SR);
    const len = Math.floor(0.18 * SR);
    for (let j = 0; j < len && start + j < out.length; j++) {
      const t = j / SR;
      const env = Math.exp(-t * 12);
      out[start + j] += Math.sin(2 * Math.PI * f * t) * env * 0.4;
    }
  });
  writeWav('coin.wav', out);
}

// ---------- 경보 (guard alert sting) ----------
function makeAlarm() {
  const len = Math.floor(0.45 * SR);
  const out = new Float32Array(len);
  const tones = [392, 523]; // G4 -> C5
  for (let i = 0; i < len; i++) {
    const t = i / SR;
    const seg = t < 0.2 ? 0 : 1;
    const f = tones[seg];
    const env = Math.min(1, t * 20) * Math.exp(-Math.max(0, t - 0.2) * 3);
    out[i] = (Math.sin(2 * Math.PI * f * t) +
      0.4 * Math.sin(2 * Math.PI * f * 2 * t)) * env * 0.3;
  }
  writeWav('alarm.wav', out);
}

makeBgm();
makeSwing();
makeHit();
makeCoin();
makeAlarm();
console.log('done');
