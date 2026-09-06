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


console.log('== Tests du module REPAS DU JOUR (cantinieres) ==\n');
// --- parseItems : lignes "Nom | prix" ---
t('parseItems ignore ligne invalide', ()=>{
  const got=run('parseItems(["Riz gras | 1500","Attieke poisson |2000","brouille","|3000","Sauce |  "].join(String.fromCharCode(10)))');
  assert.strictEqual(JSON.stringify(got), JSON.stringify([{name:'Riz gras',price:1500},{name:'Attieke poisson',price:2000}]));
});
t('parseItems vide si aucune ligne valide', ()=>{
  assert.strictEqual(run('parseItems(["bonjour","|","|1500"].join(String.fromCharCode(10))).length'), 0);
});
// --- hmMin / minHm : conversion heure/minute ---
t('hmMin convertit "10:30" en minutes', ()=>{ assert.strictEqual(run('hmMin("10:30")'), 630); });
t('minHm re-formate les minutes', ()=>{ assert.strictEqual(run('minHm(630)'), '10:30'); });
t('minHm gère minuit (0)', ()=>{ assert.strictEqual(run('minHm(0)'), '00:00'); });
t('hmMin ignore valeur invalide -> 0', ()=>{ assert.strictEqual(run('hmMin("abc")'), 0); });
// --- date ---
t('todayISO a le format AAAA-MM-JJ', ()=>{ assert.ok(/^\d{4}-\d{2}-\d{2}$/.test(run('todayISO()'))); });
// --- menuOpen : fenêtre de commande ---
t('menuOpen vrai si aujourd hui et avant le cutoff', ()=>{
  // force une date/heure: on teste via la logique en bricolant nowMin via heure actuelle;
  // ici on construit un menu dont cutoff > nowMin simulé par un objet date=aujourd'hui.
  const d=run('todayISO()'); const m={date:d, cutoff:1440}; // cutoff 23:59 -> toujours avant
  assert.strictEqual(run('menuOpen('+JSON.stringify(m)+')'), true);
});
t('menuOpen faux si date != aujourd hui', ()=>{
  const m={date:'2000-01-01', cutoff:1440};
  assert.strictEqual(run('menuOpen('+JSON.stringify(m)+')'), false);
});
t('menuOpen faux si cutoff dépassé (cutoff 00:00)', ()=>{
  const m={date:run('todayISO()'), cutoff:0};
  assert.strictEqual(run('menuOpen('+JSON.stringify(m)+')'), false);
});
// --- fmtFCFA ---
t('fmtFCFA met des espaces milliers', ()=>{ assert.strictEqual(run('fmtFCFA(1500)'), '1 500'); });
t('fmtFCFA arrondit', ()=>{ assert.strictEqual(run('fmtFCFA(1999.6)'), '2 000'); });

console.log('\n== Resultat : '+pass+' ok, '+fail+' echec(s) ==');
process.exit(fail?1:0);
