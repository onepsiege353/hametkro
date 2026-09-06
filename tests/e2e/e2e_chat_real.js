// E2E chat RÉEL de bout en bout — 2 contextes isolés (vendeur ↔ acheteur),
// app en production, création de vrais comptes + publication + échange.
// Prérequis : règles Firestore publiées (firebase/firestore.rules), npm i playwright.
const { chromium } = require('playwright');
const H = require('./helpers.js');
const assert = require('assert');
let pass=0, fail=0;
function t(n,f){ try{ f(); console.log('  PASS '+n); pass++; } catch(e){ console.log('  FAIL '+n+' :: '+e.message); fail++; } }
const URL = 'https://onepsiege353.github.io/hametkro/';
async function newCtx(b){ const c=await b.newContext({viewport:{width:430,height:860}}); const p=await c.newPage();
  await p.goto(URL,{waitUntil:'domcontentloaded',timeout:45000}); await p.waitForTimeout(6000); return {c,p}; }

(async()=>{
  const b = await chromium.launch({headless:true,args:['--no-sandbox']});
  const itemTitle = 'ChatReal '+Date.now();
  const V = await newCtx(b);
  await H.register(V.p,{name:'V Real '+String(Date.now()).slice(-5), email:H.uniq('rv'), pass:'TestPass1!'});
  await H.publishListing(V.p, itemTitle, 8800, 'échange réel');
  const pub = await V.p.evaluate(async(tt)=>{const s=await firebase.firestore().collection('listings').get();return s.docs.map(d=>d.data()).some(x=>x.t===tt);},itemTitle);
  t('annonce réellement publiée (Firestore)', ()=>assert.ok(pub));

  const A = await newCtx(b);
  const errsA=[]; A.p.on('console',m=>{if(m.type()==='error')errsA.push(m.text());});
  await H.register(A.p,{name:'A Real '+String(Date.now()).slice(-5), email:H.uniq('ra'), pass:'TestPass1!'});
  const tile=A.p.locator(`.tile:has-text("${itemTitle}")`).first();
  let found=false; try{ await tile.waitFor({timeout:25000}); found=true; }catch(e){}
  t('acheteur trouve et ouvre l annonce', ()=>assert.ok(found));
  await tile.click(); await A.p.waitForTimeout(1000);
  await A.p.locator('button:has-text("Discuter")').first().click(); await A.p.waitForTimeout(2500);
  const msgField=await A.p.locator('#msgText').count();
  t('chat ouvert chez l acheteur', ()=>assert.ok(msgField>0));
  await A.p.fill('#msgText','Bonjour, toujours dispo ?'); await A.p.press('#msgText','Enter'); await A.p.waitForTimeout(2000);
  const aSent=await A.p.evaluate(()=>document.body.innerText.includes('Bonjour, toujours dispo ?'));
  t('message acheteur envoyé et affiché', ()=>assert.ok(aSent));

  await V.p.waitForTimeout(1500);
  await V.p.click('.nav button:has-text("Messages")'); await V.p.waitForTimeout(2500);
  let vField=0;
  for(let i=0;i<5 && !vField;i++){
    try{ const it=V.p.locator(`.chatItem:has-text("${itemTitle}")`).first(); await it.waitFor({timeout:6000}); await it.click(); }catch(e){}
    await V.p.waitForTimeout(1500); vField=await V.p.locator('#msgText').count();
  }
  t('vendeur a le chat ouvert', ()=>assert.ok(vField>0));
  const vGot=await V.p.evaluate(()=>document.body.innerText.includes('Bonjour, toujours dispo ?'));
  t('vendeur reçoit le message de l acheteur', ()=>assert.ok(vGot));
  await V.p.fill('#msgText','Oui, à Cocody ce soir'); await V.p.press('#msgText','Enter'); await V.p.waitForTimeout(2000);
  const vSent=await V.p.evaluate(()=>document.body.innerText.includes('Oui, à Cocody ce soir'));
  t('vendeur répond', ()=>assert.ok(vSent));

  await A.p.waitForTimeout(3000);
  const aGot=await A.p.evaluate(()=>document.body.innerText.includes('Oui, à Cocody ce soir'));
  const still=await A.p.evaluate(()=>!!document.getElementById('msgText'));
  t('acheteur reçoit la réponse, fil toujours ouvert', ()=>assert.ok(aGot&&still));

  const msgs=await A.p.evaluate(async()=>{ const uid=await new Promise(r=>firebase.auth().onAuthStateChanged(u=>r(u?u.uid:null)));
    const cs=await firebase.firestore().collection('conversations').where('participantIds','array-contains',uid).get();
    let out=[]; cs.docs.forEach(d=>{const dd=d.data(); if((dd.msgs||[]).length) out.push(...dd.msgs.map(m=>m.text));}); return out; });
  const realMsgs=msgs.filter(m=>/Bonjour|Cocody/.test(m||''));
  t('messages persistés en Firestore', ()=>assert.ok(realMsgs.length>=2));
  console.log('  [errors acheteur]:', errsA.length?errsA.slice(0,8):'aucune');
  await V.c.close(); await A.c.close(); await b.close();
  console.log('\n== Chat réel : '+pass+' ok, '+fail+' échec(s) ==');
  process.exit(fail?1:0);
})().catch(e=>{console.error('ERR',e);process.exit(1);});
