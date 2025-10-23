INDEX_HTML = r'''<!DOCTYPE html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Vibe Landing Zone — Max Vibe Edition</title>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;600&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet" />
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/monokai.min.css">
<style>
  :root { --fg:#e5e7eb; --bg:#000 }
  html,body{height:100%;margin:0} body{background:var(--bg);color:var(--fg);font-family:'IBM Plex Sans',system-ui;overflow:hidden}
  #editor{position:fixed;top:7vh;left:6vw;width:calc(100vw - 12vw);min-height:40vh;background:rgba(10,12,18,.78);border:1px solid rgba(147,197,253,.15);border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.45),0 0 40px rgba(15,98,254,.22) inset;z-index:4}
  #editor-title{display:flex;gap:.6rem;align-items:center;padding:.8rem 1rem;border-bottom:1px solid rgba(147,197,253,.15)}
  .dot{width:.7rem;height:.7rem;border-radius:50%}
  #actions{display:flex;justify-content:flex-end;gap:.5rem;padding:.8rem 1rem 1rem}
  .btn{border:none;border-radius:9999px;padding:.65rem 1.1rem;font-weight:800;background:linear-gradient(135deg,#3b82f6,#22d3ee);color:#fff;cursor:pointer}
  .secondary-btn{background:rgba(147,197,253,.08);color:#c7d2fe;border:1px solid rgba(147,197,253,.3);border-radius:9999px;padding:.5rem .9rem;font-weight:600;cursor:pointer}
  #banner{position:fixed;top:10px;left:50%;transform:translateX(-50%);background:rgba(17,24,39,.85);color:#e5e7eb;padding:.6rem 1rem;border-radius:12px;border:1px solid rgba(99,102,241,.4);display:none;z-index:10}
  #ai-credit{position:fixed;bottom:12px;right:14px;cursor:pointer;z-index:10}
  #ai-credit img{width:36px;height:36px;filter:drop-shadow(0 0 6px rgba(255,255,255,.4));transition:transform .25s ease}
  #ai-credit:hover img{transform:scale(1.08)}
  #ai-credit .tooltip{position:absolute;bottom:45px;right:0;background:rgba(0,0,0,.9);color:#fff;padding:8px 10px;border-radius:8px;font-size:.8rem;white-space:nowrap;opacity:0;pointer-events:none;transform:translateY(5px);transition:all .25s ease}
  #ai-credit:hover .tooltip,#ai-credit:focus-within .tooltip{opacity:1;transform:translateY(0)}
  .CodeMirror{height:36vh;border-top:1px solid rgba(147,197,253,.15)}
</style></head>
<body>
<div id="banner"></div>
<section id="editor" aria-label="Vibe code editor">
  <div id="editor-title">
    <span class="dot" style="background:#ff5f56"></span>
    <span class="dot" style="background:#ffbd2f"></span>
    <span class="dot" style="background:#27c93f"></span>
    <span class="ml-2" style="opacity:.8">/vibe-code.html</span>
  </div>
  <textarea id="code" spellcheck="false"></textarea>
  <div id="actions">
    <button id="copyCode" class="secondary-btn" type="button">Copy Code ❐</button>
    <button id="revert" class="secondary-btn" type="button">Revert ↩</button>
    <button id="updateProject" class="secondary-btn" type="button">Pro Update 🌈</button>
    <button id="manifest" class="btn" type="button">Manifest ✨</button>
  </div>
</section>
<div id="ai-credit" tabindex="0">
  <img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImciIHgxPSIwIiB5MT0iMCIgeDI9IjEiIHkyPSIxIj4KICAgIDxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9IiM3QzNBRUQiLz48c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiMwNkI2RDQiLz4KICA8L2xpbmVhckdyYWRpZW50PjwvZGVmcz4KICA8cmVjdCB4PSIyIiB5PSIyIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHJ4PSIxNCIgc3Ryb2tlPSJ1cmwoI2cpIiBzdHJva2Utd2lkdGg9IjIiIGZpbGw9ImJsYWNrIi8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MiUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZpbGw9IndoaXRlIiBmb250LWZhbWlseT0iSUJNIFBsZXggU2FucyIgZm9udC1zaXplPSIyMCIgZm9udC13ZWlnaHQ9IjcwMCI+QUk8L3RleHQ+Cjwvc3ZnPg==" alt="AI-assisted"/>
  <div class="tooltip">
    🤖 Made with AI assistance, inspired by Arn Hyndman’s
    <a href="https://cloud.ibm.com/catalog" target="_blank" style="color:#a5b4fc">Static Website Deployable Architecture</a>.
  </div>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/xml/xml.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/javascript/javascript.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/css/css.min.js"></script>
<script>
const UPLOAD = "%%UPLOAD_ENDPOINT%%";
const STATUS = "%%STATUS_ENDPOINT%%";
const PROJECT_UPDATE = "%%PROJECT_UPDATE_ENDPOINT%%";
const ANALYTICS = "%%ANALYTICS_ENDPOINT%%";
const REGION = "%%REGION%%";
const BUCKET = "%%BUCKET%%";

const starter = `<!-- Welcome to the Vibe IDE 🎛️ -->
<!doctype html>
<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>
<title>My Vibe</title>
<style>body{font-family:IBM Plex Sans,system-ui;background:#0b0d14;color:#e5e7eb;padding:2rem} a{color:#93c5fd}</style></head>
<body><h1>✨ Hello, Vibe!</h1>
<p>Edit this and press <b>Manifest</b> to deploy to your COS bucket.</p>
<p>Public URL will be <code>https://${BUCKET}.${REGION}.cloud-object-storage.appdomain.cloud/index.html</code></p>
<p>Powered by IBM Cloud.</p></body></html>`;

function showBanner(msg, ok=true) { const b=document.getElementById('banner'); b.textContent=(ok?'✅ ':'⚠️ ')+msg; b.style.display='block'; }

const cm = CodeMirror.fromTextArea(document.getElementById('code'), { mode:'xml', theme:'monokai', lineNumbers:true });
cm.setValue(starter);

async function manifest() { const html=cm.getValue();
  showBanner('Deploying…');
  try { await fetch(ANALYTICS, {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({event:'manifest', REGION})}); } catch(e){}
  const r = await fetch(UPLOAD, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ body: html, key:'index.html' }) });
  const j = await r.json();
  if (j.ok) { showBanner('Deployed! Opening new tab…'); const url=`https://${BUCKET}.${REGION}.cloud-object-storage.appdomain.cloud/index.html`; setTimeout(()=>window.open(url,'_blank'),700); }
  else { showBanner('Upload failed. See console.', false); console.error(j); }
}
async function updateProject() { await fetch(PROJECT_UPDATE, {method:'POST'}); showBanner('Project update request posted. Review in your IBM Cloud Project.'); }
document.getElementById('manifest').addEventListener('click', manifest);
document.getElementById('updateProject').addEventListener('click', updateProject);
document.getElementById('revert').addEventListener('click', ()=> showBanner('Revert coming soon — use previous version in COS if needed.'));
document.getElementById('copyCode').addEventListener('click', ()=> { navigator.clipboard.writeText(cm.getValue()); showBanner('Code copied.'); });
</script></body></html>'''

def main(params):
    return {"statusCode": 200, "headers": {"Content-Type": "text/html; charset=utf-8"}, "body": INDEX_HTML}
