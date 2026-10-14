/* SAGE ONE — System: Earnings/Wallet, Spark, Fees, Evolution, Profile, Settings */
window.SAGE = window.SAGE || {};
(function (S) {
  'use strict';
  const R = S.screens = S.screens || {};

  /* ===== EARNING SYSTEM ===== */
  let range = '7D';
  S.setEarnRange = function (v) { range = v; S.render(); };
  R.earn = {
    view: () => `
      <div class="top-nav"><button class="backbtn" style="position:static" data-act="back">${S.icon('i-arrow-l')}</button>
        <div><h2>Rewards &amp; Earnings</h2><div class="tiny muted">Verified records only</div></div></div>
      <div class="card mb12">
        <div class="row" style="gap:12px;align-items:flex-start">
          <div class="iconbox">${S.icon('i-shield')}</div>
          <div class="grow">
            <b class="small">Real cash earnings are not connected</b>
            <div class="tiny muted mt8">No payment has been received or credited by this screen. Cash earnings, bank withdrawals, and external payouts remain unavailable until a real provider and verified transaction flow are connected.</div>
          </div>
        </div>
        <button class="btn primary mt12" style="width:100%" data-act="nav" data-arg="spark">Open live Spark Wallet</button>
      </div>
      <div class="sect-label">Reward animation preview</div>
      <button class="btn primary" data-act="sim-earn" style="background:linear-gradient(135deg,#b8860b,#f5c86b);color:#1c1204">${S.icon('i-play')} Preview the 7-Stage Animation</button>
      <div class="notice">Visual preview only. This does not create a payment, grant Spark, or confirm an earning.</div>
      <div class="sect-label">Earning Animation <span class="tiny">7 stages · 0–17s</span></div>
      <div class="es-timeline">
        ${S.DATA.EARN_STAGES.map(s => `
        <div class="es-stage">
          <span class="es-n">${S.esc(s.n)}</span>
          <div class="es-body">
            <div class="es-head"><b>${S.esc(s.name)}</b><em>${S.esc(s.t)}</em></div>
            <div class="tiny muted" style="margin-top:2px">${S.esc(s.d)}</div>
            <span class="es-chip">${S.esc(s.chip)}</span>
          </div>
        </div>`).join('')}
      </div>
      <div class="sect-label">Reward tiers <span class="tiny">illustrative only</span></div>
      <div class="tier-grid">
        ${S.DATA.EARN_TIERS.map(t => `
        <div class="tier-card" style="--tc:${t.c};--tc2:${t.c2}">
          <div class="tier-name">${S.esc(t.name)}</div>
          <div class="tier-range">(${S.esc(t.range)})</div>
          <div class="tier-orb">${S.stateOrb(t.id === 'small' ? 'verifying' : t.id === 'medium' ? 'analyzing' : 'earning', 92)}</div>
          <div class="tier-amt">${S.esc(t.name)}<em>PREVIEW</em></div>
          <div class="tier-d">${S.esc(t.d)}</div>
          <div class="tier-use">${S.esc(t.use)}</div>
        </div>`).join('')}
      </div>
      <div class="notice">Reward amounts are not awarded from this preview. Verified Spark movements appear in the authenticated Spark Wallet ledger.</div>
    `
  };

  /* ===== SPARK CURRENCY SYSTEM ===== */
  R.spark = {
    view: () => `
      <div class="top-nav"><button class="backbtn" style="position:static" data-act="back">${S.icon('i-arrow-l')}</button>
        <div><h2>Spark Wallet</h2><div class="tiny muted">Backend-backed balance and ledger</div></div></div>
      <div class="balance-card" style="text-align:center">
        <svg class="spark-star" style="margin:0 auto" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l2.2 7.8L22 12l-7.8 2.2L12 22l-2.2-7.8L2 12l7.8-2.2L12 2z"/></svg>
        <div class="amount" id="sageSparkBalance">—</div>
        <div class="cur">SAGE Spark · live Core balance</div>
        <div class="row mt12" style="gap:10px">
          <button class="btn primary sm" style="flex:1" disabled title="Payment provider is not yet connected">Buy Spark · unavailable</button>
          <button class="btn soft sm" style="flex:1" disabled title="A verified transfer workflow is not yet connected">Send Spark · unavailable</button>
        </div>
      </div>
      <div class="card mt12">
        <div class="row between"><b class="small">Lifetime earned</b><b id="sageSparkEarned">—</b></div>
        <div class="row between mt8"><b class="small">Lifetime spent</b><b id="sageSparkSpent">—</b></div>
      </div>
      <div class="sect-label">Payment provider readiness</div>
      <div class="card"><div class="small" id="sagePaymentStatus">Checking SAGE Core…</div>
        <div class="tiny muted mt8">No purchase or withdrawal is available unless a real payment provider is configured and the backend enables the operation.</div></div>
      <div class="sect-label">Recent Spark ledger</div>
      <div class="card" id="sageSparkLedger"><div class="tiny muted">Loading the authenticated ledger…</div></div>
      <div class="card mt12 row" style="gap:10px"><div class="iconbox">${S.icon('i-info')}</div>
        <div class="tiny muted grow">Spark balance and ledger entries are read from SAGE Core. Spark is an internal platform credit; this screen does not promise cash value or redemption.</div></div>`,
    mount: async () => {
      const balance = document.getElementById('sageSparkBalance');
      const earned = document.getElementById('sageSparkEarned');
      const spent = document.getElementById('sageSparkSpent');
      const payment = document.getElementById('sagePaymentStatus');
      const ledger = document.getElementById('sageSparkLedger');
      if (!balance || !ledger) return;
      if (!S.backend || !S.backend.isOwnerAuthenticated()) {
        balance.textContent = 'Sign in required';
        if (payment) payment.textContent = 'Sign in with the configured SAGE owner Google account to load provider readiness.';
        ledger.textContent = 'The private Spark ledger is available after sign-in.';
        return;
      }
      balance.textContent = 'Loading…';
      ledger.textContent = 'Loading authenticated ledger…';
      try {
        const [economy, payments] = await Promise.all([
          S.backend.economyMe(),
          S.backend.paymentStatus()
        ]);
        const spark = economy.spark || {};
        balance.textContent = Number(spark.balance || 0).toLocaleString();
        if (earned) earned.textContent = Number(spark.lifetime_earned || 0).toLocaleString();
        if (spent) spent.textContent = Number(spark.lifetime_spent || 0).toLocaleString();
        if (payment) payment.textContent = payments.configured === true
          ? String(payments.message || 'Provider configured; payment actions remain disabled until the full payment flow is verified.')
          : String(payments.message || 'Payment provider is not configured.');
        const entries = Array.isArray(economy.ledger) ? economy.ledger : [];
        ledger.innerHTML = entries.length ? entries.slice(0, 20).map(entry => `
          <div class="row between" style="gap:12px;padding:9px 0;border-bottom:1px solid var(--stroke)">
            <div class="grow"><b class="small">${S.esc(String(entry.reason || 'Spark movement'))}</b>
              <div class="tiny muted">${S.esc(String(entry.created_at || ''))}</div></div>
            <div style="text-align:right"><b class="small">${Number(entry.delta || 0) > 0 ? '+' : ''}${Number(entry.delta || 0).toLocaleString()}</b>
              <div class="tiny muted">Balance ${Number(entry.balance_after || 0).toLocaleString()}</div></div>
          </div>`).join('') : '<div class="tiny muted">No Spark ledger entries yet.</div>';
      } catch (error) {
        balance.textContent = 'Unavailable';
        if (earned) earned.textContent = '—';
        if (spent) spent.textContent = '—';
        if (payment) payment.textContent = 'Could not load provider readiness: ' + String(error.message || error);
        ledger.textContent = 'Could not load the backend ledger. Refresh or sign in again.';
      }
    }
  };

  /* ===== TRANSACTION & FEES ===== */
  R.fees = {
    view: () => `
      ${S.topNav('Transaction & Fees', 'Transparent, volume-based pricing')}
      <div class="sect-label">Marketplace Fee (Buy / Sell)</div>
      <div class="card">
        <table class="fee-table">${S.DATA.FEES.market.map(f => `
          <tr><td>${f.label}</td><td>${f.pct}%</td></tr>`).join('')}</table>
      </div>
      <div class="sect-label">Transaction / Withdrawal Fee</div>
      <div class="card">
        <table class="fee-table">${S.DATA.FEES.tx.map(f => `
          <tr><td>${f.label}</td><td>${f.pct}%</td></tr>`).join('')}</table>
      </div>
      <div class="notice">Fee may change with Evolution rank — higher ranks unlock lower rates.<br>Payment methods: eSewa · Khalti · FonePay · Bank Transfer.<br>More payment options coming soon…</div>`
  };

  /* ===== EVOLUTION (core system screen) ===== */
  let evoPreviewStage = null, evoPreviewLevel = null;
  S.isEvoPreview = function () { return !!evoPreviewStage; };
  S.setEvoPreviewLevel = function (l) { evoPreviewLevel = l; S.render(); };
  S.clearEvoPreview = function () { evoPreviewStage = null; evoPreviewLevel = null; };
  R.evolution = {
    view: () => {
      const st = S.state(), e = st.evo;
      const cur = S.DATA.EVOLUTIONS[e.stage - 1];
      const ps = evoPreviewStage || e.stage, pl = evoPreviewLevel || e.level;
      const pd = S.DATA.EVOLUTIONS[ps - 1];
      const isPreview = ps !== e.stage || pl !== e.level;
      return `
      <div class="row between mb8" style="min-height:44px">
        <div><h2 class="screen-title">Evolution</h2><div class="tiny muted">Lifetime achievement · never decreases</div></div>
        <span class="pill accent">${S.icon('i-diamond')} STAGE ${cur.n}</span>
      </div>

      <!-- Emblem + levels -->
      <div class="emblem-wrap">
        ${S.emblem(ps, pl, 150)}
        <div style="text-align:center;margin-top:8px">
          <div class="tiny" style="letter-spacing:2.6px;color:var(--accent-glow);font-weight:700">STAGE ${ps} · ${S.esc(pd.name)}</div>
          <div style="font-size:19px;font-weight:800;margin-top:2px">${S.esc(pd.title)}</div>
          <div class="tiny muted">${S.esc(pd.desc)} · ${S.esc(pd.material)}</div>
        </div>
        <div class="level-row">
          ${['low', 'mid', 'high'].map(l => `
            <button class="level-btn ${pl === l ? 'active' : ''}" data-act="evo-level" data-arg="${l}"
              style="${pl === l ? `background:linear-gradient(135deg,${pd.accent},${pd.glow});box-shadow:0 0 18px var(--accent-soft)` : ''}">${l.toUpperCase()}</button>`).join('')}
        </div>
        ${isPreview ? `<div class="tiny muted mt8">Previewing · <span style="color:var(--electric-2);cursor:pointer" data-act="evo-view-current">back to current</span></div>` : ''}
      </div>

      <!-- Progress to next -->
      <div class="card mt8">
        <div class="row between mb8"><b class="small">${e.level === 'high' ? 'Next Evolution' : 'Level progress'}</b>
          <span class="tiny" style="color:var(--accent-glow)">${e.progress}%</span></div>
        <div class="bar accent"><i style="width:${Math.min(100, e.progress)}%"></i></div>
        <div class="row between mt8"><span class="tiny muted">${e.level.toUpperCase()}</span>
          <span class="tiny muted">${e.level === 'high' ? 'STAGE ' + Math.min(13, e.stage + 1) + ' LOW' : e.level === 'low' ? 'MID' : 'HIGH'}</span></div>
        <button class="btn xs ghost mt12" style="width:100%" data-act="train-evolution">${S.icon('i-bolt')} Train Evolution (+8 skill progress)</button>
      </div>

      <!-- The 13 Evolutions track -->
      <div class="sect-label">The 13 Evolutions <span class="tiny">tap to preview</span></div>
      <div class="evo-track">
        ${S.DATA.EVOLUTIONS.map(d => `
          <div class="evo-node ${d.n <= e.stage ? 'reached' : ''} ${d.n === ps ? 'current' : ''}" data-act="evo-preview" data-arg="${d.n}">
            <div class="en-circle" style="background:radial-gradient(circle at 38% 32%,${d.glow}55,${d.accent}22 60%,transparent 75%);box-shadow:0 0 12px ${d.soft}">
              <span style="font-size:22px">${evoEmoji(d.n)}</span>
            </div>
            <div><div class="en-name">${S.esc(d.name.length > 11 ? d.name.split(' ')[0] : d.name)}</div><div class="en-num">#${d.n}</div></div>
          </div>`).join('')}
      </div>

      <!-- 3-Level system -->
      <div class="sect-label">The 3-Level System <span class="tiny">intensity, not separate evolutions</span></div>
      <div class="level-diagram">
        ${['low', 'mid', 'high'].map(l => `
        <div class="level-card ${pl === l ? 'on' : ''}" data-act="evo-level" data-arg="${l}">
          <h5>${l.toUpperCase()}</h5>
          ${S.emblem(ps, l, 62)}
          <div class="tiny muted" style="margin-top:7px;line-height:1.6">${
            l === 'low' ? 'Subtle particles<br>Lower glow<br>Gentle accents'
            : l === 'mid' ? 'More particles<br>Stronger glow<br>Clearer identity'
            : 'Maximum intensity<br>Rich particles<br>Evolution-ready'}</div>
        </div>`).join('')}
      </div>
      <div class="row mt12" style="gap:6px;justify-content:center;flex-wrap:wrap">
        <span class="pill blue">Current (${e.level})</span><span style="color:var(--muted-2)">→</span>
        <span class="pill accent">Evolution Transition</span><span style="color:var(--muted-2)">→</span>
        <span class="pill blue">Next Evolution (Low)</span>
      </div>

      <!-- Play the signature transition -->
      <button class="btn primary mt16" data-act="play-transition">${S.icon('i-sparkles')} Play 9-Step Transition</button>

      <!-- The Flow -->
      <div class="sect-label">The Flow</div>
      <div class="flow-strip">
        ${S.DATA.FLOW.map((f, i) => `
          <div class="flow-step ${f.k === 'Evolution' ? 'final' : ''}">
            <div class="fs-ic">${S.icon(f.ic)}</div><span>${S.esc(f.k).replace('\n', '<br>')}</span></div>
          ${i < S.DATA.FLOW.length - 1 ? '<div class="flow-arrow">→</div>' : ''}`).join('')}
      </div>

      <!-- Core Concept -->
      <div class="sect-label">The Core Concept <span class="tiny">two paths, one journey</span></div>
      <div class="compare">
        <div class="cbox skill"><h5>${S.icon('i-book')} SKILL UPGRADE</h5>
          <div class="tiny muted mb8">Improves Evolution Visual Identity</div>
          <ul>${S.DATA.CORE.skill.map(x => `<li>${x}</li>`).join('')}</ul></div>
        <div class="cbox money"><h5>${S.icon('i-wallet')} MONEY UPGRADE</h5>
          <div class="tiny muted mb8">Improves System Progression / Capability</div>
          <ul>${S.DATA.CORE.money.map(x => `<li>${x}</li>`).join('')}</ul></div>
      </div>

      <!-- Key Rules -->
      <div class="sect-label">Key Rules</div>
      <div class="card rules"><ol style="margin-left:16px">${S.DATA.RULES.map(r => `<li>${r}</li>`).join('')}</ol></div>

      <!-- Why not full color takeover -->
      <div class="sect-label">Why Not Full Color Takeover?</div>
      <div class="not-this">
        <div class="nt-card bad"><span class="pill" style="background:rgba(224,70,70,.15);color:#ff7b7b;border:1px solid rgba(224,70,70,.35)">✗ NOT THIS</span>
          <div class="nt-swatch mt8" style="background:linear-gradient(135deg,#6b4423,#3a2412)"><div class="accentbar" style="background:#c98a4b"></div></div>
          <div class="tiny muted">Entire UI brown — kills SAGE identity</div></div>
        <div class="nt-card good"><span class="pill green">✓ THIS</span>
          <div class="nt-swatch mt8" style="background:linear-gradient(135deg,#081229,#03060f)"><div class="accentbar" style="background:linear-gradient(90deg,#c98a4b,#e0a56b)"></div></div>
          <div class="tiny muted">Accent only — keeps SAGE identity</div></div>
      </div>

      <!-- SAGE identity + accent layer -->
      <div class="sect-label">The SAGE Identity <span class="tiny">permanent</span></div>
      <div class="accents-row">${S.DATA.IDENTITY.map(c => `
        <div class="accent-dot" style="background:${c.c}" title="${c.n}"></div>`).join('')}
        <span class="tiny muted" style="align-self:center">Black · Deep Blue · Electric Blue · White · Subtle Gold</span>
      </div>
      <div class="sect-label">Evolution Material <span class="tiny">accent layer · changes per evolution</span></div>
      <div class="accents-row">${S.DATA.EVOLUTIONS.map(d => `
        <div class="accent-dot ${d.n === ps ? 'on' : ''}" style="background:linear-gradient(135deg,${d.glow},${d.accent})" title="${d.name}" data-act="evo-preview" data-arg="${d.n}"></div>`).join('')}
      </div>

      <!-- Design principles -->
      <div class="sect-label">Design Principles</div>
      <div class="card rules"><ol style="margin-left:16px">${S.DATA.PRINCIPLES.map(p => `<li>${p}</li>`).join('')}</ol></div>`;
    }
  };

  function evoEmoji(n) {
    return ['🥉', '🥈', '🥇', '💠', '🟢', '🔴', '🔵', '🟩', '💎', '🪨', '🟠', '🌌', '⚛️'][n - 1];
  }

  S.evoPreview = function (n) {
    evoPreviewStage = n;
    evoPreviewLevel = n === S.evo().stage ? S.evo().level : 'low';
    S.render();
  };

  /* ===== PROFILE ===== */
  R.profile = {
    view: () => {
      const st = S.state(), u = st.user, e = st.evo, d = S.DATA.EVOLUTIONS[e.stage - 1];
      return `
      <div class="row between mb12" style="min-height:44px">
        <div><h2 class="screen-title">Profile</h2><div class="tiny muted">Your SAGE identity</div></div>
        <div class="iconbox" data-act="nav" data-arg="settings">${S.icon('i-gear')}</div>
      </div>
      <div class="card glow" style="text-align:center;padding:20px">
        <div style="width:76px;height:76px;border-radius:50%;margin:0 auto 12px;background:var(--grad-btn);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:800;box-shadow:var(--glow)">
          ${u.avatar || (u.name ? S.esc(u.name[0].toUpperCase()) : 'S')}</div>
        <div style="font-size:17px;font-weight:700">${S.esc(u.name || 'SAGE User')}</div>
        <div class="tiny muted" style="margin-top:2px">${S.esc(u.location || 'Kathmandu, Nepal')}</div>
        <div class="row mt8" style="gap:6px;justify-content:center">
          <span class="pill accent">${S.icon('i-diamond')} ${S.esc(d.name)}</span>
          <span class="pill blue">EXPLORER</span>
          <span class="pill gold">KYC NOT CONNECTED</span>
        </div>
        <div class="row mt12" style="gap:10px">
          <button class="btn sm soft" style="flex:1" data-act="nav" data-arg="spark">Open Spark Wallet</button>
          <button class="btn sm soft" style="flex:1" disabled title="Real-world earnings are not connected">Earnings unavailable</button>
        </div>
      </div>
      <div class="sect-label">Account</div>
      <div class="set-group">
        <div class="set-item" data-act="nav" data-arg="kyc"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-shield')}</div>
          <div class="grow"><b class="small">Identity Verification</b><div class="sv">Formal KYC provider is not connected</div></div>${S.icon('i-arrow-r')}</div>
        <div class="set-item" data-act="nav" data-arg="settings"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-globe')}</div>
          <div class="grow"><b class="small">Language</b><div class="sv">${st.lang === 'ne' ? 'नेपाली' : 'English'}</div></div>${S.icon('i-arrow-r')}</div>
        <div class="set-item" data-act="nav" data-arg="settings"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-moon')}</div>
          <div class="grow"><b class="small">Theme</b><div class="sv">${st.theme === 'blue' ? 'Blue Theme' : st.theme === 'light' ? 'Light' : 'Dark (Default)'}</div></div>${S.icon('i-arrow-r')}</div>
      </div>
      <div class="sect-label">Journey</div>
      <div class="set-group">
        <div class="set-item" data-act="nav" data-arg="evolution"><div class="iconbox accent" style="width:34px;height:34px">${S.icon('i-diamond')}</div>
          <div class="grow"><b class="small">Evolution Track</b><div class="sv">Stage ${e.stage} / 13 · ${e.level.toUpperCase()}</div></div>${S.icon('i-arrow-r')}</div>
        <div class="set-item" data-act="nav" data-arg="fees"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-bank')}</div>
          <div class="grow"><b class="small">Transaction &amp; Fees</b><div class="sv">Marketplace &amp; withdrawal rates</div></div>${S.icon('i-arrow-r')}</div>
        <div class="set-item" data-act="nav" data-arg="files"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-folder')}</div>
          <div class="grow"><b class="small">My Files</b><div class="sv">${S.DATA.FILES.length + st.ownedFiles.length} items</div></div>${S.icon('i-arrow-r')}</div>
      </div>
      <div class="card mt12" style="text-align:center">
        <div class="tiny muted">🇳🇵 NEPAL · SAGE · FOREVER</div>
        <div style="font-size:12px;margin-top:6px;font-weight:600">More Than An App — It's Your Future Partner</div>
      </div>
      <button class="btn soft mt12" data-act="reset-app">${S.icon('i-refresh')} Reset App Data</button>`;
    }
  };

  /* ===== SETTINGS & THEMES ===== */
  R.settings = {
    view: () => {
      const st = S.state();
      const themes = [
        { id: 'dark', name: 'Dark (Default)', prev: 'linear-gradient(160deg,#0b1734,#050b1c)', dot: '#4fa8ff' },
        { id: 'light', name: 'Light', prev: 'linear-gradient(160deg,#f4f8ff,#dbe7fb)', dot: '#1b5cff' },
        { id: 'blue', name: 'Blue Theme', prev: 'linear-gradient(160deg,#0a2a66,#04102e)', dot: '#6fb6ff' }
      ];
      return `
      ${S.topNav('Settings & Themes', 'Personalize your SAGE')}
      <div class="sect-label">Dark Mode &amp; Themes</div>
      <div class="theme-cards">
        ${themes.map(t => `
        <div class="theme-card ${st.theme === t.id ? 'on' : ''}" data-act="theme" data-arg="${t.id}">
          <div class="tprev" style="background:${t.prev}">
            <div style="position:absolute;top:8px;left:8px;width:18px;height:18px;border-radius:5px;background:${t.dot};box-shadow:0 0 10px ${t.dot}"></div>
            <div style="position:absolute;bottom:8px;left:8px;right:8px;height:5px;border-radius:3px;background:${t.id === 'light' ? 'rgba(27,92,255,.25)' : 'rgba(120,190,255,.3)'}"></div>
            <div style="position:absolute;bottom:17px;left:8px;width:34px;height:5px;border-radius:3px;background:${t.id === 'light' ? 'rgba(27,92,255,.4)' : 'rgba(120,190,255,.5)'}"></div>
          </div><span>${t.name}</span>
        </div>`).join('')}
      </div>
      <div class="tiny muted mt8">Theme changes the surface only — the SAGE blue + black identity and your evolution accent always survive.</div>

      <div class="sect-label">Language · भाषा</div>
      <div class="set-group">
        <div class="set-item" data-act="lang" data-arg="ne"><div class="iconbox" style="width:34px;height:34px">🇳🇵</div>
          <div class="grow"><b class="small">नेपाली</b><div class="sv">Nepali</div></div>${st.lang === 'ne' ? S.icon('i-check') : ''}</div>
        <div class="set-item" data-act="lang" data-arg="en"><div class="iconbox" style="width:34px;height:34px">🇬🇧</div>
          <div class="grow"><b class="small">English</b><div class="sv">Global</div></div>${st.lang === 'en' ? S.icon('i-check') : ''}</div>
      </div>

      <div class="sect-label">Account</div>
      <div class="set-group">
        <div class="set-item" data-act="nav" data-arg="kyc"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-shield')}</div>
          <div class="grow"><b class="small">Security &amp; KYC</b><div class="sv">Face + NID verification</div></div>${S.icon('i-arrow-r')}</div>
        <div class="set-item" data-act="nav" data-arg="fees"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-bank')}</div>
          <div class="grow"><b class="small">Payments &amp; Fees</b><div class="sv">eSewa · Khalti · FonePay · Bank</div></div>${S.icon('i-arrow-r')}</div>
      </div>

      <div class="set-group">
        <div class="set-item" data-act="nav" data-arg="aisettings"><div class="iconbox" style="width:34px;height:34px">${S.icon('i-sparkles')}</div>
          <div class="grow"><b class="small">AI Engine</b><div class="sv">${S.AI.isLive() ? 'Live model · key connected' : 'Built-in answer engine'}</div></div>${S.icon('i-arrow-r')}</div>
        <div class="set-item" data-act="reset-app"><div class="iconbox" style="width:34px;height:34px;color:#ff7b7b">${S.icon('i-trash')}</div>
          <div class="grow"><b class="small">Reset App Data</b><div class="sv">Clear local state &amp; restart onboarding</div></div></div>
      </div>
      <div class="notice">SAGE ONE v1.0 · Built in Nepal 🇳🇵<br>More Than An App — It's Your Future Partner</div>`;
    }
  };

  /* ===== AI ENGINE (built-in default + user supplied key) ===== */
  R.aisettings = {
    view: () => {
      const signedIn = !!(S.backend && S.backend.isOwnerAuthenticated && S.backend.isOwnerAuthenticated());
      return `
      ${S.topNav('AI Engine', 'SAGE Core manages provider access')}
      <div class="sect-label">Secure AI connection</div>
      <div class="card">
        <div class="row" style="gap:12px;align-items:flex-start">
          <div class="iconbox accent">${S.icon('i-sparkles')}</div>
          <div class="grow">
            <b>AI runs through SAGE Core</b>
            <p class="small muted mt8">Provider keys and paid-service configuration belong on the backend. This website will not ask you to paste a secret API key into your browser or save one in local storage.</p>
          </div>
        </div>
        <div class="set-item"><div class="grow"><b class="small">Owner session</b><div class="sv">${signedIn ? 'Signed in for this tab' : 'Sign in required'}</div></div></div>
        <div class="set-item"><div class="grow"><b class="small">Provider routing</b><div class="sv">Managed by SAGE Core server configuration</div></div></div>
        <button class="btn primary mt12" data-act="ai-test" style="width:100%">Check Core configuration</button>
        <div class="notice mt12">A successful configuration check does not prove an AI provider is enabled or that research/media generation is working. SAGE will show those capabilities only after real integration tests.</div>
      </div>
      <div class="sect-label">Current live capability</div>
      <div class="card">
        <div class="row"><span class="small">Owner sign-in</span><b class="small">${signedIn ? 'Active in this tab' : 'Not signed in'}</b></div>
        <div class="row mt8"><span class="small">Core chat</span><b class="small">${signedIn ? 'Available to test' : 'Sign in first'}</b></div>
        <div class="row mt8"><span class="small">Research / image / video</span><b class="small">Integration pending</b></div>
      </div>`;
    }
  };


})(window.SAGE);
