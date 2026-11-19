// R36SPORTSBR STORE: contador por catalogo (GPL-3.0).
// Nao ha prova criptografica de que o cliente concluiu o download.
// Controles: whitelist D1, deduplicacao atomica, limite por EVENTO e POST desligado.
// Rotas de ranking nunca agregam lira com r36sbr.
const SOURCES = new Set(["lira", "r36sbr"]);
const PORT_ID = /^[a-z0-9][a-z0-9_.-]{0,119}$/i;
const EVENT_ID = /^[a-f0-9]{32}$/i;
const MAX_BODY = 8192, MAX_BATCH = 10, MAX_CATALOG_BYTES = 1024*1024;
const CONFIG = [
  ["lira", "CATALOG_LIRA_URL"],
  ["r36sbr", "CATALOG_R36SBR_URL"]
];
function reply(data,status=200,cache="no-store") {
  return Response.json(data,{status,headers:{"Cache-Control":cache,"X-Content-Type-Options":"nosniff"}});
}
async function limitedJson(request,maxBytes) {
  if (!request.body) throw new Error("invalid_json");
  const reader = request.body.getReader();
  const parts = []; let total = 0;
  try {
    while (true) {
      const {done,value} = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > maxBytes) {
        await reader.cancel();
        throw new Error("payload_too_large");
      }
      parts.push(value);
    }
  } finally {
    try { reader.releaseLock(); } catch {}
  }
  const buf = new Uint8Array(total);
  let pos = 0;
  for (const x of parts) { buf.set(x,pos); pos += x.byteLength; }
  try { return JSON.parse(new TextDecoder().decode(buf)); }
  catch { throw new Error("invalid_json"); }
}
function validatedIDs(data) {
  if (!data || !Array.isArray(data.ports) || data.ports.length > 1000)
    throw new Error("catalog_invalid_format");
  const ids = new Set();
  for (const p of data.ports) {
    if (p?.section !== "games") continue;
    if (typeof p.id !== "string" || !PORT_ID.test(p.id))
      throw new Error("catalog_invalid_port_id");
    ids.add(p.id);
    if (ids.size > 500) throw new Error("catalog_too_many_games");
  }
  if (!ids.size) throw new Error("catalog_without_games");
  return [...ids].sort();
}
export async function syncOneCatalog(env,catalog,sourceURL,sourceFetch=fetch) {
  if (!SOURCES.has(catalog) || !env.DB) throw new Error("invalid_catalog_or_db");
  let url;
  try { url = new URL(sourceURL); }
  catch { throw new Error("catalog_url_invalid"); }
  if (url.protocol !== "https:" || url.hostname !== "raw.githubusercontent.com"
    || !url.pathname.endsWith(".json") || url.search || url.hash
    || url.username || url.password) throw new Error("catalog_url_not_allowed");
  const res = await sourceFetch(url.toString(),{
    signal: AbortSignal.timeout(12000),
    headers: {"Accept":"application/json"}
  });
  if (!res.ok) throw new Error("catalog_http_"+res.status);
  const declared = Number(res.headers.get("content-length") || 0);
  if (declared > MAX_CATALOG_BYTES) throw new Error("catalog_too_large");
  const data = await limitedJson(res,MAX_CATALOG_BYTES);
  const ids = validatedIDs(data);
  // Uma unica transacao por fonte; falha preserva lista anterior.
  const changes=[
    env.DB.prepare("UPDATE approved_ports SET active = 0 WHERE catalog = ?").bind(catalog),
    ...ids.map(id=>env.DB.prepare(
      "INSERT INTO approved_ports (catalog,port_id,active) VALUES (?,?,1) "+
      "ON CONFLICT(catalog,port_id) DO UPDATE SET active = 1").bind(catalog,id))
  ];
  await env.DB.batch(changes);
  return {catalog,authorized:ids.length};
}
export async function syncCatalogs(env,sourceFetch=fetch) {
  const completed=[],errors=[];
  for (const [cat,setting] of CONFIG) {
    if (!env[setting]) continue;
    try {
      const r=await syncOneCatalog(env,cat,env[setting],sourceFetch);
      completed.push(r);
      console.info("Catalogo sincronizado:",r.catalog,r.authorized);
    } catch(e) {
      console.error("Falha sincronia; registro anterior preservado:",cat,String(e));
      errors.push(cat);
    }
  }
  if (errors.length) throw new Error("catalog_sync_failed:"+errors.join(","));
  return completed;
}
export default {
  async scheduled(_event,env) { await syncCatalogs(env); },
  async fetch(request,env) {
    const url=new URL(request.url);
    if (!env.DB) return reply({error:"database_not_configured"},503);
    try {
      if (request.method==="GET" && url.pathname==="/health") {
        await env.DB.prepare("SELECT COUNT(*) AS total FROM download_totals").first();
        return reply({ok:true,writes_enabled:env.STATS_WRITES_ENABLED==="true"});
      }
      if (request.method==="GET" && url.pathname==="/v1/top") {
        const catalog=url.searchParams.get("catalog");
        if (!SOURCES.has(catalog)) return reply({error:"invalid_catalog"},400);
        const rows=await env.DB.prepare(
          "SELECT catalog,port_id,downloads FROM download_totals "+
          "WHERE catalog = ? ORDER BY downloads DESC,port_id LIMIT 5"
        ).bind(catalog).all();
        return reply({catalog,ranking:rows.results||[]},200,"public, max-age=30");
      }
      if (request.method==="GET" && url.pathname==="/v1/count") {
        const catalog=url.searchParams.get("catalog"),id=url.searchParams.get("port_id");
        if (!SOURCES.has(catalog) || !id || !PORT_ID.test(id))
          return reply({error:"invalid_port"},400);
        const row=await env.DB.prepare(
          "SELECT downloads FROM download_totals WHERE catalog = ? AND port_id = ?"
        ).bind(catalog,id).first();
        return reply({catalog,port_id:id,downloads:Number(row?.downloads||0)},200,"public, max-age=30");
      }
      if (request.method==="POST" && url.pathname==="/v1/events") {
        if (env.STATS_WRITES_ENABLED!=="true")
          return reply({error:"writes_disabled"},503);
        if (!env.EVENT_RATE_LIMITER || typeof env.EVENT_RATE_LIMITER.limit!=="function")
          return reply({error:"rate_limiter_unavailable"},503);
        const ip=request.headers.get("CF-Connecting-IP");
        if (!ip) return reply({error:"client_unavailable"},503);
        const ct=request.headers.get("content-type")||"";
        if (!/^application\/json\s*(;|$)/i.test(ct))
          return reply({error:"invalid_content_type"},415);
        if (Number(request.headers.get("content-length")||0)>MAX_BODY)
          return reply({error:"payload_too_large"},413);
        let body;
        try { body=await limitedJson(request,MAX_BODY); }
        catch(e) {
          return reply({error:String(e.message)},e.message==="payload_too_large"?413:400);
        }
        const events=body?.events;
        if (!Array.isArray(events) || !events.length || events.length>MAX_BATCH)
          return reply({error:"invalid_batch"},400);
        const ids=new Set();
        for (const e of events) {
          if (!e || typeof e!=="object" || typeof e.event_id!=="string"
            || !EVENT_ID.test(e.event_id) || !SOURCES.has(e.catalog)
            || typeof e.port_id!=="string" || !PORT_ID.test(e.port_id))
            return reply({error:"invalid_event"},400);
          if (ids.has(e.event_id)) return reply({error:"duplicate_event_in_batch"},400);
          ids.add(e.event_id);
        }
        // Limita EVENTOS por IP/colo, nao apenas o numero de requests.
        // Nao e prova de download. E aproximado e pode afetar redes com NAT.
        const rate=await env.EVENT_RATE_LIMITER.limit({
          key:"stats-events:"+ip,delta:events.length
        });
        if (!rate.success) return reply({error:"rate_limited"},429);
        // Valida o lote inteiro ANTES de inserir. Nao mistura categorias.
        const keys=new Set();
        for (const e of events) {
          const key=e.catalog+":"+e.port_id;
          if (keys.has(key)) continue;
          keys.add(key);
          const allowed=await env.DB.prepare(
            "SELECT 1 AS allowed FROM approved_ports "+
            "WHERE catalog = ? AND port_id = ? AND active = 1"
          ).bind(e.catalog,e.port_id).first();
          if (!allowed) return reply({error:"port_not_approved"},422);
        }
        await env.DB.batch(events.map(e=>env.DB.prepare(
          "INSERT OR IGNORE INTO download_events (event_id,catalog,port_id) VALUES (?,?,?)"
        ).bind(e.event_id,e.catalog,e.port_id)));
        return reply({acknowledged:events.map(e=>e.event_id)});
      }
      return reply({error:"not_found"},404);
    } catch(e) {
      console.error("Stats error",String(e));
      return reply({error:"temporarily_unavailable"},503);
    }
  }
};
