import {JSDOM} from 'jsdom';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const dom=new JSDOM(fs.readFileSync(root+'frontend/index.html','utf8'),{url:'http://localhost',runScripts:'outside-only'});
const w=dom.window;
w.scrollTo=()=>{};
w.HTMLDialogElement.prototype.showModal=function(){this.open=true;};
w.HTMLDialogElement.prototype.close=function(){this.open=false;};
let parents=[{parent_id:'P00001',name:'Parent'}], children=[{child_id:'C00001',parent_id:'P00001',name:'Child',date_of_birth:'2020-01-01'}];
let schedules=[{schedule_id:'S00001',child_id:'C00001',vaccine_id:'V00001',vaccine_name:'Test',dose_number:1,status:'completed',scheduled_date:'2020-01-01'}];
let records=[{record_id:'D00001',child_id:'C00001',vaccine_id:'V00001',vaccine_name:'Test',dose_number:1,vaccination_date:'2020-01-01T12:00:00'}];
let reminders=[{reminder_id:'R00001',schedule_id:'S00001',reminder_status:'completed'}];
let deletes=0, fail=false;
w.fetch=async(path,opts={})=>{
 if(opts.method==='DELETE'){
  deletes++;
  if(fail)return {ok:false,json:async()=>({detail:'Test failure'})};
  if(path.startsWith('/records/')){records=[];schedules[0].status='pending';reminders[0].reminder_status='pending';}
  if(path.startsWith('/children/')){children=[];records=[];schedules=[];reminders=[];}
  if(path.startsWith('/parents/')){parents=[];children=[];records=[];schedules=[];reminders=[];}
  return {ok:true,json:async()=>({deleted:true})};
 }
 const routes={'/health':{},'/parents':parents,'/children':children,'/vaccines':[], '/schedules/recommended':[], '/schedules':schedules,'/records':records,'/reminders':reminders};
 return {ok:true,json:async()=>structuredClone(routes[path.split('?')[0]])};
};
w.eval(fs.readFileSync(root+'frontend/app.js','utf8')+'\nwindow.setTab=setTab; window.historyDetail=historyDetail; window.testState=state;');
const flush=()=>new Promise(r=>setTimeout(r,20));
await flush();
w.eval("setTab('family')");
assert.ok(w.document.querySelector('[data-delete-kind="children"]'));
w.document.querySelector('[data-delete-kind="children"]').click();
w.document.querySelector('[data-action="close"]').click();
assert.equal(deletes,0);
w.eval("historyDetail('D00001')");
w.document.querySelector('[data-delete-kind="records"]').click();
fail=true;w.document.querySelector('[data-confirm-delete]').click();await flush();
assert.ok(w.document.querySelector('.form-error').textContent.includes('Test failure'));
assert.equal(records.length,1);
fail=false;w.document.querySelector('[data-confirm-delete]').click();await flush();
assert.equal(records.length,0);assert.equal(w.testState.schedules[0].status,'pending');
w.eval("setTab('family')");w.document.querySelector('[data-delete-kind="children"]').click();
w.document.querySelector('[data-confirm-delete]').click();await flush();
assert.equal(w.localStorage.getItem('littleSteps.child'),'');
assert.ok(w.document.querySelector('[data-delete-kind="parents"]'));
w.document.querySelector('[data-delete-kind="parents"]').click();w.document.querySelector('[data-confirm-delete]').click();await flush();
assert.equal(w.localStorage.getItem('littleSteps.parent'),'');
assert.ok(w.document.querySelector('[data-action="add-parent"]'));
console.log('PASS UI: cancel, failure, record/child/parent deletion, refresh, empty family and localStorage');
w.close();
