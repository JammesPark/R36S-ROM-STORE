import test from "node:test";
import assert from "node:assert/strict";
import app, {syncOneCatalog,syncCatalogs} from "./src/worker.mjs";

function makeEnv(writes="true") {
  const approved=new Set(),seen=new Set(),totals=new Map();
  const key=(cat,id)=>cat+"/"+id;
  const DB={
    approve(cat,id) { approved.add(key(cat,id)); },
    prepare(sql) {
      let args=[];
      return {
        bind(...a){args=a;return this;},
        async first(){
          if (sql.includes("FROM approved_ports"))
            return approved.has(key(args[0],args[1]))?{allowed:1}:null;
          if (sql.includes("COUNT(*)"))return{total:totals.size};
          if (sql.includes("FROM download_totals"))
            return{downloads:totals.get(key(args[0],args[1]))||0};
          throw new Error("not implemented: "+sql);
        },
        async all(){
          assert.match(sql,/WHERE catalog =/);
          return {results:[...totals].map(([k,downloads])=>{
            const index=k.indexOf("/");
            return {catalog:k.slice(0,index),port_id:k.slice(index+1),downloads};
          }).filter(x=>x.catalog===args[0]).sort((a,b)=>b.downloads-a.downloads||a.port_id.localeCompare(b.port_id)).slice(0,5)};
        },
        async run(){
          if(sql.startsWith("UPDATE approved_ports SET active = 0")){
            for(const k of [...approved]) if(k.startsWith(args[0]+"/"))approved.delete(k);
          }else if(sql.startsWith("INSERT INTO approved_ports")) {
            approved.add(key(args[0],args[1]));
          }else if(sql.includes("INSERT OR IGNORE INTO download_events")){
            if(!seen.has(args[0])){
              seen.add(args[0]);const k=key(args[1],args[2]);
              totals.set(k,(totals.get(k)||0)+1);
            }
          }else throw new Error("not implemented: "+sql);
          return{};
        }
      };
    },
    async batch(statements){for(const item of statements)await item.run();}
  };
  return {
    DB,STATS_WRITES_ENABLED:writes,
    EVENT_RATE_LIMITER:{async limit(){return {success:true};}}
  };
}
const event=(n,cat="r36sbr",id="aestheta")=>({event_id:n.toString(16).padStart(32,"0"),catalog:cat,port_id:id});
const get=(path,env)=>app.fetch(new Request("https://worker.example"+path),env);
const post=(data,env,headers={})=>app.fetch(new Request("https://worker.example/v1/events",{
  method:"POST",headers:{"Content-Type":"application/json","CF-Connecting-IP":"203.0.113.12",...headers},
  body:JSON.stringify(data)
}),env);

test("SOMENTE LEITURA ate habilitar POST",async()=>{
  const env=makeEnv("false");env.DB.approve("r36sbr","aestheta");
  const r=await post({events:[event(1)]},env);
  assert.equal(r.status,503);
  assert.equal((await r.json()).error,"writes_disabled");
  assert.deepEqual(await(await get("/health",env)).json(),{ok:true,writes_enabled:false});
});
test("D1 deduplica o mesmo event_id; um novo download soma",async()=>{
  const env=makeEnv();env.DB.approve("r36sbr","aestheta");
  assert.equal((await post({events:[event(2)]},env)).status,200);
  assert.equal((await post({events:[event(2)]},env)).status,200);
  assert.equal((await post({events:[event(3)]},env)).status,200);
  const data=await (await get("/v1/count?catalog=r36sbr&port_id=aestheta",env)).json();
  assert.equal(data.downloads,2);
});
test("Nao aceita jogo nao autorizado, nem lote misto",async()=>{
  const env=makeEnv();env.DB.approve("r36sbr","aestheta");
  assert.equal((await post({events:[event(4,"r36sbr","falso")]},env)).status,422);
  assert.equal((await post({events:[event(5),event(6,"r36sbr","falso")]},env)).status,422);
  assert.equal((await(await get("/v1/count?catalog=r36sbr&port_id=aestheta",env)).json()).downloads,0);
});
test("Top 5 separados e sem catalog=all",async()=>{
  const env=makeEnv();env.DB.approve("r36sbr","aestheta");env.DB.approve("lira","jogo-lira");
  await post({events:[event(7),event(8,"lira","jogo-lira")]},env);
  assert.equal((await get("/v1/top",env)).status,400);
  assert.equal((await get("/v1/top?catalog=all",env)).status,400);
  const br=await (await get("/v1/top?catalog=r36sbr",env)).json();
  const lira=await (await get("/v1/top?catalog=lira",env)).json();
  assert.deepEqual(br.ranking.map(x=>x.port_id),["aestheta"]);
  assert.deepEqual(lira.ranking.map(x=>x.port_id),["jogo-lira"]);
});
test("Rate limit proporcional ao lote e impede excesso",async()=>{
  const env=makeEnv();env.DB.approve("r36sbr","aestheta");
  let last;
  env.EVENT_RATE_LIMITER={async limit(a){last=a;return{success:false};}};
  assert.equal((await post({events:[event(10),event(11)]},env)).status,429);
  assert.equal(last.delta,2);
});
test("Valida tipo, batch, payload e repeticao dentro do lote",async()=>{
  const env=makeEnv();env.DB.approve("r36sbr","aestheta");
  assert.equal((await post({events:[event(14),event(14)]},env)).status,400);
  assert.equal((await post({events:[{...event(15),event_id:"!bad"}]},env)).status,400);
  assert.equal((await post({events:Array.from({length:11},(_,n)=>event(n+100))},env)).status,400);
  assert.equal((await post({events:[event(16)]},env,{"Content-Type":"text/plain"})).status,415);
});
test("Sem limitador ou IP nao autoriza",async()=>{
  const env=makeEnv();env.DB.approve("r36sbr","aestheta");delete env.EVENT_RATE_LIMITER;
  assert.equal((await post({events:[event(17)]},env)).status,503);
  env.EVENT_RATE_LIMITER={async limit(){return{success:true};}};
  assert.equal((await post({events:[event(18)]},env,{"CF-Connecting-IP":""})).status,503);
});
test("Sincronizacao automatica: inclusao e exclusao por fonte",async()=>{
  const env=makeEnv("false");
  const url="https://raw.githubusercontent.com/JammesPark/R36SPORTSBR-STORE-UPDATES/main/catalog/catalog.json";
  const source=(ids)=>async()=>Response.json({ports:ids.map(id=>({id,section:"games"}))});
  assert.deepEqual(await syncOneCatalog(env,"r36sbr",url,source(["aestheta","alice-in-clicheland"])),{catalog:"r36sbr",authorized:2});
  await syncOneCatalog(env,"r36sbr",url,source(["aestheta"]));
  assert.equal(await env.DB.prepare("SELECT 1 AS allowed FROM approved_ports WHERE catalog = ? AND port_id = ? AND active = 1").bind("r36sbr","alice-in-clicheland").first(),null);
  assert.ok(await env.DB.prepare("SELECT 1 AS allowed FROM approved_ports WHERE catalog = ? AND port_id = ? AND active = 1").bind("r36sbr","aestheta").first());
});
test("Sincronizacao falha sem apagar autorizacoes antigas",async()=>{
  const env=makeEnv("false");const url="https://raw.githubusercontent.com/x/y/main/ports.json";
  const good=async()=>Response.json({ports:[{id:"aestheta",section:"games"}]});
  await syncOneCatalog(env,"r36sbr",url,good);
  await assert.rejects(syncOneCatalog(env,"r36sbr",url,async()=>Response.json({ports:[]})),/catalog_without_games/);
  assert.ok(await env.DB.prepare("SELECT 1 AS allowed FROM approved_ports WHERE catalog = ? AND port_id = ? AND active = 1").bind("r36sbr","aestheta").first());
});
test("URL sem origem GitHub raw e rejeitada",async()=>{
  const env=makeEnv();
  await assert.rejects(syncOneCatalog(env,"r36sbr","https://fake.example/catalog.json",async()=>Response.json({ports:[]})),/catalog_url_not_allowed/);
});
test("Dois catalogos sincronizados isoladamente",async()=>{
  const env=makeEnv("false");
  env.CATALOG_LIRA_URL="https://raw.githubusercontent.com/x/l/main/ports.json";
  env.CATALOG_R36SBR_URL="https://raw.githubusercontent.com/x/r/main/catalog.json";
  const result=await syncCatalogs(env,async url=>Response.json({
    ports:[{id:url.includes("/l/")?"lira-game":"r36sbr-game",section:"games"}]
  }));
  assert.deepEqual(result.map(x=>x.authorized),[1,1]);
  assert.ok(await env.DB.prepare("SELECT 1 AS allowed FROM approved_ports WHERE catalog = ? AND port_id = ? AND active = 1").bind("lira","lira-game").first());
  assert.ok(await env.DB.prepare("SELECT 1 AS allowed FROM approved_ports WHERE catalog = ? AND port_id = ? AND active = 1").bind("r36sbr","r36sbr-game").first());
});
