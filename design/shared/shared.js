/* Mock behaviour shared by all options: drawing, language switch, fake analysis, TTS. */
const LANGS = {
  CN: { name: 'Chinese', script: 'Hanzi', glyph: '中', html: 'zh-Hans', tts: 'zh-CN', romanLabel: 'Pinyin', hint: 'Draw a Chinese character',
    entries: [
      { char: '木', roman: 'mù', meaning: 'Tree, wood', matches: [
        { lang: 'Japanese', code: 'JP', html: 'ja', text: '木', read: 'ki, moku', gloss: 'Tree' },
        { lang: 'Korean', code: 'KR', html: 'ko', text: '木', read: 'mok', gloss: 'Tree' }] },
      { char: '本', roman: 'běn', meaning: 'Root, origin; book', matches: [
        { lang: 'Japanese', code: 'JP', html: 'ja', text: '本', read: 'hon', gloss: 'Book, origin' },
        { lang: 'Korean', code: 'KR', html: 'ko', text: '本', read: 'bon', gloss: 'Origin' }] },
      { char: '末', roman: 'mò', meaning: 'End, tip', matches: [
        { lang: 'Japanese', code: 'JP', html: 'ja', text: '末', read: 'sue, matsu', gloss: 'End' },
        { lang: 'Korean', code: 'KR', html: 'ko', text: '末', read: 'mal', gloss: 'End' }] }] },
  KO: { name: 'Korean', script: 'Hanja', glyph: '한', html: 'ko', tts: 'ko-KR', romanLabel: 'Romanization', hint: 'Draw a Hanja character',
    entries: [
      { char: '水', roman: 'su', meaning: 'Water', matches: [
        { lang: 'Chinese', code: 'CN', html: 'zh-Hans', text: '水', read: 'shuǐ', gloss: 'Water' },
        { lang: 'Japanese', code: 'JP', html: 'ja', text: '水', read: 'mizu, sui', gloss: 'Water' }] },
      { char: '氷', roman: 'bing', meaning: 'Ice', matches: [
        { lang: 'Chinese', code: 'CN', html: 'zh-Hans', text: '冰', read: 'bīng', gloss: 'Ice' },
        { lang: 'Japanese', code: 'JP', html: 'ja', text: '氷', read: 'kōri, hyō', gloss: 'Ice' }] },
      { char: '永', roman: 'yeong', meaning: 'Eternal, long', matches: [
        { lang: 'Chinese', code: 'CN', html: 'zh-Hans', text: '永', read: 'yǒng', gloss: 'Eternal' },
        { lang: 'Japanese', code: 'JP', html: 'ja', text: '永', read: 'ei', gloss: 'Eternal' }] }] },
  AR: { name: 'Arabic', script: 'Arabic', glyph: 'ع', html: 'ar', tts: 'ar-SA', romanLabel: 'Transliteration', hint: 'Write an Arabic letter or word',
    entries: [
      { char: 'كتاب', roman: 'kitāb', meaning: 'Book', matches: [
        { lang: 'Persian', code: 'FA', html: 'fa', text: 'کتاب', read: 'ketâb', gloss: 'Book' },
        { lang: 'Urdu', code: 'UR', html: 'ur', text: 'کتاب', read: 'kitāb', gloss: 'Book' },
        { lang: 'Indonesian', code: 'ID', html: 'id', text: 'kitab', read: 'kitab', gloss: 'Scripture' }] },
      { char: 'كتب', roman: 'kutub', meaning: 'Books', matches: [
        { lang: 'Persian', code: 'FA', html: 'fa', text: 'کتب', read: 'kotob', gloss: 'Books' },
        { lang: 'Urdu', code: 'UR', html: 'ur', text: 'کتب', read: 'kutub', gloss: 'Books' }] },
      { char: 'كاتب', roman: 'kātib', meaning: 'Writer, scribe', matches: [
        { lang: 'Persian', code: 'FA', html: 'fa', text: 'کاتب', read: 'kâteb', gloss: 'Scribe' },
        { lang: 'Urdu', code: 'UR', html: 'ur', text: 'کاتب', read: 'kātib', gloss: 'Scribe' }] }] },
  HI: { name: 'Hindi', script: 'Devanagari', glyph: 'हि', html: 'hi', tts: 'hi-IN', romanLabel: 'Transliteration', hint: 'Write a Hindi letter or word',
    entries: [
      { char: 'राजा', roman: 'rājā', meaning: 'King, ruler', matches: [
        { lang: 'Sanskrit', code: 'SA', html: 'sa', text: 'राजन्', read: 'rājan', gloss: 'King' },
        { lang: 'Indonesian', code: 'ID', html: 'id', text: 'raja', read: 'raja', gloss: 'King' }] },
      { char: 'राज', roman: 'rāj', meaning: 'Rule, reign', matches: [
        { lang: 'Urdu', code: 'UR', html: 'ur', text: 'راج', read: 'rāj', gloss: 'Rule' },
        { lang: 'Bengali', code: 'BN', html: 'bn', text: 'রাজ', read: 'raj', gloss: 'Rule' }] },
      { char: 'रजा', roman: 'razā', meaning: 'Consent, will', matches: [
        { lang: 'Urdu', code: 'UR', html: 'ur', text: 'رضا', read: 'razā', gloss: 'Consent' },
        { lang: 'Arabic', code: 'AR', html: 'ar', text: 'رضا', read: 'riḍā', gloss: 'Consent' }] }] }
};

(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const root = $('.phone'), cv = $('#canvas'), ctx = cv.getContext('2d');
  const status = $('#status'), analyzeBtn = $('[data-action=analyze]');
  const params = new URLSearchParams(location.search);
  let lang = LANGS[params.get('lang')] ? params.get('lang') : 'CN';
  let strokes = [], cur = null, busy = false, idx = 0;

  const bind = (k, v) => $$(`[data-bind="${k}"]`).forEach(el => (el.textContent = v));

  function fit() {
    const r = { width: cv.offsetWidth, height: cv.offsetHeight }, d = window.devicePixelRatio || 1;
    cv.width = r.width * d; cv.height = r.height * d;
    ctx.setTransform(d, 0, 0, d, 0, 0);
    paint();
  }
  function paint() {
    const r = { width: cv.offsetWidth, height: cv.offsetHeight };
    ctx.clearRect(0, 0, r.width, r.height);
    ctx.strokeStyle = ctx.fillStyle = getComputedStyle(cv).color;
    ctx.lineWidth = +cv.dataset.width || 7; ctx.lineCap = ctx.lineJoin = 'round';
    for (const s of strokes) {
      if (s.length === 1) { ctx.beginPath(); ctx.arc(s[0].x, s[0].y, ctx.lineWidth / 2, 0, 7); ctx.fill(); continue; }
      ctx.beginPath(); ctx.moveTo(s[0].x, s[0].y);
      for (let i = 1; i < s.length - 1; i++) {
        const mx = (s[i].x + s[i + 1].x) / 2, my = (s[i].y + s[i + 1].y) / 2;
        ctx.quadraticCurveTo(s[i].x, s[i].y, mx, my);
      }
      ctx.lineTo(s[s.length - 1].x, s[s.length - 1].y); ctx.stroke();
    }
  }
  const pt = e => { const r = cv.getBoundingClientRect(), k = r.width / cv.offsetWidth; return { x: (e.clientX - r.left) / k, y: (e.clientY - r.top) / k }; };

  function sync() {
    const n = strokes.length;
    root.dataset.state = busy ? 'analyzing' : n ? 'drawing' : 'ready';
    root.classList.toggle('busy', busy);
    if (status) status.textContent = busy ? 'Analyzing…' : n ? `${n} stroke${n > 1 ? 's' : ''}` : 'Ready for input';
    if (analyzeBtn) { analyzeBtn.disabled = busy || !n; const l = $('.label', analyzeBtn); if (l) l.textContent = busy ? 'Analyzing' : 'Analyze'; }
    $$('[data-action=clear],[data-action=undo]').forEach(b => (b.disabled = busy || !n));
    $$('[data-lang]').forEach(b => { b.disabled = busy; });
  }

  function setLang(code) {
    lang = code; const L = LANGS[code];
    $$('[data-lang]').forEach(b => { const on = b.dataset.lang === code; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on); });
    bind('hint', L.hint); bind('langName', L.name); bind('langCode', code); bind('langGlyph', L.glyph);
    bind('tag', `${L.name} (${L.script})`); bind('romanLabel', L.romanLabel);
    root.dataset.lang = code; cv.setAttribute('lang', L.html);
  }

  function renderEntry(i) {
    const L = LANGS[lang], e = L.entries[idx = i];
    bind('char', e.char); bind('roman', e.roman); bind('meaning', e.meaning);
    $$('[data-bind=char]').forEach(el => el.setAttribute('lang', L.html));
    $('#matches').innerHTML = e.matches.map(m => `<li class="match"><span class="m-lang"><b class="m-code">${m.code}</b>${m.lang}</span><span class="m-char" lang="${m.html}" dir="auto">${m.text}</span><span class="m-read">${m.read}</span><span class="m-gloss">${m.gloss}</span></li>`).join('');
    const c = $('#cands');
    if (c) c.innerHTML = L.entries.map((x, j) => `<button class="cand${j === i ? ' active' : ''}" data-i="${j}" aria-pressed="${j === i}" lang="${L.html}">${x.char}</button>`).join('');
  }

  const openSheet = () => { root.classList.add('open'); };
  const closeSheet = () => { root.classList.remove('open'); };

  function analyze() {
    if (busy || !strokes.length) return;
    busy = true; sync();
    setTimeout(() => { busy = false; renderEntry(0); sync(); openSheet(); }, 1100);
  }
  function speak(btn) {
    const L = LANGS[lang], e = L.entries[idx];
    if ('speechSynthesis' in window) { speechSynthesis.cancel(); const u = new SpeechSynthesisUtterance(e.char); u.lang = L.tts; speechSynthesis.speak(u); }
    btn.classList.add('speaking'); setTimeout(() => btn.classList.remove('speaking'), 1200);
  }

  cv.addEventListener('pointerdown', e => {
    if (busy) return; cv.setPointerCapture(e.pointerId);
    cur = [pt(e)]; strokes.push(cur); paint(); sync();
  });
  cv.addEventListener('pointermove', e => { if (cur) { cur.push(pt(e)); paint(); } });
  ['pointerup', 'pointercancel'].forEach(t => cv.addEventListener(t, () => { cur = null; }));

  document.addEventListener('click', e => {
    const t = e.target.closest('[data-action],[data-lang],.cand,[data-close]'); if (!t) return;
    if (t.dataset.lang) { setLang(t.dataset.lang); sync(); return; }
    if (t.classList.contains('cand')) { renderEntry(+t.dataset.i); return; }
    if (t.hasAttribute('data-close')) { closeSheet(); return; }
    switch (t.dataset.action) {
      case 'clear': strokes = []; paint(); sync(); break;
      case 'undo': strokes.pop(); paint(); sync(); break;
      case 'analyze': analyze(); break;
      case 'speak': speak(t); break;
      case 'close': closeSheet(); break;
    }
  });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') closeSheet(); });
  // desktop preview: scale the 844px phone down to fit short windows (not inside the index iframes)
  const scale = () => { if (window.top !== window) return; root.style.setProperty('--s', innerWidth > 480 ? Math.min(1, (innerHeight - 40) / 844) : 1); };
  scale(); addEventListener('resize', scale);
  new ResizeObserver(fit).observe(cv);

  setLang(lang); sync();
  // ?demo=1 pre-draws a stroke and opens the sheet, for screenshots
  if (params.get('demo')) { strokes = [[{x:90,y:150},{x:200,y:150}],[{x:145,y:90},{x:145,y:260}]]; fit(); sync(); renderEntry(0); openSheet(); }
})();
