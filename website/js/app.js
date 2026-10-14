/* SAGE ONE — App controller: router, tabbar, action dispatcher */
window.SAGE = window.SAGE || {};
(function (S) {
  'use strict';

  const TAB_ROUTES = { home: 'home', research: 'research', wallet: 'wallet', profile: 'profile', earn: 'wallet', spark: 'wallet' };
  let current = { name: 'splash', param: null };
  let history = [];

  /* ===== desktop / phone mode (board 2) ===== */
  let modeOverride = null;
  S.deskPreferred = function () {
    try { if (!S.state().onboarded) return false; } catch (e) { return false; }
    if (modeOverride !== null) return modeOverride;
    return window.matchMedia('(min-width: 1180px)').matches;
  };
  S.isDesktop = function () { return document.body.classList.contains('on-desk'); };
  S.toggleMode = function () {
    modeOverride = !S.deskPreferred();
    S.render();
    S.toast(modeOverride ? '🖥 Desktop dashboard' : '📱 Phone experience');
  };
  function applyMode() {
    const desk = S.deskPreferred();
    document.body.classList.toggle('on-desk', desk);
    const t = S.$('#viewToggle');
    if (t) t.textContent = desk ? '📱 Phone view' : '🖥 Desktop view';
    const d = S.$('#desk');
    if (d) d.setAttribute('aria-hidden', desk ? 'false' : 'true');
    return desk;
  }
  function deskIconChrome() {
    const s1 = S.$('.dt-sic'), b1 = S.$('#dtBell1'), b2 = S.$('#dtBell2');
    if (s1) s1.innerHTML = S.icon('i-search');
    if (b1) b1.innerHTML = S.icon('i-bell');
    if (b2) b2.innerHTML = S.icon('i-bell');
    const orb = S.$('#dtOrb');
    if (orb) orb.innerHTML = S.logo(30, { spin: false });
    const dl = S.$('#dsLogo');
    if (dl) dl.innerHTML = S.logo(34);
  }
  function renderSidebar() {
    const st = S.state();
    const nav = S.$('#dsNav');
    if (nav) nav.innerHTML = S.DATA.DESK_NAV.map(n => `
      <button class="ds-item ${current.name === n.id ? 'on' : ''}" data-act="nav" data-arg="${n.id}">
        ${S.icon(n.ic)}<span>${n.name}</span></button>`).join('');
    const cr = S.$('#dsCredits'), ts = S.$('#dtSpark');
    // Never display the local prototype balance as real money or backend-confirmed Spark.
    if (cr) cr.textContent = '—';
    if (ts) ts.textContent = '—';
    const nm = S.$('#dsName'), av = S.$('#dsAva');
    if (nm) nm.textContent = st.user.name || 'SAGE User';
    if (av) av.textContent = st.user.avatar || (st.user.name ? st.user.name[0].toUpperCase() : 'S');
    deskIconChrome();
  }
  function renderRail() {
    const rail = S.$('#deskRight');
    if (!rail) return;
    if (current.name !== 'home') { rail.innerHTML = ''; return; }
    rail.innerHTML = `
      <div class="rail-card">
        <div class="rail-head">Explore</div>
        <div class="la-row" data-act="nav" data-arg="research">
          <span class="iconbox" style="width:32px;height:32px">${S.icon('i-search')}</span>
          <div class="grow"><b class="small">Open Research</b><div class="tiny muted">Start a research session</div></div>
          ${S.icon('i-arrow-r')}
        </div>
      </div>
      <div class="rail-card">
        <div class="rail-head">Your activity</div>
        <div class="la-row" data-act="nav" data-arg="history">
          <span class="iconbox" style="width:32px;height:32px">${S.icon('i-clock')}</span>
          <div class="grow"><b class="small">Chat History</b><div class="tiny muted">Open or archive saved conversations</div></div>
          ${S.icon('i-arrow-r')}
        </div>
        <div class="la-row" data-act="nav" data-arg="activity">
          <span class="iconbox" style="width:32px;height:32px">${S.icon('i-bell')}</span>
          <div class="grow"><b class="small">Activity Center</b><div class="tiny muted">Tasks and notifications</div></div>
          ${S.icon('i-arrow-r')}
        </div>
      </div>
      <div class="rail-foot">More than an AI.<br><b>It's your edge.</b></div>`;
  }

  /* ===== navigation ===== */
  S.go = function (name, param, opts) {
    if (!S.screens[name]) name = 'home';
    if (current.name !== name || current.param !== param) {
      if (!(opts && opts.replace)) history.push(current);
      if (history.length > 40) history.shift();
    }
    current = { name, param };
    S.render();
  };
  S.back = function () {
    const prev = history.pop();
    current = prev && S.screens[prev.name] ? prev : { name: 'home', param: null };
    S.render();
  };
  S.currentRoute = function () { return current.name; };

  /* ===== render ===== */
  S.render = function (keepScroll) {
    const def = S.screens[current.name] || S.screens.home;
    const desk = applyMode();
    const target = desk ? S.$('#deskContent') : S.$('#screen');
    const other = desk ? S.$('#screen') : S.$('#deskContent');
    if (other) other.innerHTML = '';
    const oldView = target ? S.$('.view', target) : null;
    const scroll = keepScroll && oldView ? oldView.scrollTop : 0;

    document.body.classList.toggle('desk-home', desk && current.name === 'home');
    const html = `<div class="view ${def.nonav ? 'nonav' : ''} ${def.flush ? 'flush' : ''} ${def.chat ? 'chatview' : ''} ${def.back ? 'has-back' : ''}">${def.view(current.param)}</div>`;
    if (target) target.innerHTML = html;
    if (desk) { renderSidebar(); renderRail(); }
    else renderTabbar(def);
    S.applyTheme();
    if (keepScroll) { const v = target && S.$('.view', target); if (v) v.scrollTop = scroll; }
    if (def.mount) def.mount(current.param);
  };

  function renderTabbar(def) {
    const bar = S.$('#tabbar');
    if (def.nonav) { bar.classList.add('hidden'); bar.innerHTML = ''; return; }
    bar.classList.remove('hidden');
    const act = TAB_ROUTES[current.name] || '';
    const ic = (n) => S.icon(n);
    bar.innerHTML = `
      <button class="tab ${act === 'home' ? 'active' : ''}" data-act="tab" data-arg="home">${ic('i-home')}<span>${S.t('nav.home')}</span></button>
      <button class="tab ${act === 'research' ? 'active' : ''}" data-act="tab" data-arg="research">${ic('i-search')}<span>Research</span></button>
      <button class="tab center ${current.name === 'chat' ? 'active' : ''}" data-act="chat"><div class="orb">${ic('i-chat')}</div></button>
      <button class="tab ${act === 'wallet' ? 'active' : ''}" data-act="tab" data-arg="wallet">${ic('i-wallet')}<span>Wallet</span></button>
      <button class="tab ${act === 'profile' ? 'active' : ''}" data-act="tab" data-arg="profile">${ic('i-user')}<span>Profile</span></button>`;
  }

  /* ===== level-up: plays the signature 9-step transition ===== */
  S.handleLevelUp = function (leveled) {
    if (!leveled) return;
    const order = ['low', 'mid', 'high'];
    const from = leveled.newRank
      ? { stage: leveled.stage - 1, level: 'high' }
      : { stage: leveled.stage, level: order[Math.max(0, order.indexOf(leveled.level) - 1)] };
    setTimeout(() => {
      S.playTransition(from.stage, from.level, leveled.stage, leveled.level, () => {
        S.toast(leveled.newRank
          ? '🏆 New rank: ' + S.DATA.EVOLUTIONS[leveled.stage - 1].name + '!'
          : 'Level up: ' + leveled.level.toUpperCase() + ' intensity unlocked');
        if (S.clearEvoPreview) S.clearEvoPreview();
        S.render();
      });
    }, 550);
  };

  /* ===== action dispatcher ===== */
  S.act = function (name, arg) {
    const st = S.state();
    switch (name) {

      /* --- nav --- */
      case 'nav': S.go(arg); break;
      case 'back': S.back(); break;
      case 'tab': history = []; S.go(arg, null, { replace: true }); break;
      case 'chat': S.go('chat'); break;
      case 'noop': break;
      case 'toast': S.toast(arg); break;
      case 'close-sheet': S.closeSheet(); break;
      case 'skip-fx': if (S._fxSkip) S._fxSkip(); break;
      case 'toggle-mode': S.toggleMode(); break;

      /* --- agent workspace (board 5-8: control, marketplace, workflow, integrations) --- */
      case 'ag': S.AG_ACT(arg); break;

      /* --- home ask bar --- */
      case 'home-ask': {
        const inp = S.$('#homeAsk');
        const v = inp && inp.value.trim();
        S.go('chat');
        if (v) setTimeout(() => S.sendChat(v), 150);
        break;
      }

      /* --- research lab (board 4) --- */
      case 'rs-start': S.rsStop(); S.rsJump(0); S.go('research'); setTimeout(() => S.rsPlay(), 80); break;
      case 'rs-analyze': S.rsStop(); S.rsJump(2); S.go('research'); break;
      case 'rs-set': S.rsStop(); S.rsSet(+arg); break;
      case 'rs-play': S.rsPlay(); break;
      case 'rs-fail': {
        S.closeSheet();
        if (S.currentRoute() !== 'research') S.go('research');
        S.playFailure({ preview: true });
        break;
      }
      case 'fail-retry': {
        S.toast('Live research is not connected yet. No retry request was sent.');
        break;
      }
      case 'logo-preview': S.previewState(arg); break;
      case 'src-detail': S.srcDetail(arg); break;
      case 'src-tab': S.srcTab(arg); break;
      case 'src-all': S.toast('Live source verification is not connected. No source counts are being claimed.'); break;

      /* --- earning animation (board 3) --- */
      case 'sim-earn': S.closeSheet(); S.playEarning(5000, { source: 'Animation Preview', preview: true, noCredit: true }); break;
      case 'earn-tier': S.toast('Real earnings are not connected. This preview will not credit Spark or cash.'); break;

      /* --- premium (not connected) --- */
      case 'premium-upgrade':
      case 'premium-confirm':
      case 'premium-cancel':
        S.closeSheet();
        S.toast('Premium billing is not connected. No subscription was started or changed.');
        break;

      /* --- onboarding: real identity provider required --- */
      case 'auth-continue':
      case 'auth-google':
        S.toast('Use the secure Google sign-in connected to SAGE Core. Local/demo account creation is disabled.');
        S.go('auth');
        break;
      case 'kyc-start':
      case 'kyc-done':
        S.toast('KYC provider is not configured. Identity has not been verified and access was not unlocked.');
        break;
      case 'pick-avatar': {
        const avatars = ['🧘', '🦅', '🏔️', '🦁', '🐺', '🪔'];
        st.user.avatar = avatars[Math.floor(Math.random() * avatars.length)];
        S.save(); S.render(); S.toast('Profile photo added'); break;
      }
      case 'profile-save': {
        const n = ((S.$('#pc-name') || {}).value || '').trim();
        const l = ((S.$('#pc-loc') || {}).value || '').trim();
        const p = ((S.$('#pc-phone') || {}).value || '').trim();
        if (n) st.user.name = n;
        if (l) st.user.location = l;
        if (p) st.user.phone = p;
        if (!st.user.avatar) st.user.avatar = (st.user.name || 'S')[0].toUpperCase();
        S.save(); S.go('welcome-go'); break;
      }
      case 'finish-onboard':
        st.onboarded = true; S.save(); S.go('home'); S.toast('Welcome to SAGE ONE 🙏'); break;

      /* --- chat --- */
      case 'chat-send': {
        const inp = S.$('#chatInput');
        if (inp && inp.value.trim()) { const v = inp.value; inp.value = ''; S.sendChat(v); }
        break;
      }
      case 'chat-quick': S.sendChat(arg); break;
      case 'chat-action': S.chatAction(arg); break;

      /* --- marketplace --- */
      case 'mkt-cat': S.setMktCat(arg); break;
      case 'listing': S.go('listing-detail', arg); break;
      case 'buy-listing':
      case 'buy-confirm':
        S.closeSheet();
        S.toast('Marketplace checkout is not connected. No purchase or Spark movement occurred.');
        break;
      case 'sell-submit':
        S.closeSheet();
        S.toast('Marketplace publishing is not connected. No listing was published and no earnings were credited.');
        break;

      /* --- jobs --- */
      case 'job-filter': S.setJobFilter(arg); break;
      case 'apply-job':
        S.toast('Job application delivery is not connected. No application was sent.');
        break;

      /* --- learning --- */
      case 'learn-tab': S.setLearnTab(arg); break;
      case 'course': S.go('course-detail', arg); break;
      case 'enroll':
      case 'course-complete':
        S.toast('Course enrollment and completion tracking are not connected to a learning provider. No progress reward was granted.');
        break;

      /* --- community --- */
      case 'comm-tab': S.setCommTab(arg); break;
      case 'files-tab': S.setFilesTab(arg); break;
      case 'chat-new':
        if (S.backend && S.backend.startNewChat) S.backend.startNewChat();
        else { S.state().chatSessionId = null; S.state().chat = []; S.save(); S.go('chat'); }
        break;
      case 'history-filter': S.setHistoryFilter(arg); break;
      case 'history-open':
        if (S.backend && S.backend.loadSession) {
          S.backend.loadSession(arg).catch(error => S.toast('Could not open conversation: ' + String(error.message || error)));
        } else S.toast('Chat history is not connected to SAGE Core.');
        break;
      case 'history-archive':
        if (S.backend && S.backend.archiveSession) {
          S.backend.archiveSession(arg).then(() => { S.toast('Conversation archived'); S.go('history'); })
            .catch(error => S.toast('Could not archive conversation: ' + String(error.message || error)));
        }
        break;
      case 'history-restore':
        if (S.backend && S.backend.restoreSession) {
          S.backend.restoreSession(arg).then(() => { S.toast('Conversation restored'); S.go('history'); })
            .catch(error => S.toast('Could not restore conversation: ' + String(error.message || error)));
        }
        break;
      case 'history-refresh':
      case 'activity-refresh':
        S.render();
        break;
      case 'activity-read':
        if (S.backend && S.backend.markNotificationRead) {
          S.backend.markNotificationRead(arg).then(() => S.render())
            .catch(error => S.toast('Could not mark notification read: ' + String(error.message || error)));
        }
        break;

      /* --- AI studio --- */
      case 'ai-tool': {
        if (arg === 'image') S.go('ai-image');
        else if (arg === 'video') S.go('ai-video');
        else S.toast('Code Generation — coming soon ⏳');
        break;
      }
      case 'gen-image': {
        if (st.spark < 5) { S.toast('Not enough Spark — buy more first'); S.go('spark'); break; }
        const prompt = ((S.$('#gen-prompt') || {}).value || '').trim();
        S.addSpark(-5, 'Image generated');
        S.drawGenerated(prompt);
        st.ownedFiles.push({ name: 'AI_Image_' + (st.ownedFiles.length + 1) + '.png', size: '2.1 MB', when: 'Just now' });
        S.save();
        S.toast('Image generated · −5 Spark');
        const lvl = S.addProgress(4, 'AI image created');
        if (lvl) S.handleLevelUp(lvl);
        break;
      }
      case 'gen-video': {
        const secs = S.$('#vlen') ? +S.$('#vlen').value : 8;
        const cost = 25 + Math.max(0, secs - 4) * 2;
        if (st.spark < cost) { S.toast('Not enough Spark — need ' + cost); S.go('spark'); break; }
        S.addSpark(-cost, 'Video rendered');
        st.ownedFiles.push({ name: 'AI_Video_' + secs + 's.mp4', size: (secs * 1.4).toFixed(1) + ' MB', when: 'Just now' });
        st.earnings.content += 15; st.lifetimeEarned += 15; S.save();
        S.toast('Video rendered ✓ −' + cost + ' Spark · +NPR 15 content reward');
        const lvl = S.addProgress(8, 'AI video rendered');
        if (lvl) S.handleLevelUp(lvl);
        S.go('files');
        break;
      }

      /* --- spark & money --- */
      case 'pay-method':
        st.payMethod = arg; S.save(); S.render();
        S.toast(S.DATA.PAYMENTS.find(p => p.id === arg).name + ' selected'); break;
      case 'buy-spark': {
        const pm = S.DATA.PAYMENTS.find(p => p.id === st.payMethod);
        S.sheet(`
          <h3>Buy Spark</h3>
          <div class="sub">1 Spark = NPR 1 · KYC verified &amp; secure</div>
          <div class="grid2" style="margin-bottom:12px">
            ${[100, 500, 1250, 5000].map(v => `
            <button class="btn soft" data-act="buy-spark-amount" data-arg="${v}" style="flex-direction:column;gap:2px;padding:12px">
              <b>${S.fmtSpark(v)}</b><span class="tiny muted">Spark · ${S.npr(v)}</span></button>`).join('')}
          </div>
          <div class="field"><label>Custom amount</label><input class="input" id="spark-custom" inputmode="numeric" placeholder="e.g. 2500"></div>
          <button class="btn primary mt8" data-act="buy-spark-custom">${S.icon('i-bolt')} Purchase with ${pm.name}</button>
          <div class="notice">Payment flow: Choose ${pm.name} → Secure payment (KYC verified) → Instant Spark credited</div>`);
        break;
      }
      case 'buy-spark-amount': S.addSpark(+arg, 'Purchased'); S.closeSheet(); S.render(); break;
      case 'buy-spark-custom': {
        const v = parseInt(((S.$('#spark-custom') || {}).value || '').replace(/\D/g, ''), 10);
        if (!v) { S.toast('Enter an amount'); break; }
        S.addSpark(v, 'Purchased'); S.closeSheet(); S.render(); break;
      }
      case 'send-spark': {
        S.sheet(`
          <h3>Send Spark</h3>
          <div class="sub">Instant transfer to any SAGE user · balance ${S.fmtSpark(st.spark)}</div>
          <div class="field"><label>Recipient (phone or SAGE ID)</label><input class="input" placeholder="+977 98XXXXXXXX"></div>
          <div class="field"><label>Amount</label><input class="input" id="send-amt" inputmode="numeric" placeholder="e.g. 250"></div>
          <button class="btn primary mt8" data-act="send-spark-go">${S.icon('i-share')} Send Spark</button>`);
        break;
      }
      case 'send-spark-go': {
        const v = parseInt(((S.$('#send-amt') || {}).value || '').replace(/\D/g, ''), 10);
        if (!v || v > st.spark) { S.toast('Check the amount (balance ' + S.fmtSpark(st.spark) + ')'); break; }
        S.addSpark(-v, 'Sent'); S.closeSheet(); S.render();
        const lvl = S.addProgress(2, 'Sent Spark to a peer');
        if (lvl) S.handleLevelUp(lvl);
        break;
      }

      /* --- earn & withdraw --- */
      case 'earn-range': S.setEarnRange(arg); break;
      case 'withdraw': {
        S.sheet(`
          <h3>Withdraw to Bank</h3>
          <div class="sub">Only through approved &amp; regulated partners</div>
          <div class="field"><label>Amount (NPR)</label><input class="input" id="wd-amt" inputmode="numeric" placeholder="e.g. 5000"></div>
          <div class="fee-box" style="margin-bottom:12px">
            <div class="row between small"><span class="muted">Withdrawal fee</span><b id="wd-fee">—</b></div>
            <div class="tiny muted mt8">Evolution is lifetime achievement — withdrawal never reduces it.</div>
          </div>
          <button class="btn primary" data-act="withdraw-go">${S.icon('i-bank')} Confirm Withdrawal</button>`);
        const inp = S.$('#wd-amt');
        if (inp) inp.addEventListener('input', () => {
          const v = parseInt(inp.value.replace(/\D/g, ''), 10) || 0;
          S.$('#wd-fee').textContent = v ? S.npr(Math.round(v * S.txFeePct(v) / 100)) + ' (' + S.txFeePct(v) + '%)' : '—';
        });
        break;
      }
      case 'withdraw-go': {
        const v = parseInt(((S.$('#wd-amt') || {}).value || '').replace(/\D/g, ''), 10);
        if (!v) { S.toast('Enter an amount'); break; }
        S.closeSheet();
        S.toast('Withdrawal of ' + S.npr(v) + ' initiated ✓ (fee ' + S.txFeePct(v) + '%)');
        const lvl = S.addProgress(3, 'Funds withdrawn');
        if (lvl) S.handleLevelUp(lvl);
        break;
      }

      /* --- evolution --- */
      case 'evo-preview': S.evoPreview(+arg); break;
      case 'evo-view-current': S.clearEvoPreview(); S.render(); break;
      case 'evo-level': {
        if (S.isEvoPreview()) { S.setEvoPreviewLevel(arg); break; }
        const order = ['low', 'mid', 'high'];
        const e = st.evo;
        if (order.indexOf(arg) <= order.indexOf(e.level)) { e.level = arg; S.save(); S.render(); }
        else S.toast('Reach ' + arg.toUpperCase() + ' by training your Evolution');
        break;
      }
      case 'train-evolution': {
        const lvl = S.addProgress(8, 'Skill training session');
        if (lvl) S.handleLevelUp(lvl); else S.render();
        break;
      }
      case 'play-transition': {
        const e = st.evo;
        const nextStage = e.level === 'high' ? Math.min(13, e.stage + 1) : e.stage;
        const nextLevel = e.level === 'low' ? 'mid' : e.level === 'mid' ? 'high' : 'low';
        S.playTransition(e.stage, e.level, nextStage, nextLevel, () => {
          if (S.clearEvoPreview) S.clearEvoPreview();
          S.render();
        });
        break;
      }

      /* --- AI engine --- */
      case 'ai-mode': {
        S.AI.setCfg({ mode: arg });
        S.render();
        S.toast('AI providers are managed by SAGE Core. Browser API-key mode is disabled.');
        break;
      }
      case 'ai-provider': {
        const isGem = arg === 'gemini';
        S.AI.setCfg({
          provider: arg,
          model: isGem ? 'gemini-1.5-flash' : 'gpt-4o-mini',
          base: isGem ? '' : 'https://api.openai.com/v1'
        });
        S.render();
        break;
      }
      case 'ai-save': {
        const k = ((S.$('#aiKey') || {}).value || '').trim();
        const mdl = ((S.$('#aiModel') || {}).value || '').trim();
        const b = ((S.$('#aiBase') || {}).value || '').trim();
        S.AI.setCfg({ key: k, model: mdl || undefined, base: b || undefined });
        S.render();
        S.toast('Browser API keys are disabled. Configure providers on the SAGE Core server instead.');
        break;
      }
      case 'ai-test': {
        if (!S.backend || !S.backend.checkConfig) { S.toast('SAGE Core connection is not ready.'); break; }
        S.toast('Testing connection…');
        S.backend.checkConfig()
          .then(c => S.toast(c.googleConfigured ? 'Core identity configuration loaded. AI provider health is not yet exposed.' : 'Core responded, but Google sign-in is not configured.'))
          .catch(e => S.toast('Core configuration check failed: ' + (e && e.message ? e.message : 'connection failed')));
        break;
      }

      /* --- settings --- */
      case 'theme': {
        S.setTheme(arg); S.render();
        S.toast((arg === 'dark' ? 'Dark (Default)' : arg === 'light' ? 'Light' : 'Blue Theme') + ' applied · SAGE identity preserved');
        break;
      }
      case 'reset-app': {
        S.sheet(`
          <h3>Reset App Data?</h3>
          <div class="sub">This clears your local SAGE state and restarts onboarding.</div>
          <button class="btn primary" data-act="reset-confirm">Yes, reset everything</button>
          <button class="btn soft mt8" data-act="close-sheet">Cancel</button>`);
        break;
      }
      case 'reset-confirm':
        S.reset(); S.closeSheet(); S.applyTheme(); history = []; S.go('splash', null, { replace: true }); break;

      default:
        /* agent-workspace actions are handled by S.AG_ACT (mission control,
           marketplace, workflow builder, integrations). The buttons emit a bare
           data-act (e.g. "ig-test", "agent-hire", "wf-run") that this switch
           doesn't own, so forward anything AG_ACT recognizes instead of dropping it. */
        if (S.AG_ACT && S.AG_ACT_KNOWN && S.AG_ACT_KNOWN.indexOf(name) !== -1) { S.AG_ACT(name + (arg != null && arg !== '' ? ':' + arg : '')); break; }
        break;
    }
  };

  /* ===== delegated events ===== */
  document.addEventListener('click', (e) => {
    const el = e.target.closest('[data-act]');
    if (!el) return;
    e.preventDefault();
    S.act(el.getAttribute('data-act'), el.getAttribute('data-arg'));
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && e.target && e.target.id === 'chatInput') S.act('chat-send');
  });

  /* ===== boot ===== */
  window.addEventListener('DOMContentLoaded', () => {
    S.load();
    S.applyTheme();
    const bl = S.$('#brandLogo');
    if (bl) bl.innerHTML = S.logo(56);
    S.initStars();
    S.go(S.state().onboarded ? 'home' : 'splash', null, { replace: true });
    /* auto-switch desktop ↔ phone when the viewport crosses the breakpoint */
    let lastDesk = S.isDesktop();
    let rt = null;
    window.addEventListener('resize', () => {
      clearTimeout(rt);
      rt = setTimeout(() => {
        const desk = S.deskPreferred();
        if (desk !== lastDesk) { lastDesk = desk; S.render(); }
      }, 150);
    });
  });

})(window.SAGE);
