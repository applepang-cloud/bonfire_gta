const fs=require('fs'),path=require('path');const {PNG}=require('pngjs');
const OUT=path.join(__dirname,'..','assets','images','build');
function cv(w,h){const p=new PNG({width:w,height:h});p.data.fill(0);return p;}
function px(p,x,y,c){if(x<0||y<0||x>=p.width||y>=p.height)return;const i=(y*p.width+x)*4;p.data[i]=c[0];p.data[i+1]=c[1];p.data[i+2]=c[2];p.data[i+3]=c.length>3?c[3]:255;}
function rect(p,x,y,w,h,c){for(let j=0;j<h;j++)for(let i=0;i<w;i++)px(p,x+i,y+j,c);}
function save(p,n){fs.writeFileSync(path.join(OUT,n),PNG.sync.write(p));console.log('build/'+n,p.width+'x'+p.height);}
const sh=(c,d)=>[Math.max(0,Math.min(255,c[0]+d)),Math.max(0,Math.min(255,c[1]+d)),Math.max(0,Math.min(255,c[2]+d))];
// 동굴 바닥(16) 어두운 돌
function floor(){const p=cv(16,16);const b=[58,54,62];rect(p,0,0,16,16,b);
 for(let y=0;y<16;y++)for(let x=0;x<16;x++){let c=b;const r=(x*7+y*13)%9;if(r===0)c=sh(b,-14);else if(r===4)c=sh(b,10);if((x===3&&y>5&&y<11)||(y===9&&x>8&&x<13))c=sh(b,-22);px(p,x,y,c);}
 save(p,'cave_floor.png');}
// 동굴 벽(16) 검은 바위
function wall(){const p=cv(16,16);const b=[34,30,38];rect(p,0,0,16,16,b);
 for(let y=0;y<16;y+=8)rect(p,0,y,16,1,sh(b,-12));
 for(let y=0;y<16;y++)for(let x=0;x<16;x++){const off=Math.floor(y/8)%2?8:0;if((x+off)%8===0)px(p,x,y,sh(b,-12));else if((x+off)%8===1||y%8===1)px(p,x,y,sh(b,12));}
 save(p,'cave_wall.png');}
// 동굴 입구(32) 풀밭 위 바위 + 검은 아치
function entrance(){const p=cv(32,32);
 // 바위 더미
 const rock=[96,90,86];
 for(let y=6;y<32;y++)for(let x=2;x<30;x++){const dx=(x-16)/14,dy=(y-20)/13;if(dx*dx+dy*dy<=1){let c=rock;if(((x*5+y*3)%11)===0)c=sh(rock,-18);else if(((x+y)%9)===0)c=sh(rock,14);px(p,x,y,c);}}
 // 검은 입구 아치
 for(let y=14;y<31;y++)for(let x=10;x<22;x++){const dx=(x-16)/6,dy=(y-30)/16;if(dx*dx+dy*dy<=1)px(p,x,y,[8,6,12]);}
 // 아치 테두리
 for(let a=0;a<180;a++){const r=6.2;const x=Math.round(16+Math.cos(a*Math.PI/180)*r);const y=Math.round(30-Math.sin(a*Math.PI/180)*15.2/6.2*r);px(p,x,y,[40,34,40]);}
 save(p,'cave_entrance.png');}
// 계단(16) 아래로
function stairs(){const p=cv(16,16);const b=[70,66,74];rect(p,0,0,16,16,[40,36,44]);
 for(let i=0;i<4;i++){rect(p,2,3+i*3,12-i*2,2,sh(b,-i*8));}
 save(p,'stairs_down.png');}
floor();wall();entrance();stairs();console.log('done');
