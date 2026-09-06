// Aides E2E pour Hametkro (Playwright, app en production).
// Crée des comptes temporaires réels sur le projet Firebase + un fichier photo.
const { chromium } = require('playwright');
const fs = require('fs');
const R = 'e2e' + Date.now();
function uniq(prefix){ return (prefix + '.' + R + '@test.fr'); }
const IMG = '/tmp/hametkro_e2e.png';
if (!fs.existsSync(IMG)) fs.writeFileSync(IMG, Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==','base64'));

async function launch(){ return chromium.launch({headless:true, args:['--no-sandbox']}); }
function newPage(b){ return b.newPage({viewport:{width:430,height:860}}); }
async function open(p){ await p.goto('https://onepsiege353.github.io/hametkro/',{waitUntil:'domcontentloaded',timeout:45000}); await p.waitForTimeout(6000); }
async function register(p,{name,email,pass}){
  await p.click('button:has-text("Se connecter")'); await p.waitForTimeout(500);
  await p.click('button:has-text("Créer un compte")').catch(()=>{}); await p.waitForTimeout(400);
  await p.fill('#rn', name); await p.fill('#re', email); await p.fill('#rc','Abidjan'); await p.fill('#rp', pass);
  await p.click('button:has-text("Créer mon compte")'); await p.waitForTimeout(7000);
}
async function publishListing(p, title, price, desc){
  await p.click('.nav button:has-text("Vendre")'); await p.waitForTimeout(900);
  await p.click('button:has-text("➕ Publier")'); await p.waitForTimeout(900);
  await p.fill('input[placeholder*="Robe wax"]', title);
  await p.fill('input[type=number]', String(price));
  await p.fill('textarea', desc||'');
  const fi = await p.$('input[type=file]'); await fi.setInputFiles(IMG); await p.waitForTimeout(1200);
  await p.click('button:has-text("Publier 🎉")'); await p.waitForTimeout(2500);
}
module.exports={ launch,newPage,open,register,publishListing,uniq,R };
