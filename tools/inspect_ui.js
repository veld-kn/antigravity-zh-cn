const http = require('http');
const fs = require('fs');
const path = require('path');

function getDevToolsPort() {
  const portFile = path.join(process.env.APPDATA, 'antigravity', 'DevToolsActivePort');
  const content = fs.readFileSync(portFile, 'utf8');
  return parseInt(content.split('\n')[0].trim(), 10);
}

async function getWsUrl() {
  const port = getDevToolsPort();
  return new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}/json`, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        const list = JSON.parse(d);
        resolve(list[0].webSocketDebuggerUrl);
      });
    }).on('error', reject);
  });
}

async function evalInBrowser(expr) {
  const wsUrl = await getWsUrl();
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: {
          expression: expr,
          returnByValue: true
        }
      }));
    };
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id === 1) {
        ws.close();
        if (msg.error) reject(msg.error);
        else resolve(msg.result.result ? msg.result.result.value : msg.result);
      }
    };
    ws.onerror = reject;
  });
}

async function main() {
  try {
    const res = await evalInBrowser(`
      (() => {
        const selectors = 'button, [role="button"], [role="tab"], [role="menuitem"], input, textarea, label, [aria-label], [title], .ant-btn, .btn, span, div, a';
        const elements = Array.from(document.querySelectorAll(selectors));
        const chinese = [];
        const english = [];
        for (const el of elements) {
          if (el.closest('.prose, pre, code, .markdown')) continue;
          const text = (el.innerText || el.placeholder || el.getAttribute('aria-label') || el.getAttribute('title') || '').trim();
          if (!text || text.length > 50) continue;
          if (/[\\u4e00-\\u9fff]/.test(text)) {
            if (!chinese.includes(text)) chinese.push(text);
          } else if (/[a-zA-Z]/.test(text)) {
            if (!english.includes(text)) english.push(text);
          }
        }
        return {
          title: document.title,
          chineseCount: chinese.length,
          englishCount: english.length,
          chineseSample: chinese.slice(0, 25),
          englishSample: english.slice(0, 25)
        };
      })()
    `);
    console.log('UI Inspection:\n', JSON.stringify(res, null, 2));
  } catch (err) {
    console.error('Inspection failed:', err);
  }
}

main();
