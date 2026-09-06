// Test d'intégration du chat : simule un échange ACHETEUR <-> VENDEUR complet
// à travers les VRAIES fonctions (openChatFromListing / openConv / sendMsg /
// listenConvs) reliées à un mock Firestore qui reproduit arrayUnion.
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const html = fs.readFileSync(__dirname + '/../webapp/index.html', 'utf8');
const blocks = html.match(/<script>([\s\S]*?)<\/script>/g) || [];
const src = blocks.find(b=>b.includes('DÉMARRAGE')).replace(/^<script>/,'').replace(/<\/script>$/,'');

// ---- Firestore mock fidèle : stockage réel + arrayUnion server-side ----
let store = {};           // id -> doc data
let changeLogs = [];
function applyUpdate(doc, patch){
  // simule FieldValue.arrayUnion : AJOUTE l'objet à la fin (ne remplace pas)
  for (const k of Object.keys(patch)){
    const v = patch[k];
    if (v && v.__op==='arrayUnion'){
      if (!Array.isArray(doc[k])) doc[k]=[];
      const j=JSON.stringify(v.obj);
      if (!doc[k].some(o=>JSON.stringify(o)===j)) doc[k]=doc[k].concat(v.obj);
    } else doc[k]=v;
  }
}
function makeRef(cid){ return {
  get:async()=>store[cid]?{exists:true,data:()=>store[cid]}:{exists:false,data:()=>null},
  set:async(d)=>{ store[cid]=JSON.parse(JSON.stringify(d)); },
  update:async(p)=>{ if(!store[cid])store[cid]={}; applyUpdate(store[cid],p); changeLogs.push(cid); },
  onSnapshot:(cb)=>{ /* pas de temps réel dans ce mock ; on force manuellement */ },
}; }

function buildSandbox(){
  const fieldValue={ arrayUnion:o=>({__op:'arrayUnion',obj:o}) };
  const s={
    console, Math, Date, JSON, URLSearchParams, encodeURIComponent, decodeURIComponent,
    setTimeout, clearTimeout, Set, Map,
    location:{origin:'https://x.github.io',pathname:'/h/',search:''},
    localStorage:{getItem:()=>null,setItem:()=>{}},
    navigator:{serviceWorker:{register:()=>Promise.resolve()}},
    window:{addEventListener:()=>{}},
    document:{ getElementById:()=>({innerHTML:'',value:'',style:{},scrollTop:0,scrollHeight:0,clientHeight:0}), querySelector:()=>null, documentElement:{scrollTop:0,scrollHeight:0,clientHeight:0}, addEventListener:()=>{} },
    openAuth:()=>{}, closeAll:()=>{}, toast:()=>{}, openSheet:()=>{}, openModal:()=>{},
    renderApp:()=>{}, prompt:()=>{}, copyListingLink:()=>{},
  };
  s.allListings=[];
  s.auth = { onAuthStateChanged:()=>{}, currentUser:null, setPersistence:()=>({catch:()=>{}}) };
  s.db = { collection:(name)=>({
     doc:(cid)=>makeRef(cid),
     where:()=>({onSnapshot:cb=>{ /* subscribe; manual */ }}),
     orderBy:()=>({onSnapshot:()=>{}}),
     add:async()=>{}, get:async()=>({size:0}),
  }) };
  const authSvc = s.auth; authSvc.Auth={Persistence:{LOCAL:1}};
  const dbSvc = s.db; dbSvc.FieldValue=fieldValue;
  const fbAuth=function(){ return authSvc; }; fbAuth.Auth=authSvc.Auth;
  const fbFS=function(){ return dbSvc; }; fbFS.FieldValue=fieldValue;
  s.firebase={ initializeApp:()=>{}, auth:fbAuth, firestore:fbFS };
  vm.createContext(s);
  vm.runInContext(src,s);
  return { s, run:(e)=>vm.runInContext(e,s) };
}

let pass=0, fail=0;
function t(n,f){ try{f();console.log('  PASS '+n);pass++;}catch(e){console.log('  FAIL '+n+' :: '+e.message);fail++;} }

(async()=>{
  console.log('== Test d integration : echange acheteur/vendeur ==\n');
  store={};

  // Scénario
  const buyer={uid:'B1',name:'Awa'}, seller={uid:'S1',name:'Kofi'};
  const item={id:'it1',sellerId:'S1',sellerName:'Kofi',t:'Robe wax',p:10000};

  const {run, s} = buildSandbox();

  // ACHETEUR ouvre le chat depuis l'annonce
  run('curProfile='+JSON.stringify(buyer)+'; allListings='+JSON.stringify([item]));
  await run('openChatFromListing("it1")');

  // Conversation créée en base
  const cid=run('convIdKey("B1","S1","it1")');
  t('conversation creee avec id deterministe partage', ()=> assert.ok(store[cid]));
  t('participantIds tries et complets', ()=>{
    assert.deepStrictEqual(store[cid].participantIds, ['B1','S1']);
    assert.ok(store[cid].participants.length===2);
  });

  // ACHETEUR envoie un message via sendMsg
  // sendMsg lit #msgText ; on pose sa valeur puis on appelle
  const el = { value:'Bonjour, toujours dispo ?' };
  s.document.getElementById = (id)=> id==='msgText'?el:{innerHTML:'',value:'',style:{}};
  await run('sendMsg()');
  t('message acheteur stocke', ()=> assert.strictEqual(store[cid].msgs.length,1));
  t('lastAt et lastMsg mis a jour', ()=> assert.strictEqual(store[cid].lastMsg,'Bonjour, toujours dispo ?'));

  // VENDEUR (autre "appareil") : se connecte et voit la conversation
  store[cid].seen = store[cid].seen||{};         // vendeur n'a rien lu
  // Vendeur répond
  s.document.getElementById=(id)=> id==='msgText'?{value:'Oui ! 15h au marché de Treichville.'}:{innerHTML:'',value:'',style:{}};
  await run('curProfile='+JSON.stringify(seller));
  const cData = JSON.stringify(store[cid]);
  await run('_activeCid="'+cid+'"; _convData='+cData+'; _convRef=db.collection("conversations").doc("'+cid+'")');
  await run('sendMsg()');
  t('second message ajoute sans ecraser le premier', ()=>{
    assert.strictEqual(store[cid].msgs.length,2);
    assert.strictEqual(store[cid].msgs[0].text,'Bonjour, toujours dispo ?');
    assert.strictEqual(store[cid].msgs[1].text,'Oui ! 15h au marché de Treichville.');
  });
  t('expediteur du 2e message = vendeur', ()=> assert.strictEqual(store[cid].msgs[1].uid,'S1'));

  // Simulation de course : deux envois quasi simultanés (arrayUnion ajoute les 2)
  s.document.getElementById=(id)=> id==='msgText'?{value:'S1-deuxieme'}:{innerHTML:'',value:'',style:{}};
  await run('curProfile='+JSON.stringify(seller));
  await run('sendMsg()');
  s.document.getElementById=(id)=> id==='msgText'?{value:'S1-troisieme'}:{innerHTML:'',value:'',style:{}};
  await run('sendMsg()');
  t('les envois successifs du vendeur sont tous conserves (pas de course)', ()=>{
    assert.ok(store[cid].msgs.length>=4, 'messages perdus en course');
  });

  // non-lus vendeur : l acheteur a ecrit 1 message, vendeur a repondu 3x -> si vendeur n a pas marqué seen avant ses envois...
  t('message texte stocke tel quel sans HTML', ()=>
    assert.ok(store[cid].msgs.every(m=>!m.text.includes('<'))));

  // Deep link waUrl pour cette annonce
  t('lien de partage reference la bonne annonce', ()=>{
    const u=run('listingURL("it1")');
    assert.ok(u.includes('?a=it1'));
  });

  // La liste des conversations de l'acheteur (messagesV) fonctionne sans erreur
  run('curProfile='+JSON.stringify(buyer));
  run('convCache=['+JSON.stringify(store[cid])+']');
  run('msgUnread=0');
  const html=run('messagesV()');
  t('messagesV (acheteur) rend la conversation sans erreur', ()=> assert.ok(html.includes('Kofi')));

  console.log('\n== Resultat : '+pass+' ok, '+fail+' echec(s) ==');
  process.exit(fail?1:0);
})();
