(function(){
const cv=document.getElementById('c3d');if(!cv||!window.THREE)return;const T=THREE;
const sc=new T.Scene();sc.background=new T.Color(0x0e1236);
const cam=new T.PerspectiveCamera(48,1,.1,120),rd=new T.WebGLRenderer({canvas:cv,antialias:true});
sc.add(new T.AmbientLight(0xffffff,.75));const sun=new T.DirectionalLight(0xffffff,.9);sun.position.set(9,18,12);sc.add(sun);
const M=(c,o)=>new T.MeshStandardMaterial(Object.assign({color:c,roughness:.6},o||{}));
const bx=(w,h,d,c,x,y,z)=>{const m=new T.Mesh(new T.BoxGeometry(w,h,d),M(c));m.position.set(x,y,z);sc.add(m);return m};
[[-4,3.5,0xf1ecff],[4,3.5,0xffeadb],[-4,-3.5,0xdcf7ea],[4,-3.5,0xe3eeff]].forEach(([x,z,c])=>bx(8,.2,7,c,x,-.1,z));
const W=0x7c83ff;bx(16,1.8,.3,W,0,.9,-7);bx(16,1.8,.3,W,0,.9,7);bx(.3,1.8,14,W,-8,.9,0);bx(.3,1.8,14,W,8,.9,0);
[[-7,-5],[-3,3],[5,7]].forEach(([a,b])=>bx(.3,1.8,b-a,W,0,.9,(a+b)/2));
bx(3,.7,1.2,0xf472b6,-4,.35,6.1);bx(2.4,.5,3.2,0xa78bfa,5,.25,-5);bx(2.4,.9,1.2,0xfbbf24,5,.45,6.2);bx(1.6,.8,1.6,0x34d399,-5,.4,-5.5);
const dv={luz:[]};
[[-4,3.5],[4,3.5],[4,-3.5],[-4,-3.5]].forEach(([x,z])=>{const m=new T.Mesh(new T.SphereGeometry(.35,16,16),M(0xfde68a,{emissive:0xfbbf24,emissiveIntensity:1}));m.position.set(x,2.6,z);sc.add(m);dv.luz.push(m)});
dv.ac=bx(.3,.9,1.2,0x9ca3af,-7.7,1.1,0);dv.lock=bx(.3,.9,.5,0x22c55e,7.7,.9,0);dv.mov=bx(.6,.3,.3,0xf59e0b,0,1.6,6.7);
dv.cam=new T.Mesh(new T.ConeGeometry(.35,.8,12),M(0x38bdf8));dv.cam.position.set(7.4,1.6,-6.4);dv.cam.rotation.z=Math.PI/2;sc.add(dv.cam);
const dock=new T.Mesh(new T.CylinderGeometry(.9,.9,.1,24),M(0x22c55e,{emissive:0x16a34a}));dock.position.set(-7,.05,5.8);sc.add(dock);
const rb=new T.Group(),eyeM=new T.MeshBasicMaterial({color:0x67e8f9});
const part=(g,c,x,y,z)=>{const m=new T.Mesh(g,M(c));m.position.set(x,y,z);rb.add(m);return m};
part(new T.CylinderGeometry(.5,.6,.9,20),0x6366f1,0,.55,0);part(new T.BoxGeometry(.8,.55,.7),0x8b5cf6,0,1.3,0);part(new T.CylinderGeometry(.03,.03,.35),0xf472b6,0,1.75,0);
[-.2,.2].forEach(x=>{const e=new T.Mesh(new T.SphereGeometry(.09,10,10),eyeM);e.position.set(x,1.32,.36);rb.add(e)});
[-.55,.55].forEach(x=>{const w=part(new T.CylinderGeometry(.22,.22,.15,16),0x1e1b4b,x,.22,0);w.rotation.z=Math.PI/2});
const cone=new T.Mesh(new T.ConeGeometry(.9,2.4,16,1,true),new T.MeshBasicMaterial({color:0x22d3a6,transparent:true,opacity:.28,side:2}));cone.rotation.x=-Math.PI/2;cone.position.set(0,.9,1.4);rb.add(cone);
rb.position.set(-6,0,4);sc.add(rb);
const P=[[-6,4],[6,4],[6,-4],[-6,-4]],L=[12,8,12,8],obs=[];
function pos(t){let d=(t%1)*40,i=0;while(d>L[i]){d-=L[i];i++}const a=P[i],b=P[(i+1)%4];return{x:a[0]+(b[0]-a[0])*d/L[i],z:a[1]+(b[1]-a[1])*d/L[i],h:Math.atan2(b[0]-a[0],b[1]-a[1])}}
let rot=.6,el=.6,drag=null,tgt={chg:false,t:0};
window.TWIN={update(K,H){const ok=!K.dev.some(d=>d.s!=='ONLINE'),s=K.dev.find(d=>d.n==='Sensor de distancia');eyeM.color.set(ok?0x67e8f9:0xff5d73);
let li=0;H.forEach(h=>{const c=h.on;if(h.t==='luz'){const m=dv.luz[li++];if(m){m.material.emissiveIntensity=c?1:0;m.material.color.set(c?0xfde68a:0x6b7280)}}
else if(h.t==='lock')dv.lock.material.color.set(c?0x22c55e:0xf97316);else if(h.t==='cam')dv.cam.material.color.set(c?0x38bdf8:0x6b7280);
else if(h.t==='mov')dv.mov.material.color.set(c?0xf59e0b:0x6b7280);else if(h.t==='ac')dv.ac.material.color.set(c?0x60a5fa:0x9ca3af)});
cone.material.color.set(s&&s.s==='ONLINE'?0x22d3a6:0x6b7280);
if(!obs.length)OB.forEach(o=>{const p=pos(o/360);obs.push(bx(.8,.8,.8,0xef4444,p.x,.4,p.z))});
tgt={chg:K.chg,t:K.ang/360}}};
cv.addEventListener('pointerdown',e=>{drag=[e.clientX,e.clientY]});addEventListener('pointerup',()=>{drag=null});
cv.addEventListener('pointermove',e=>{if(drag){rot-=(e.clientX-drag[0])*.008;el=Math.min(1.3,Math.max(.25,el+(e.clientY-drag[1])*.006));drag=[e.clientX,e.clientY]}});
(function loop(){requestAnimationFrame(loop);const w=cv.clientWidth,h=cv.clientHeight;if(!w||!h)return;
if(cv.width!==w||cv.height!==h){rd.setSize(w,h,false);cam.aspect=w/h;cam.updateProjectionMatrix()}
const g=tgt.chg?{x:-7,z:5.8,h:Math.PI}:pos(tgt.t);rb.position.x+=(g.x-rb.position.x)*.08;rb.position.z+=(g.z-rb.position.z)*.08;
let d=g.h-rb.rotation.y;d=Math.atan2(Math.sin(d),Math.cos(d));rb.rotation.y+=d*.1;
if(!drag)rot+=.0015;cam.position.set(22*Math.sin(rot)*Math.cos(el),22*Math.sin(el),22*Math.cos(rot)*Math.cos(el));cam.lookAt(0,0,0);rd.render(sc,cam)})();
})();
