// Tests poussés du chat Hametkro.
// Charge le VRAI code source (webapp/index.html) dans une VM Node avec des
// stubs DOM/Firebase, puis exerce les fonctions du chat.
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const html = fs.readFileSync(__dirname + '/../webapp/index.html', 'utf8');
const blocks = html.match(/<script>([\s\S]*?)<\/script>/g) || [];
const main = blocks.find(b => b.includes('DÉMARRAGE'));
if (!main) { console.error('script principal introuvable'); process.exit(1); }
const src = main.replace(/^<script>/,'').replace(/<\/script>$/,'');

const storage = {};
const els = {};
const documentStub = {
  getElementById: (id)=>{ if(!els[id]) els[id]={ innerHTML:'', style:{}, value:'', scrollTop:0, scrollHeight:0, clientHeight:0 }; return els[id]; },
  querySelector: () => null,
  createElement: () => ({ style:{}, getContext:()=>null }),
  documentElement: { scrollTop: 0, scrollHeight: 0, clientHeight: 0 },
  addEventListener: () => {},
};
let dbRefs = {};
function getDoc(id){ return dbRefs[id] ? { exists:true, data:()=>dbRefs[id].data } : { exists:false, data:()=>null }; }
const fieldValueStub = { arrayUnion(obj){ return { __op:'arrayUnion', obj }; } };

const sandbox = {
  console, Math, Date, JSON, URLSearchParams, encodeURIComponent, decodeURIComponent,
  setTimeout, clearTimeout, Set, Map,
  document: documentStub,
  location: { origin:'https://onepsiege353.github.io', pathname:'/hametkro/', search:'' },
  localStorage: { getItem:k=>storage[k]??null, setItem:(k,v)=>storage[k]=String(v) },
  navigator: { serviceWorker:{ register:()=>Promise.resolve() }, clipboard:{ writeText:()=>Promise.resolve() } },
  window: { addEventListener:()=>{}, HAM_FIREBASE_CONFIG:{} },
  firebase: {
    initializeApp:()=>{},
    auth:()=>sandbox.auth,
    firestore:()=>sandbox.db,
    auth:{ Auth:{ Persistence:{ LOCAL:1 } } },
    firestore:{ FieldValue:fieldValueStub },
  },
  openAuth:()=>{}, closeAll:()=>{}, toast:()=>{}, openSheet:()=>{}, openModal:()=>{},
};
sandbox.auth = { onAuthStateChanged:()=>{}, currentUser:null, setPersistence:()=>({catch:()=>{}}) };
sandbox.db = { collection:()=>({
    doc:(id)=>({ get:async()=>getDoc(id), set:async(d)=>{dbRefs[id]={data:d}}, update:async(u)=>{ if(!dbRefs[id])dbRefs[id]={data:{}}; Object.assign(dbRefs[id].data,u); } }),
    where:()=>({ onSnapshot:()=>{} }), orderBy:()=>({onSnapshot:()=>{}}),
  }) };
sandbox.auth.Auth={Persistence:{LOCAL:1}}; sandbox.db.FieldValue=fieldValueStub;
const _fa=function(){ return sandbox.auth; }; _fa.Auth=sandbox.auth.Auth;
const _ff=function(){ return sandbox.db; }; _ff.FieldValue=fieldValueStub;
sandbox.firebase={ initializeApp:()=>{}, auth:_fa, firestore:_ff };

vm.createContext(sandbox);
vm.runInContext(src, sandbox, { filename:'index.html' });
// Accès aux fonctions (déclarations → propriétés du contexte) et aux
// variables `let` (liaison lexicale) via runInContext.
function run(expr){ return vm.runInContext(expr, sandbox); }
function setProf(o){ run('curProfile='+JSON.stringify(o)); }
function get(k){ return run(k); }

let pass=0, fail=0;
function t(name, fn){ try{ fn(); console.log('  PASS ' + name); pass++; } catch(e){ console.log('  FAIL ' + name + ' :: ' + e.message); fail++; } }

console.log('== Tests pousses du chat Hametkro ==\n');

// 1) identifiant conversation déterministe
t('convIdKey symetrique (acheteur/vendeur -> meme id)', ()=>{
  assert.strictEqual(run('convIdKey("uidA","uidB","itemXyz")'), run('convIdKey("uidB","uidA","itemXyz")'));
});
t('convIdKey differencie les articles', ()=>{
  assert.notStrictEqual(run('convIdKey("a","b","i1")'), run('convIdKey("a","b","i2")'));
});
t('convIdKey differencie les paires', ()=>{
  assert.notStrictEqual(run('convIdKey("a","b","i")'), run('convIdKey("a","c","i")'));
});

// 2) unreadOf / mySeen / otherName
setProf({uid:'buyerX',name:'Acheteur'});
run('convX={participantIds:["buyerX","sellerY"],participants:[{uid:"buyerX",name:"Acheteur"},{uid:"sellerY",name:"Vendeur"}],seen:{buyerX:1000},msgs:[]}');
t('unreadOf = 0 si aucun message apres seen', ()=>{
  assert.strictEqual(run('unreadOf({...convX,msgs:[{uid:"sellerY",time:900}]})'), 0);
});
t('unreadOf compte seulement les messages de l AUTRE apres seen', ()=>{
  assert.strictEqual(run('unreadOf({...convX,msgs:[{uid:"sellerY",time:900},{uid:"sellerY",time:1100},{uid:"buyerX",time:1200}]})'), 1);
});
t('unreadOf ignore ses propres messages', ()=>{
  assert.strictEqual(run('unreadOf({...convX,msgs:[{uid:"buyerX",time:5000},{uid:"sellerY",time:1100}]})'), 1);
});
t('mySeen renvoie le timestamp du profil courant', ()=>{
  assert.strictEqual(run('mySeen(convX)'), 1000);
});
t('otherName = le participant different du profil courant', ()=>{
  assert.strictEqual(run('otherName(convX).uid'), 'sellerY');
});
t('esc neutralise HTML dans un nom', ()=>{
  assert.strictEqual(run('esc("<img onerror=1>")'), '&lt;img onerror=1&gt;');
});

// 3) bulles XSS + classes
t('convBubbles echappe le HTML du message (anti-XSS)', ()=>{
  const out=run('convBubbles({msgs:[{uid:"sellerY",name:"X",time:Date.now(),text:"<script>alert(1)</script>"}]})');
  assert.ok(!out.includes('<script>'), 'script present non echappe');
  assert.ok(out.includes('&lt;script&gt;')||out.includes('&#60;script&#62;'), "pas d'echappement");
});
t('convBubbles classe mes bulles en me / autres en them', ()=>{
  const out=run('convBubbles({msgs:[{uid:"buyerX",time:Date.now(),text:"hi"},{uid:"sellerY",time:Date.now(),text:"yo"}]})');
  assert.ok(out.includes('bubble me'), 'bulle me absente');
  assert.ok(out.includes('bubble them'), 'bulle them absente');
});
t('convBubbles affiche un placeholder quand il ny a pas de message', ()=>{
  const out=run('convBubbles({msgs:[]})');
  assert.ok(out.length>0);
});

// 4) messagesV
t('messagesV montre le dernier message sans prefixe Vous sil vient de lautre', ()=>{
  setProf({uid:'buyerX',name:'A'});
  run('convCache=[{id:"c1",participantIds:["buyerX","sellerY"],participants:[{uid:"buyerX",name:"A"},{uid:"sellerY",name:"B"}],itemTitle:"Robe",lastAt:Date.now(),msgs:[{uid:"buyerX",text:"dispo ?"},{uid:"sellerY",text:"oui"}],seen:{buyerX:Date.now(),sellerY:0}}]');
  run('msgUnread=1');
  const h=get('messagesV()');
  assert.ok(h.includes('oui'), 'apercu dernier message absent');
  assert.ok(!h.includes('Vous :'), 'prefixe Vous present a tort');
});
t('messagesV prefixe Vous quand le dernier message est le mien', ()=>{
  setProf({uid:'buyerX',name:'A'});
  run('convCache=[{id:"c1",participantIds:["buyerX","sellerY"],participants:[{uid:"buyerX",name:"A"},{uid:"sellerY",name:"B"}],itemTitle:"Robe",lastAt:Date.now(),msgs:[{uid:"sellerY",text:"oui"},{uid:"buyerX",text:"merci"}],seen:{buyerX:Date.now(),sellerY:0}}]');
  run('msgUnread=0');
  assert.ok(get('messagesV()').includes('Vous : merci'));
});

// 5) envoi atomique
t('sendMsg utilise un ajout atomique arrayUnion (anti-course)', ()=>{
  assert.ok(src.includes('fv.arrayUnion(msg)'), 'sendMsg ne fait pas d ajout atomique');
});

// 6) isolation chat plein ecran
t('chatIsOpen false au depart', ()=>{ assert.strictEqual(run('chatIsOpen()'), false); });
t('shell() ne re-affiche pas pendant qu un fil est ouvert', ()=>{
  // prime le #app avec un rendu normal (view home, chat ferme)
  run('view="home";_activeCid=null;_convData=null;shell()');
  const el=els['app']; const before=el.innerHTML;
  run('_activeCid="c1";_convData={participants:[],msgs:[]}');
  run('shell()');   // snapshot d'arriere-plan ne doit RIEN changer
  assert.strictEqual(el.innerHTML, before, 'shell a re-affiche pendant que le chat est ouvert');
  run('_activeCid=null;_convData=null;view="home"');
});

// 7) partage lien / whatsapp
t('listingURL construit un lien ?a=id', ()=>{
  assert.ok(get('listingURL("abc")').includes('?a=abc'));
});
t('waUrl inclut prix et lien, correctement encode', ()=>{
  run('allListings=[{id:"abc",t:"Robe",p:5000,cond:"Neuf",city:"Abidjan"}]');
  const out=get('waUrl("abc")');
  assert.ok(out.startsWith('https://wa.me/?text='), 'mauvais prefixe');
  const txt=decodeURIComponent(out);
  assert.ok(txt.includes('FCFA') && txt.includes('000'), 'prix absent du message');
  assert.ok(txt.includes('?a=abc'), 'lien annonce absent du message');
});

// 8) pas de collision
t('convIdKey sans collision entre paires proches', ()=>{
  assert.notStrictEqual(run('convIdKey("x","y","ab")'), run('convIdKey("x","y","ba")'));
  assert.notStrictEqual(run('convIdKey("ab","c","i")'), run('convIdKey("a","bc","i")'));
});

console.log('\n== Resultat : ' + pass + ' ok, ' + fail + ' echec(s) ==');
process.exit(fail?1:0);
