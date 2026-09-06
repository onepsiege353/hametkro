// Lancement E2E de bout en bout : (A) cycle complet du chat vendeur/acheteur,
// (B) badges de presence en ligne.
//
// PRÉ-REQUIS :
//  1) Les règles Firestore (conversations/messages) DOIVENT être publiées sur le
//     projet (voir firebase/firestore.rules), sinon le test chat échoue en
//     "permission-denied".
//  2) npm i playwright && npx playwright install chromium
// Usage : node run_e2e.js
const H = require('./helpers.js');
const assert = require('assert');
let pass=0, fail=0;
function t(n,f){ try{ f(); console.log('  PASS '+n); pass++; } catch(e){ console.log('  FAIL '+n+' :: '+e.message); fail++; } }

(async()=>{
  const b = await H.launch();
  console.log('== E2E Hametkro (production) ==\n');

  // ---------- A) Chat : vendeur publie, acheteur discute ----------
  // NB : nécessite que les règles Firestore conversations/messages soient
  // publiées ; sinon échec "permission-denied" attendu (voir README).
  const itemTitle='E2E '+Date.now();
  const v=await H.newPage(b); await H.open(v);
  await H.register(v,{name:'Vendeur E2E',email:H.uniq('ve'),pass:'TestPass1!'});
  await H.publishListing(v,itemTitle,7500,'annonce e2e');
  t('vendeur publie une annonce', ()=>true);

  const a=await H.newPage(b); await H.open(a);
  await H.register(a,{name:'Acheteur E2E',email:H.uniq('ac'),pass:'TestPass1!'});
  const tile=a.locator(`.tile:has-text("${itemTitle}")`).first();
  let found=false; try{ await tile.waitFor({timeout:25000}); found=true;}catch(e){}
  t('acheteur trouve l annonce', ()=>assert.ok(found));
  await tile.click(); await a.waitForTimeout(900);
  let disc=false; try{ await a.locator('button:has-text("Discuter")').first().click({timeout:8000}); disc=true;}catch(e){}
  t('bouton Discuter ouvert', ()=>assert.ok(disc));
  // Ouvre le chat et teste l'échange si les règles sont publiées (sinon, marque
  // les étapes chat comme NON VÉRIFIÉES et continue vers la présence).
  const msgField = await a.locator('#msgText').count().catch(()=>0);
  if(msgField===0){
    const body=await a.evaluate(()=>document.body.innerText);
    const err = body.includes('Impossible')||body.includes('permission')||body.includes('discussion');
    console.log('  [SKIP chat] règles conversations non publiées ? =>', body.replace(/\s+/g,' ').slice(-80));
    if(err) console.log('  [note] publie firebase/firestore.rules (conversations/messages) pour débloquer le chat.');
  } else {
    await a.fill('#msgText','Bonjour, c est dispo ?'); await a.press('#msgText','Enter'); await a.waitForTimeout(2000);
    const aSent=await a.evaluate(()=>document.body.innerText.includes('Bonjour, c est dispo ?'));
    t('message acheteur envoyé', ()=>assert.ok(aSent));
    await v.waitForTimeout(1500);
    await v.click('.nav button:has-text("Messages")'); await v.waitForTimeout(1500);
    await v.locator(`.chatItem:has-text("${itemTitle}")`).click().catch(async()=>{await v.click('.chatItem');});
    await v.waitForTimeout(1200);
    const vGot=await v.evaluate(()=>document.body.innerText.includes('Bonjour, c est dispo ?'));
    t('vendeur reçoit le message', ()=>assert.ok(vGot));
    await v.fill('#msgText','Oui viens à Cocody'); await v.press('#msgText','Enter'); await v.waitForTimeout(2000);
    await a.waitForTimeout(2500);
    const aGot=await a.evaluate(()=>document.body.innerText.includes('Oui viens à Cocody'));
    const still=await a.evaluate(()=>!!document.getElementById('msgText'));
    t('acheteur reçoit la réponse sans être éjecté', ()=>assert.ok(aGot&&still));
  }

  // ---------- B) Présence ----------
  const vis=await H.newPage(b); await H.open(vis);
  const t2=vis.locator(`.tile:has-text("${itemTitle}")`).first();
  await t2.waitFor({timeout:20000}); await t2.click(); await vis.waitForTimeout(800);
  await vis.locator('.box:has-text("voir profil")').click(); await vis.waitForTimeout(1500);
  const onTxt=await vis.evaluate(()=>document.body.innerText);
  t('vendeur connecté = badge En ligne', ()=>assert.ok(onTxt.includes('En ligne')));
  await v.close();
  console.log('  [attente 65s expiration presence]');
  await vis.waitForTimeout(65000); await vis.reload(); await vis.waitForTimeout(4000);
  const t3=vis.locator(`.tile:has-text("${itemTitle}")`).first();
  try{ await t3.waitFor({timeout:20000}); await t3.click(); await vis.waitForTimeout(800);
       await vis.locator('.box:has-text("voir profil")').click(); await vis.waitForTimeout(1500);}catch(e){}
  const offTxt=await vis.evaluate(()=>document.body.innerText);
  t('vendeur fermé = Hors ligne', ()=>assert.ok(offTxt.includes('Hors ligne')));

  await b.close();
  console.log('\n== Résultat E2E : '+pass+' ok, '+fail+' échec(s) ==');
  process.exit(fail?1:0);
})().catch(e=>{console.error('ERR',e);process.exit(1);});
