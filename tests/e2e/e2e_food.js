// E2E local du module Repas du jour : nécessite de servir webapp/ (avec firebase-config.js)
// ex. : cp index.html et firebase-config.js, puis `python3 -m http.server 8123`,
// puis `node e2e_food.js`. Crée de vrais comptes/commandes sur le projet (à nettoyer).
const { chromium } = require('/home/user/e2e/node_modules/playwright');
const assert = require('assert');
let pass=0,fail=0; function t(n,f){try{f();console.log('  PASS '+n);pass++;}catch(e){console.log('  FAIL '+n+' :: '+e.message);fail++;}}
const URL='http://127.0.0.1:8123/index.html';
const R='food'+Date.now();
async function bodyText(p){ return p.evaluate(()=>document.body.innerText); }
async function ctx(b){ const c=await b.newContext({viewport:{width:430,height:860}}); const p=await c.newPage();
  await p.goto(URL,{waitUntil:'domcontentloaded',timeout:45000}); await p.waitForTimeout(6500); return {c,p}; }
async function reg(p,name,email){ await p.click('button:has-text("Se connecter")'); await p.waitForTimeout(400);
  await p.click('button:has-text("Créer un compte")').catch(()=>{}); await p.waitForTimeout(300);
  await p.fill('#rn',name); await p.fill('#re',email); await p.fill('#rc','Abidjan'); await p.fill('#rp','TestPass1!');
  await p.click('button:has-text("Créer mon compte")'); await p.waitForTimeout(7000); }
async function goResto(p){ await p.click('.nav button:has-text("Repas")'); await p.waitForTimeout(1200); }
(async()=>{
  const b=await chromium.launch({headless:true,args:['--no-sandbox']});
  const V=await ctx(b);
  await reg(V.p,'Cant '+R.slice(-4),'ve.'+R+'@test.fr');
  await goResto(V.p);
  const cta=await V.p.locator('button:has-text("Ouvrir ma cantinière")').count();
  t('vendeur voit le CTA Ouvrir ma cantinière', ()=>assert.ok(cta>0));
  await V.p.locator('button:has-text("Ouvrir ma cantinière")').click(); await V.p.waitForTimeout(900);
  await V.p.fill('#ff_name','Cantine Plateau'); await V.p.fill('#ff_zone','Plateau / Cocody');
  await V.p.selectOption('#ff_cut','10:30'); await V.p.selectOption('#ff_ws','12:00'); await V.p.selectOption('#ff_we','14:00');
  await V.p.fill('#ff_items','Riz gras | 1500\nAttiéké poisson | 2000');
  await V.p.click('button:has-text("Publier / mettre à jour")'); await V.p.waitForTimeout(2800);
  let t1=await bodyText(V.p);
  t('menu du jour publié (panneau Ma cantinière)', ()=>assert.ok(t1.includes('Ma cantinière') && t1.includes('Cantine Plateau'), t1.slice(-150)));

  const A=await ctx(b);
  await reg(A.p,'Client '+R.slice(-4),'cl.'+R+'@test.fr');
  await goResto(A.p); await A.p.waitForTimeout(800);
  let t2=await bodyText(A.p);
  t('acheteur voit le menu dans Menus du jour', ()=>assert.ok(t2.includes('Cantine Plateau'), t2.slice(-150)));
  await A.p.evaluate(()=>{const e=[...document.querySelectorAll('button')].find(x=>x.textContent.includes('Commander')); if(e)e.click();});
  await A.p.waitForTimeout(900);
  await A.p.evaluate(()=>{const bs=[...document.querySelectorAll('button')].filter(x=>x.textContent==='+'); if(bs[0])bs[0].click(); if(bs[1])bs[1].click();});
  await A.p.fill('#ff_place','Hall Immeuble N°2'); await A.p.fill('#ff_note','sans piment');
  await A.p.evaluate(()=>{const e=[...document.querySelectorAll('button')].find(x=>x.textContent.includes('Confirmer la commande')); if(e)e.click();});
  await A.p.waitForTimeout(2500);
  let t3=await bodyText(A.p);
  t('commande envoyée (Mes commandes / À confirmer)', ()=>assert.ok(t3.includes('À confirmer')||t3.includes('Mes commandes'), t3.slice(-200)));

  await goResto(V.p); await V.p.waitForTimeout(2500);
  let t4=await bodyText(V.p);
  t('vendeur reçoit la commande', ()=>assert.ok(t4.includes('À confirmer') && t4.includes('Client '), t4.slice(-250)));
  await V.p.evaluate(()=>{const e=[...document.querySelectorAll('button')].find(x=>x.textContent.includes('Confirmer')); if(e)e.click();});
  await V.p.waitForTimeout(2200);
  let t5=await bodyText(V.p);
  t('vendeur confirme la commande', ()=>assert.ok(t5.includes('Confirmée'), t5.slice(-150)));

  const persist=await V.p.evaluate(async()=>{ const uid=await new Promise(r=>firebase.auth().onAuthStateChanged(u=>r(u?u.uid:null)));
    const s=await firebase.firestore().collection('foodorders').where('sellerId','==',uid).get();
    return s.docs.map(d=>d.data()).filter(x=>x.status==='confirmed').length; });
  t('commande persistée & confirmée en Firestore', ()=>assert.ok(persist>=1));
  await V.c.close(); await A.c.close(); await b.close();
  console.log('\n== Resto E2E : '+pass+' ok, '+fail+' échec(s) ==');
  process.exit(fail?1:0);
})().catch(e=>{console.error('ERR',e);process.exit(1);});
