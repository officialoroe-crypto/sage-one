/* SAGE ONE — Onboarding screens: splash, welcome, language, auth, KYC, profile, let's-go */
window.SAGE = window.SAGE || {};
(function (S) {
  'use strict';
  const R = S.screens = S.screens || {};

  /* ===== 1. Splash & Onboarding ===== */
  R.splash = {
    nonav: true,
    view: () => `
      <div class="splash">
        <div class="big-logo">${S.logo(150)}</div>
        <h1>SAGE<span>ONE</span></h1>
        <div class="tag">Your Personal AI Mentor &amp; Execution Partner</div>
        <div class="quote" lang="ne">“सपना होइन, लक्ष्य बनाऔं।<br>लक्ष्य होइन, कार्य बनाऔं।<br>कार्य होइन, वास्तविकता बनाऔं।”</div>
        <div class="loadbar"><i></i></div>
      </div>`,
    mount() {
      setTimeout(() => {
        S.go(S.state().onboarded ? 'home' : 'welcome');
      }, 2350);
    }
  };

  /* ===== Welcome ===== */
  R.welcome = {
    nonav: true,
    view: () => `
      <div class="hero-art">
        <div class="h-stars"></div>
        <div class="h-moon"></div>
        <div class="h-peak"></div>
        <div class="h-logo">${S.logo(110)}</div>
      </div>
      <h2 class="screen-title" style="text-align:center">${S.t('onb.welcome')}</h2>
      <p class="screen-sub" style="text-align:center;margin:8px auto 22px;max-width:280px;line-height:1.7">${S.t('onb.mentor')}</p>
      <button class="btn primary" data-act="nav" data-arg="language">${S.t('onb.getstarted')}</button>
      <div class="linkline">${S.t('onb.haveacc')} <b data-act="nav" data-arg="auth">Sign In</b></div>
      <div class="notice">🇳🇵 NEPAL · SAGE · FOREVER</div>`
  };

  /* ===== Language ===== */
  R.language = {
    nonav: true,
    view: () => {
      const cur = S.state().lang;
      return `
      <div style="text-align:center;margin:14px 0 22px">${S.logo(76)}</div>
      <h2 class="screen-title" style="text-align:center">${S.t('onb.chooseLang')}</h2>
      <p class="screen-sub" style="text-align:center;margin-bottom:22px">आफ्नो भाषा छान्नुहोस् · Choose your language</p>
      <div class="lang-card ${cur === 'ne' ? 'active' : ''}" data-act="lang" data-arg="ne">
        <span class="flag">🇳🇵</span>
        <div class="grow"><b>नेपाली (Nepali)</b><div class="sub">नेपाली भाषा</div></div>
        ${cur === 'ne' ? S.icon('i-check', 'ci') : ''}
      </div>
      <div class="lang-card ${cur === 'en' ? 'active' : ''}" data-act="lang" data-arg="en">
        <span class="flag">🇬🇧</span>
        <div class="grow"><b>English</b><div class="sub">Global language</div></div>
        ${cur === 'en' ? S.icon('i-check', 'ci') : ''}
      </div>
      <button class="btn primary mt16" data-act="nav" data-arg="auth">${S.t('onb.continue')}</button>`;
    }
  };

  /* ===== Login / Sign Up ===== */
  R.auth = {
    nonav: true,
    view: () => `
      ${S.topNav('Sign in to SAGE Core', 'Private owner workspace')}
      <div class="card glow" style="text-align:center;padding:24px">
        <div style="font-size:28px;font-weight:800;letter-spacing:2px">SAGE ONE</div>
        <div class="tiny muted mt8">Sign in with the configured owner Google account to connect this website to the real SAGE backend.</div>
        <div class="or">SECURE GOOGLE SIGN-IN</div>
        <button class="google-btn" data-act="auth-google">
          <svg width="17" height="17" viewBox="0 0 24 24"><path fill="#4285F4" d="M23 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.2a5.3 5.3 0 0 1-2.3 3.5v2.9h3.7c2.2-2 3.4-5 3.4-8.6z"/><path fill="#34A853" d="M12 24c3.1 0 5.7-1 7.6-2.8l-3.7-2.9c-1 .7-2.3 1.1-3.9 1.1-3 0-5.5-2-6.4-4.7H1.8v3C3.7 21.4 7.6 24 12 24z"/><path fill="#FBBC05" d="M5.6 14.7a7.2 7.2 0 0 1 0-4.6v-3H1.8a12 12 0 0 0 0 10.7l3.8-3z"/><path fill="#EA4335" d="M12 4.8c1.7 0 3.2.6 4.4 1.7l3.3-3.3C17.7 1.2 15.1 0 12 0 7.6 0 3.7 2.6 1.8 6.1l3.8 3C6.5 6.7 9 4.8 12 4.8z"/></svg>
          Continue with Google
        </button>
        <div class="notice mt12">Google tokens are held in memory for this tab. SAGE Core must verify the identity and grant owner access; a normal Google sign-in does not automatically grant owner permissions.</div>
      </div>`,
    mount() {}
  };

  /* ===== KYC Verification ===== */
  R.kyc = {
    nonav: true,
    view: () => `
      ${S.topNav('Identity Verification', 'Verification must be confirmed by a real provider')}
      <div class="card glow" style="padding:20px">
        <div class="row" style="gap:12px;align-items:flex-start">
          <div class="iconbox">${S.icon('i-shield')}</div>
          <div class="grow">
            <b>Formal KYC is not connected</b>
            <div class="tiny muted mt8">SAGE Core currently has no government-ID, face-liveness, or KYC provider connected to this website. No identity scan is running and no KYC status can be granted here.</div>
          </div>
        </div>
      </div>
      <div class="card mt12">
        <b class="small">What this means</b>
        <div class="tiny muted mt8">Do not upload government ID or biometric data here. A provider-backed verification flow must be implemented and tested before SAGE can mark KYC complete or unlock regulated financial actions.</div>
      </div>
      <button class="btn soft mt16" data-act="back">${S.icon('i-arrow-l')} Back to SAGE</button>
      <div class="notice mt12">Status: NOT CONNECTED · No verification claim has been made.</div>`
  };

  /* ===== Create Profile ===== */
  R['profile-create'] = {
    nonav: true,
    view: () => {
      const u = S.state().user;
      return `
      ${S.topNav('Complete Your Profile', 'Help us know you better')}
      <div class="avatar-pick ${u.avatar ? 'filled' : ''}" data-act="pick-avatar">
        ${u.avatar ? `<div style="width:100%;height:100%;border-radius:50%;background:var(--grad-btn);display:flex;align-items:center;justify-content:center;font-size:30px">${S.esc(u.avatar)}</div>` : S.icon('i-camera')}
        <div class="cam">${S.icon('i-plus')}</div>
      </div>
      <div class="field"><label>Name</label><input class="input" id="pc-name" placeholder="e.g. Ramesh Shrestha" value="${S.esc(u.name)}"></div>
      <div class="field"><label>Location</label><input class="input" id="pc-loc" placeholder="e.g. Kathmandu, Nepal" value="${S.esc(u.location)}"></div>
      <div class="field"><label>Phone Number</label><input class="input" id="pc-phone" placeholder="e.g. +977 98XXXXXXXX" value="${S.esc(u.phone)}"></div>
      <button class="btn primary mt12" data-act="profile-save">${S.t('onb.continue')}</button>`;
    }
  };

  /* ===== Welcome to SAGE ONE (Let's Go) ===== */
  R['welcome-go'] = {
    nonav: true,
    view: () => `
      <div class="hero-art" style="height:260px">
        <div class="h-stars"></div><div class="h-moon"></div><div class="h-peak"></div>
        <div class="h-logo">${S.logo(100)}</div>
      </div>
      <div style="text-align:center;margin-top:6px">
        <div class="pill blue" style="margin-bottom:10px">JOURNEY STARTED</div>
        <h2 class="screen-title">Welcome to SAGE ONE</h2>
        <p class="screen-sub" style="margin:8px auto 0;max-width:270px;line-height:1.7">Your journey begins now. Learn, earn, and evolve through 13 cosmic stages.</p>
      </div>
      <div class="grid3 mt20">
        <div class="stat-tile" style="text-align:center"><div class="v" style="color:var(--electric-2)">13</div><div class="k">EVOLUTIONS</div></div>
        <div class="stat-tile" style="text-align:center"><div class="v" style="color:var(--cyan)">${S.fmtSpark(S.state().spark)}</div><div class="k">SPARK</div></div>
        <div class="stat-tile" style="text-align:center"><div class="v" style="color:var(--gold)">1</div><div class="k">STAGE</div></div>
      </div>
      <button class="btn primary mt20" data-act="finish-onboard">Let's Go ${S.icon('i-arrow-r')}</button>`
  };

})(window.SAGE);
