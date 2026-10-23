/* Character Lens prototype logic, shared by all design options.
   Recognition is mocked (picks the nearest sample by stroke count); everything else follows the PRD flow:
   model state -> draw -> auto-recognize after 600 ms -> candidate chips -> result sheet (dictionary first, AI fills in). */
(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const phone = $('.phone');
  const esc = (t) => String(t).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

  const LANGS = {
    CN: { name: 'Chinese', short: 'CN', html: 'zh-Hans', tts: 'zh-CN', reading: 'Pinyin', size: '12 MB' },
    JP: { name: 'Japanese', short: 'JP', html: 'ja', tts: 'ja-JP', reading: 'On · Kun', size: '18 MB' },
    KO: { name: 'Korean (Hanja)', short: 'KO', html: 'ko', tts: 'ko-KR', reading: 'Hangul', size: '' },
  };

  /* Sample data shaped like the Unihan-derived dictionary + a validated AI explanation. */
  const DICT = {
    mu: {
      strokes: 4, def: 'tree; wood',
      form: { CN: '木', JP: '木', KO: '木' },
      read: { CN: 'mù', JP: 'モク・ボク · き', KO: '목 (mok)' },
      variant: {},
      ai: {
        components: [{ part: '木', role: 'Pictograph of a tree: trunk in the middle, branches above, roots below.' }],
        mnemonic: 'Picture a tree: the vertical stroke is the trunk, the horizontal one is the branches, and the two flicks are the roots.',
        examples: [
          { word: '木材', reading: 'mùcái', meaning: 'timber; lumber', ok: true },
          { word: '木曜日', reading: 'もくようび', meaning: 'Thursday', ok: true },
        ],
        note: 'Alone, Japanese reads it き (ki); Chinese is always mù.',
      },
    },
    sui: {
      strokes: 4, def: 'water',
      form: { CN: '水', JP: '水', KO: '水' },
      read: { CN: 'shuǐ', JP: 'スイ · みず', KO: '수 (su)' },
      variant: {},
      ai: {
        components: [{ part: '水', role: 'Pictograph of a flowing stream with droplets on either side.' }],
        mnemonic: 'A river running down the middle with splashes on both banks.',
        examples: [
          { word: '水果', reading: 'shuǐguǒ', meaning: 'fruit', ok: true },
          { word: '水曜日', reading: 'すいようび', meaning: 'Wednesday', ok: true },
        ],
        note: '',
      },
    },
    nichi: {
      strokes: 4, def: 'sun; day',
      form: { CN: '日', JP: '日', KO: '日' },
      read: { CN: 'rì', JP: 'ニチ・ジツ · ひ・か', KO: '일 (il)' },
      variant: {},
      ai: {
        components: [{ part: '日', role: 'Pictograph of the sun, squared off over time; the middle stroke is a sunspot.' }],
        mnemonic: 'A window with the sun shining through it: one sun is one day.',
        examples: [
          { word: '生日', reading: 'shēngrì', meaning: 'birthday', ok: true },
          { word: '日本', reading: 'にほん', meaning: 'Japan', ok: true },
        ],
        note: 'Japanese has many readings (ニチ, ジツ, ひ, か); Chinese uses mostly rì.',
      },
    },
    gaku: {
      strokes: 8, def: 'study; learn; school',
      form: { CN: '学', JP: '学', KO: '學' },
      read: { CN: 'xué', JP: 'ガク · まな-ぶ', KO: '학 (hak)' },
      variant: { CN: 'Traditional 學', JP: 'Traditional 學' },
      ai: {
        components: [
          { part: '⺍', role: 'Two hands above, passing knowledge down.' },
          { part: '冖', role: 'A roof: the schoolhouse.' },
          { part: '子', role: 'A child, the learner.' },
        ],
        mnemonic: 'A child (子) under a roof (冖) receiving knowledge from above.',
        examples: [
          { word: '学生', reading: 'xuésheng', meaning: 'student', ok: true },
          { word: '大学', reading: 'だいがく', meaning: 'university', ok: true },
        ],
        note: 'The simplified Chinese form and the Japanese form are the same here.',
      },
    },
    go: {
      strokes: 14, def: 'language; word; speech',
      form: { CN: '语', JP: '語', KO: '語' },
      read: { CN: 'yǔ', JP: 'ゴ · かた-る', KO: '어 (eo)' },
      variant: { CN: 'Traditional 語', JP: 'Simplified 语' },
      ai: {
        components: [
          { part: '言', role: 'Speech radical: a mouth with words coming out.' },
          { part: '吾', role: 'Phonetic hint: sounds like ご (go), also means “I”.' },
        ],
        mnemonic: 'Words (言) that come from “I” (吾): the things you say yourself.',
        examples: [
          { word: '日本語', reading: 'にほんご', meaning: 'Japanese language', ok: true },
          { word: '語感', reading: 'ごかん', meaning: 'feel for language', ok: false },
        ],
        note: '',
      },
    },
  };
  const ORDER = ['mu', 'sui', 'nichi', 'gaku', 'go'];

  const S = {
    lang: 'CN',
    model: { CN: 'ready', JP: 'idle' }, // idle | downloading | ready | failed
    strokes: [], cands: [], sel: 0,
    open: null, // { id, lang }
    cache: new Set(['mu|CN', 'sui|JP', 'nichi|CN']),
    history: [{ id: 'nichi', lang: 'CN', ago: '2 min ago' }, { id: 'sui', lang: 'JP', ago: 'Yesterday' }, { id: 'mu', lang: 'CN', ago: 'Yesterday' }],
  };
  let timer = 0, busy = false, aiTimer = 0;

  /* ---------- status / model ---------- */
  function setStatus(kind, text) {
    phone.dataset.state = kind;
    $$('[data-bind=status]').forEach((e) => (e.textContent = text));
  }
  const idleText = () => (S.strokes.length ? 'Looking good. Pause and I’ll recognise it' : 'Ready. Draw one character');

  function renderModel() {
    const m = S.model[S.lang], L = LANGS[S.lang];
    phone.dataset.modelState = m;
    const text = {
      idle: `${L.name} model · ${L.size} · not downloaded`,
      downloading: `Downloading ${L.name} model…`,
      ready: `${L.name} model ready · on-device`,
      failed: 'Download failed. Check your connection',
    }[m];
    $$('[data-bind=model]').forEach((e) => (e.textContent = text));
    $$('[data-act=download]').forEach((b) => {
      b.hidden = !(m === 'idle' || m === 'failed');
      b.textContent = m === 'failed' ? 'Retry' : 'Download';
    });
    $$('[data-bar]').forEach((b) => (b.hidden = m !== 'downloading'));
  }

  function download() {
    const lang = S.lang;
    S.model[lang] = 'downloading';
    renderModel();
    setStatus('busy', 'Downloading model');
    const fills = $$('[data-bar] .bar-fill');
    let p = 0;
    const iv = setInterval(() => {
      p += 9 + Math.random() * 10;
      fills.forEach((f) => (f.style.width = Math.min(p, 100) + '%'));
      if (p >= 100) {
        clearInterval(iv);
        S.model[lang] = 'ready';
        if (S.lang === lang) { renderModel(); setStatus('ready', idleText()); }
        toast(`${LANGS[lang].name} model ready`);
      }
    }, 180);
  }

  function setLang(l) {
    if (l === S.lang) return;
    S.lang = l;
    $$('[data-lang]').forEach((b) => b.setAttribute('aria-pressed', b.dataset.lang === l));
    $$('[data-lang]').forEach((b) => b.classList.toggle('active', b.dataset.lang === l));
    clearAll();
    renderModel();
    if (S.model[l] === 'ready') setStatus('ready', idleText());
    else setStatus('ready', 'Download the model to start drawing');
  }

  /* ---------- canvas ---------- */
  const canvas = $('#pad');
  const ctx = canvas.getContext('2d');
  let cur = null, dpr = 1;

  function fit() {
    dpr = window.devicePixelRatio || 1;
    const r = canvas.getBoundingClientRect();
    const z = parseFloat(getComputedStyle(phone).zoom) || 1;
    canvas.width = Math.round((r.width / z) * dpr);
    canvas.height = Math.round((r.height / z) * dpr);
    redraw();
  }
  function redraw() {
    const w = canvas.width, h = canvas.height;
    ctx.clearRect(0, 0, w, h);
    const css = getComputedStyle(canvas);
    ctx.strokeStyle = css.getPropertyValue('--ink').trim() || '#111';
    ctx.lineWidth = (parseFloat(canvas.dataset.width) || 8) * dpr;
    ctx.lineCap = ctx.lineJoin = 'round';
    for (const s of S.strokes) {
      const p = s.pts;
      if (!p.length) continue;
      ctx.beginPath();
      ctx.moveTo(p[0].x * dpr, p[0].y * dpr);
      if (p.length === 1) ctx.lineTo(p[0].x * dpr + 0.1, p[0].y * dpr);
      for (let i = 1; i < p.length - 1; i++) {
        const mx = (p[i].x + p[i + 1].x) / 2, my = (p[i].y + p[i + 1].y) / 2;
        ctx.quadraticCurveTo(p[i].x * dpr, p[i].y * dpr, mx * dpr, my * dpr);
      }
      if (p.length > 1) ctx.lineTo(p[p.length - 1].x * dpr, p[p.length - 1].y * dpr);
      ctx.stroke();
    }
  }
  const pt = (e) => {
    const r = canvas.getBoundingClientRect();
    const z = parseFloat(getComputedStyle(phone).zoom) || 1;
    return { x: (e.clientX - r.left) / z, y: (e.clientY - r.top) / z, t: Math.round(e.timeStamp) };
  };
  canvas.addEventListener('pointerdown', (e) => {
    if (busy || S.model[S.lang] !== 'ready') return;
    canvas.setPointerCapture(e.pointerId);
    clearTimeout(timer);
    cur = { pts: [pt(e)] };
    S.strokes.push(cur);
    S.cands = []; renderCands();
    setStatus('drawing', 'Drawing…');
    sync(); redraw();
  });
  canvas.addEventListener('pointermove', (e) => {
    if (!cur) return;
    cur.pts.push(pt(e));
    redraw();
  });
  const end = () => {
    if (!cur) return;
    cur = null;
    setStatus('ready', idleText());
    timer = setTimeout(recognize, 600);
  };
  canvas.addEventListener('pointerup', end);
  canvas.addEventListener('pointercancel', end);

  function sync() {
    phone.dataset.ink = S.strokes.length ? '1' : '0';
    $$('[data-act=undo],[data-act=clear]').forEach((b) => (b.disabled = !S.strokes.length || busy));
    $$('[data-act=analyze]').forEach((b) => (b.disabled = busy));
    const lab = S.cands.length ? `Look up ${DICT[S.cands[S.sel]].form[S.lang]}` : 'Analyze';
    $$('[data-bind=cta]').forEach((e) => (e.textContent = lab));
  }
  function clearAll() {
    clearTimeout(timer);
    S.strokes = []; S.cands = []; S.sel = 0; cur = null;
    redraw(); renderCands(); sync();
    setStatus('ready', idleText());
  }
  function undo() {
    clearTimeout(timer);
    S.strokes.pop(); S.cands = []; S.sel = 0;
    redraw(); renderCands(); sync();
    if (S.strokes.length) timer = setTimeout(recognize, 600);
    setStatus('ready', idleText());
  }

  /* ---------- recognition (mock) ---------- */
  function recognize(then) {
    clearTimeout(timer);
    if (!S.strokes.length) { setStatus('error', 'Draw a character first'); return; }
    busy = true; phone.classList.add('busy'); sync();
    setStatus('busy', 'Recognizing…');
    const n = S.strokes.length;
    const seed = Math.round(S.strokes[0].pts[0].x + S.strokes[0].pts[0].y) % 3;
    const ranked = ORDER.map((id, i) => ({ id, d: Math.abs(DICT[id].strokes - n) + ((i + seed) % 3) * 0.01 + i * 0.001 }))
      .sort((a, b) => a.d - b.d).map((o) => o.id);
    setTimeout(() => {
      busy = false; phone.classList.remove('busy');
      S.cands = ranked; S.sel = 0;
      renderCands(); sync();
      setStatus('done', 'Pick a match, then look up');
      if (typeof then === 'function') then();
    }, 420);
  }

  function renderCands() {
    $$('#cands').forEach((box) => {
      if (!S.cands.length) { box.innerHTML = '<p class="cands-empty">Matches appear here after you draw</p>'; return; }
      box.innerHTML = S.cands.slice(0, 5).map((id, i) =>
        `<button class="chip" data-i="${i}" lang="${LANGS[S.lang].html}" aria-pressed="${i === S.sel}" aria-label="Candidate ${i + 1}: ${esc(DICT[id].form[S.lang])}">${esc(DICT[id].form[S.lang])}</button>`).join('');
    });
  }

  /* ---------- result sheet ---------- */
  const body = $('#sheetBody');
  const spk = '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 9.5v5h3.5L12 18.5v-13L7.5 9.5H4z"/><path d="M15.5 9a4.2 4.2 0 0 1 0 6M18 6.5a8 8 0 0 1 0 11"/></svg>';

  function aiHTML(id, lang) {
    const a = DICT[id].ai;
    const comps = a.components.map((c) => `<li><span class="comp-part" lang="zh-Hans">${esc(c.part)}</span><span class="comp-role">${esc(c.role)}</span></li>`).join('');
    const ex = a.examples.map((x) => `<li class="ex"><span class="ex-word" lang="${/[ぁ-ん]/.test(x.word + x.reading) ? 'ja' : 'zh-Hans'}">${esc(x.word)}</span><span class="ex-read">${esc(x.reading)}</span><span class="ex-mean">${esc(x.meaning)}</span>${x.ok ? '' : '<span class="flag" title="Reading not found in the dictionary">Unverified reading</span>'}</li>`).join('');
    return `<div class="ai-block"><h4>Components</h4><ul class="comps">${comps}</ul></div>
      <div class="ai-block"><h4>Memory hook</h4><p class="mnemonic">${esc(a.mnemonic)}</p></div>
      <div class="ai-block"><h4>Example words</h4><ul class="exs">${ex}</ul></div>
      ${a.note ? `<div class="ai-block"><h4>CN vs JP</h4><p class="note">${esc(a.note)}</p></div>` : ''}`;
  }
  const skeleton = '<div class="ai-skel" aria-label="Generating explanation"><span class="sk" style="width:38%"></span><span class="sk" style="width:92%"></span><span class="sk" style="width:80%"></span><span class="sk" style="width:55%;margin-top:14px"></span><span class="sk" style="width:86%"></span></div>';

  function openSheet(id, lang, fromHistory) {
    const d = DICT[id], L = LANGS[lang];
    S.open = { id, lang };
    const key = `${id}|${lang}`;
    const cached = S.cache.has(key);
    if (!fromHistory) {
      S.history = S.history.filter((h) => !(h.id === id && h.lang === lang));
      S.history.unshift({ id, lang, ago: 'Just now' });
      S.history = S.history.slice(0, 50);
      renderHistory();
    }
    const variant = d.variant[lang];
    const cross = ['CN', 'JP', 'KO'].map((k) => `<li class="x-item${k === lang ? ' is-current' : ''}"><span class="x-lang">${k}</span><span class="x-char" lang="${LANGS[k].html}">${esc(d.form[k])}</span><span class="x-read">${esc(d.read[k])}</span></li>`).join('');
    const others = !fromHistory && S.cands.length > 1
      ? `<div class="s-cands"><span class="s-cands-l">Not it?</span>${S.cands.slice(0, 5).map((cid, i) => `<button class="chip${cid === id ? ' on' : ''}" data-sc="${cid}" lang="${L.html}" aria-pressed="${cid === id}">${esc(DICT[cid].form[lang])}</button>`).join('')}</div>` : '';
    body.innerHTML = `
      <div class="s-head">
        <div class="s-char" lang="${L.html}">${esc(d.form[lang])}</div>
        <div class="s-meta">
          <span class="tag tag-lang">${L.name}</span>
          ${variant ? `<span class="tag tag-var">${esc(variant)}</span>` : ''}
          <span class="s-def">${esc(d.def)}</span>
        </div>
        <button class="speak" data-act="speak" aria-label="Play pronunciation">${spk}</button>
      </div>
      ${others}
      <section class="card dict" aria-label="Dictionary">
        <header class="card-h"><h3>Dictionary</h3><span class="badge verified"><svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>Verified · Unihan</span></header>
        <dl class="kv">
          <div><dt>${L.reading}</dt><dd class="v-read">${esc(d.read[lang])}</dd></div>
          <div><dt>Meaning</dt><dd>${esc(d.def)}</dd></div>
        </dl>
      </section>
      <section class="card cross" aria-label="Across languages">
        <header class="card-h"><h3>Across languages</h3><span class="card-sub">same character</span></header>
        <ul class="xl">${cross}</ul>
      </section>
      <section class="card ai" aria-label="AI explanation">
        <header class="card-h"><h3>Explain it</h3><span class="badge ai-b"><svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor" aria-hidden="true"><path d="M12 2l1.9 6.1L20 10l-6.1 1.9L12 18l-1.9-6.1L4 10l6.1-1.9z"/></svg>AI-generated</span></header>
        <div class="ai-body" aria-live="polite">${cached ? aiHTML(id, lang) : skeleton}</div>
        <p class="ai-foot">Readings above come from the dictionary. Memory hooks can be plausible-sounding folk etymology.</p>
      </section>
      <p class="s-foot">Data: Unicode Unihan · Handwriting stays on your device</p>`;
    body.parentElement.scrollTop = 0;
    phone.classList.add('open');
    clearTimeout(aiTimer);
    if (!cached) {
      aiTimer = setTimeout(() => {
        S.cache.add(key);
        if (S.open && S.open.id === id && S.open.lang === lang) {
          const el = $('.ai-body', body);
          if (el) { el.innerHTML = aiHTML(id, lang); el.classList.add('in'); }
        }
      }, 1500);
    }
    setTimeout(() => $('[data-act=close]')?.focus({ preventScroll: true }), 50);
  }
  function closeSheet() {
    phone.classList.remove('open');
    clearTimeout(aiTimer);
    S.open = null;
    speechSynthesis?.cancel?.();
    phone.classList.remove('speaking');
  }

  function speak() {
    if (!S.open) return;
    const { id, lang } = S.open;
    const synth = window.speechSynthesis;
    const voices = synth ? synth.getVoices() : [];
    if (!synth || (voices.length && !voices.some((v) => v.lang.startsWith(LANGS[lang].tts.slice(0, 2))))) {
      toast('No voice installed for this language');
      return;
    }
    synth.cancel();
    const u = new SpeechSynthesisUtterance(DICT[id].form[lang]);
    u.lang = LANGS[lang].tts;
    u.onstart = () => phone.classList.add('speaking');
    u.onend = u.onerror = () => phone.classList.remove('speaking');
    synth.speak(u);
  }

  /* ---------- history ---------- */
  function renderHistory() {
    const box = $('#hist');
    if (!box) return;
    $$('[data-bind=histCount]').forEach((e) => (e.textContent = S.history.length));
    if (!S.history.length) { box.innerHTML = '<p class="empty">Characters you look up appear here, and open instantly offline.</p>'; return; }
    box.innerHTML = S.history.map((h, i) => {
      const d = DICT[h.id], L = LANGS[h.lang];
      return `<li><button class="h-item" data-h="${i}"><span class="h-char" lang="${L.html}">${esc(d.form[h.lang])}</span><span class="h-main"><span class="h-read">${esc(d.read[h.lang])}</span><span class="h-def">${esc(d.def)}</span></span><span class="h-side"><span class="tag tag-lang">${h.lang}</span><span class="h-ago">${esc(h.ago)}</span></span></button></li>`;
    }).join('');
  }

  function setTab(t) {
    phone.dataset.tab = t;
    $$('[data-view]').forEach((v) => (v.hidden = v.dataset.view !== t));
    $$('[data-tab]').forEach((b) => { const on = b.dataset.tab === t; b.setAttribute('aria-current', on ? 'page' : 'false'); b.classList.toggle('active', on); });
    if (t === 'draw') requestAnimationFrame(fit);
  }

  function toast(msg) {
    let t = $('#toast');
    if (!t) { t = document.createElement('div'); t.id = 'toast'; t.className = 'toast'; t.setAttribute('role', 'status'); phone.appendChild(t); }
    t.textContent = msg; t.classList.add('show');
    clearTimeout(t._h); t._h = setTimeout(() => t.classList.remove('show'), 2200);
  }

  /* ---------- wiring ---------- */
  document.addEventListener('click', (e) => {
    const a = e.target.closest('[data-act],[data-lang],[data-tab],.chip,.h-item,[data-close]');
    if (!a) return;
    if (a.dataset.lang) return setLang(a.dataset.lang);
    if (a.dataset.tab) return setTab(a.dataset.tab);
    if (a.dataset.close !== undefined) return closeSheet();
    if (a.dataset.h !== undefined) { const h = S.history[+a.dataset.h]; return openSheet(h.id, h.lang, true); }
    if (a.dataset.sc) { S.sel = S.cands.indexOf(a.dataset.sc); renderCands(); sync(); return openSheet(a.dataset.sc, S.lang); }
    if (a.classList.contains('chip') && a.dataset.i !== undefined) { S.sel = +a.dataset.i; renderCands(); sync(); return; }
    switch (a.dataset.act) {
      case 'undo': return undo();
      case 'clear': return clearAll();
      case 'download': return download();
      case 'close': return closeSheet();
      case 'speak': return speak();
      case 'analyze':
        if (busy) return;
        if (!S.strokes.length) { setStatus('error', 'Draw a character first'); phone.classList.remove('shake'); void phone.offsetWidth; phone.classList.add('shake'); return; }
        if (!S.cands.length) return recognize(() => openSheet(S.cands[0], S.lang));
        setStatus('busy', 'Looking up…');
        return setTimeout(() => { openSheet(S.cands[S.sel], S.lang); setStatus('done', 'Pick a match, then look up'); }, 120);
    }
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeSheet(); });
  window.addEventListener('resize', fit);
  new ResizeObserver(fit).observe(canvas);
  if (speechSynthesis) speechSynthesis.getVoices();

  renderModel(); renderCands(); renderHistory(); sync();
  setStatus('ready', idleText());
  setTab('draw');
  $$('[data-lang]').forEach((b) => { b.setAttribute('aria-pressed', b.dataset.lang === S.lang); b.classList.toggle('active', b.dataset.lang === S.lang); });
  fit();
})();
