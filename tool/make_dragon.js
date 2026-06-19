const fs=require('fs'),path=require('path');const {PNG}=require('pngjs');
const OUT=path.join(__dirname,'..','assets','images','build');
function px(p,x,y,c){x|=0;y|=0;if(x<0||y<0||x>=p.width||y>=p.height)return;const i=(y*p.width+x)*4;p.data[i]=c[0];p.data[i+1]=c[1];p.data[i+2]=c[2];p.data[i+3]=c.length>3?c[3]:255;}
function rect(p,x,y,w,h,c){for(let j=0;j<h;j++)for(let i=0;i<w;i++)px(p,x+i,y+j,c);}
function ellipse(p,cx,cy,rx,ry,c){for(let y=-ry;y<=ry;y++)for(let x=-rx;x<=rx;x++){if((x*x)/(rx*rx)+(y*y)/(ry*ry)<=1)px(p,cx+x,cy+y,c);}}
function tri(p,ax,ay,bx,by,cx,cy,c){const minx=Math.min(ax,bx,cx),maxx=Math.max(ax,bx,cx),miny=Math.min(ay,by,cy),maxy=Math.max(ay,by,cy);
 const s=(x,y,x1,y1,x2,y2)=>(x1-x)*(y2-y)-(x2-x)*(y1-y);
 for(let y=miny;y<=maxy;y++)for(let x=minx;x<=maxx;x++){const d1=s(x,y,ax,ay,bx,by),d2=s(x,y,bx,by,cx,cy),d3=s(x,y,cx,cy,ax,ay);const neg=(d1<0)||(d2<0)||(d3<0),pos=(d1>0)||(d2>0)||(d3>0);if(!(neg&&pos))px(p,x,y,c);}}
const BODY=[150,46,46],DK=[104,28,28],BELLY=[205,128,96],WING=[120,34,42],WINGDK=[80,22,30],HORN=[235,225,200],EYE=[255,225,90],OL=[36,16,18];
// side view dragon facing RIGHT, frame: wingUp(0/1). canvas 64x64
function frame(p,ox,wingUp){
 // tail (left, curling)
 tri(p,ox+2,52,ox+14,40,ox+16,48,DK);
 rect(p,ox+10,38,12,8,BODY);
 // body
 ellipse(p,ox+30,38,16,11,BODY);
 ellipse(p,ox+30,42,14,7,BELLY);
 // back legs
 rect(p,ox+22,46,5,9,DK);rect(p,ox+36,46,5,9,DK);
 px(p,ox+22,55,OL);px(p,ox+40,55,OL);
 // neck + head (right)
 tri(p,ox+40,32,ox+52,18,ox+46,36,BODY);
 ellipse(p,ox+54,20,8,6,BODY);          // head
 tri(p,ox+60,18,ox+64,21,ox+59,23,BODY);// snout
 px(p,ox+57,18,EYE);px(p,ox+58,18,OL);
 tri(p,ox+50,14,ox+52,6,ox+54,14,HORN); // horn1
 tri(p,ox+54,14,ox+56,7,ox+58,14,HORN); // horn2
 // wing (big, behind/above body)
 const ty = wingUp? 4 : 22;
 tri(p,ox+26,30,ox+14,ty,ox+40,ty+4,WING);
 tri(p,ox+26,30,ox+40,ty+4,ox+38,30,WINGDK);
 // wing ribs
 for(let k=0;k<3;k++){const tx=ox+18+k*7;px(p,tx,ty+6,WINGDK);px(p,tx+1,ty+8,WINGDK);}
 // outline-ish darker bottom
 rect(p,ox+16,49,28,1,OL);
}
const sheet=new PNG({width:128,height:64});sheet.data.fill(0);
frame(sheet,0,true);
frame(sheet,64,false);
fs.writeFileSync(path.join(OUT,'dragon.png'),PNG.sync.write(sheet));
console.log('build/dragon.png 128x64 (2 frames 64x64)');
// preview x4
const sc=4,M=new PNG({width:128*sc,height:64*sc});for(let i=0;i<M.data.length;i+=4){M.data[i]=24;M.data[i+1]=20;M.data[i+2]=28;M.data[i+3]=255;}
for(let j=0;j<64;j++)for(let i=0;i<128;i++){const si=(j*128+i)*4;if(sheet.data[si+3]<10)continue;for(let sy=0;sy<sc;sy++)for(let sx=0;sx<sc;sx++){const X=i*sc+sx,Y=j*sc+sy;const di=(Y*128*sc+X)*4;for(let k=0;k<3;k++)M.data[di+k]=sheet.data[si+k];M.data[di+3]=255;}}
fs.writeFileSync('preview_dragon.png',PNG.sync.write(M));
