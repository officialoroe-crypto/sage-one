import { test, expect, request as playwrightRequest } from '@playwright/test';

const apiBase = (process.env.SAGE_API_URL || 'https://sage-one-api.onrender.com').replace(/\/+$/, '');

test.describe('SAGE Core live API smoke checks', () => {
  test('health endpoint reports healthy', async () => {
    // The hosted API can cold-start; allow the bounded three-attempt retry budget.
    test.setTimeout(90_000);
    const api = await playwrightRequest.newContext();
    const failures: string[] = [];
    try {
      // Hosted free-tier services may be waking from idle. Retry transient transport
      // failures, but still fail the smoke test if the health endpoint never responds
      // or returns an unhealthy/non-2xx result. This is not a health-check bypass.
      let response: Awaited<ReturnType<typeof api.get>> | undefined;
      for (let attempt = 1; attempt <= 3; attempt += 1) {
        try {
          response = await api.get(`${apiBase}/health`, { timeout: 20_000 });
          if (response.ok()) break;
          failures.push(`attempt ${attempt}: HTTP ${response.status()}`);
        } catch (error) {
          failures.push(`attempt ${attempt}: ${String(error)}`);
        }
        if (attempt < 3) await new Promise(resolve => setTimeout(resolve, 2_000));
      }
      expect(response?.ok(), `GET ${apiBase}/health did not return 2xx after 3 attempts. ${failures.join(' | ')}`).toBeTruthy();
      const body = await response!.json();
      expect(body.status, `GET ${apiBase}/health returned an unexpected body: ${JSON.stringify(body)}`).toBe('healthy');
    } finally {
      await api.dispose();
    }
  });

  test('production CORS allows the published site but not the ephemeral localhost QA origin', async () => {
    const api = await playwrightRequest.newContext();
    const localOriginResponse = await api.get(`${apiBase}/identity/config`, {
      headers: { Origin: 'http://127.0.0.1:8080' },
      timeout: 30_000
    });
    expect(localOriginResponse.ok()).toBeTruthy();
    expect(localOriginResponse.headers()['access-control-allow-origin']).not.toBe('http://127.0.0.1:8080');

    const publishedOriginResponse = await api.get(`${apiBase}/identity/config`, {
      headers: { Origin: 'https://officialoroe-crypto.github.io' },
      timeout: 30_000
    });
    expect(publishedOriginResponse.ok()).toBeTruthy();
    expect(publishedOriginResponse.headers()['access-control-allow-origin']).toBe('https://officialoroe-crypto.github.io');
    await api.dispose();
  });

  test('identity config is reachable and advertises Google sign-in', async () => {
    const api = await playwrightRequest.newContext();
    const response = await api.get(`${apiBase}/identity/config`, { timeout: 30_000 });
    expect(response.ok(), `GET ${apiBase}/identity/config returned HTTP ${response.status()}`).toBeTruthy();
    const body = await response.json();
    expect(body.success).toBeTruthy();
    expect(typeof body.google_client_id).toBe('string');
    expect(body.google_client_id.length).toBeGreaterThan(10);
    await api.dispose();
  });

  test('published website origin can preflight authenticated Chat requests', async () => {
    const origin = 'https://officialoroe-crypto.github.io';
    const api = await playwrightRequest.newContext();
    const response = await api.fetch(`${apiBase}/chat`, {
      method: 'OPTIONS',
      timeout: 30_000,
      headers: {
        Origin: origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'authorization,content-type'
      }
    });
    expect([200, 204]).toContain(response.status());
    expect(response.headers()['access-control-allow-origin']).toBe(origin);
    expect((response.headers()['access-control-allow-methods'] || '').toUpperCase()).toContain('POST');
    const allowedHeaders = (response.headers()['access-control-allow-headers'] || '').toLowerCase();
    expect(allowedHeaders).toContain('authorization');
    expect(allowedHeaders).toContain('content-type');
    await api.dispose();
  });
});

test.describe('SAGE ONE actual browser interactions', () => {
  test.beforeEach(async ({ page }) => {
    // The separate API smoke tests above exercise the live service. Keep browser
    // UI checks deterministic when the hosted service's CORS deployment lags code.
    await page.route('**/identity/config', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          google_client_id: 'qa-client-id.apps.googleusercontent.com',
          developer_mode: false,
          owner_mode_available: true
        })
      });
    });
    // Use a disposable QA-only account state. No production identity or stored token.
    await page.addInitScript(() => {
      localStorage.setItem('sage-one-state-v1', JSON.stringify({
        onboarded: true,
        lang: 'en',
        theme: 'dark',
        user: { name: 'Browser QA', email: '', location: 'QA', avatar: 'Q' },
        evo: { stage: 1, level: 'low', progress: 22, maxStage: 13 },
        chat: [],
        demoDataVersion: 2
      }));
    });
  });

  test('workspace boots, renders home, and has no uncaught JavaScript errors', async ({ page }) => {
    const pageErrors: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    await page.goto('/');
    await expect(page.locator('#screen')).toBeVisible();
    await expect(page.locator('#screen')).toContainText('Namaste');
    await expect(page.locator('#homeAsk')).toBeVisible();
    await expect(page.locator('#sageBackendStatus')).toBeVisible();
    // The QA server uses an ephemeral localhost origin that production intentionally
    // does not allow. Live API reachability and CORS policy are tested separately above.
    expect(pageErrors, 'uncaught browser JavaScript errors').toEqual([]);
  });

  test('real click actions navigate to Chat and the app hub', async ({ page }) => {
    await page.goto('/');
    await page.locator('#tabbar [data-act="chat"]').first().click();
    await expect(page.locator('#chatInput')).toBeVisible();
    await expect(page.locator('#chatBody')).toBeVisible();

    await page.locator('#screen [data-act="back"]').click();
    await expect(page.locator('#homeAsk')).toBeVisible();

    await page.locator('#screen [data-act="nav"][data-arg="apps"]').first().click();
    await expect(page.locator('#screen')).toContainText('SAGE Apps');
    await expect(page.locator('#screen [data-act="nav"][data-arg="research"]').first()).toBeVisible();
  });

  test('Chat does not pretend to answer when owner authentication is missing', async ({ page }) => {
    await page.goto('/');
    await page.locator('#tabbar [data-act="chat"]').first().click();
    await page.locator('#chatInput').fill('QA check: please reply with a short greeting.');
    await page.locator('#screen [data-act="chat-send"]').click();
    await expect(page.locator('#sageBackendStatus')).toBeVisible();
    await expect(page.locator('#sageGoogleButton')).toBeVisible();
    await expect(page.locator('#toastRoot')).toContainText('Sign in with the configured SAGE owner');
    // This test verifies the authentication guard, not a real AI answer.
  });

  test('primary screens render without throwing', async ({ page }) => {
    const pageErrors: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    await page.goto('/');
    const routes = ['home', 'apps', 'chat', 'research', 'jobs', 'marketplace', 'learning', 'community', 'aistudio', 'files', 'logostates', 'premium', 'profile', 'settings', 'wallet', 'spark', 'earn', 'evolution', 'agents', 'workflow', 'integrations', 'memory', 'aisettings', 'history', 'activity'];
    const inventory: Array<{ route: string; rendered: boolean; error?: string }> = [];
    for (const route of routes) {
      const result = await page.evaluate((name) => {
        try {
          if (!window.SAGE?.screens?.[name]) return { rendered: false, error: 'screen not registered' };
          window.SAGE.go(name, null, { replace: true });
          const screen = document.querySelector('#screen');
          return { rendered: Boolean(screen && screen.textContent?.trim().length), error: undefined };
        } catch (error) {
          return { rendered: false, error: String(error) };
        }
      }, route);
      inventory.push({ route, ...result });
    }
    await test.info().attach('primary-screen-inventory.json', {
      body: JSON.stringify(inventory, null, 2),
      contentType: 'application/json'
    });
    const failed = inventory.filter(item => !item.rendered);
    expect(failed, `screens that failed to render: ${JSON.stringify(failed)}`).toEqual([]);
    expect(pageErrors, 'uncaught browser JavaScript errors while visiting primary screens').toEqual([]);
  });

  test('visible controls expose an action or are explicitly disabled', async ({ page }) => {
    await page.goto('/');
    const audit = await page.evaluate(() => {
      const root = document.querySelector('#screen');
      if (!root) return { total: 0, missing: [] as string[] };
      const controls = Array.from(root.querySelectorAll('button, [role="button"], input[type="button"], input[type="submit"]'));
      const missing = controls
        .filter((el) => {
          const item = el as HTMLElement;
          return !item.hasAttribute('disabled') && !item.hasAttribute('data-act') && !item.getAttribute('aria-disabled');
        })
        .map((el) => ({
          element: el.tagName.toLowerCase(),
          label: (el as HTMLElement).innerText?.trim() || el.getAttribute('aria-label') || el.getAttribute('title') || '',
          id: el.id || ''
        }))
        .map(item => JSON.stringify(item));
      return { total: controls.length, missing };
    });
    await test.info().attach('visible-control-audit.json', {
      body: JSON.stringify(audit, null, 2),
      contentType: 'application/json'
    });
    expect(audit.total).toBeGreaterThan(0);
    expect(audit.missing, 'controls without an action, disabled state, or aria-disabled explanation').toEqual([]);
  });
});

test('bulk action wiring audit across every primary screen', async ({ page }) => {
  await page.goto('/');
  const audit = await page.evaluate(async () => {
    const routes = ['home', 'apps', 'chat', 'research', 'jobs', 'marketplace', 'learning', 'community', 'aistudio', 'files', 'logostates', 'premium', 'profile', 'settings', 'wallet', 'spark', 'earn', 'evolution', 'agents', 'workflow', 'integrations', 'memory', 'aisettings', 'history', 'activity'];
    const scripts = Array.from(document.scripts).map(script => script.src).filter(src => src && src.startsWith(location.origin + '/js/'));
    const sourcePairs = await Promise.all(scripts.map(async src => [new URL(src).pathname.split('/').pop() || '', await (await fetch(src)).text()] as const));
    const source = Object.fromEntries(sourcePairs) as Record<string, string>;
    const appSource = source['app.js'] || '';
    const backendSource = source['backend.js'] || '';
    const known = new Set<string>();
    for (const match of appSource.matchAll(/case\s+['"]([^'"]+)['"]\s*:/g)) known.add(match[1]);
    for (const match of backendSource.matchAll(/name\s*===\s*['"]([^'"]+)['"]/g)) known.add(match[1]);
    const demo = backendSource.match(/const DEMO_ONLY\s*=\s*new Set\(\[([\s\S]*?)\]\);/);
    if (demo) for (const match of demo[1].matchAll(/['"]([^'"]+)['"]/g)) known.add(match[1]);
    for (const name of (window.SAGE?.AG_ACT_KNOWN || [])) known.add(name);
    const perScreen: Array<{route:string; controls:number; actions:string[]; noAction:string[]}> = [];
    for (const route of routes) {
      try {
        if (!window.SAGE?.screens?.[route]) {
          perScreen.push({ route, controls: 0, actions: [], noAction: ['SCREEN NOT REGISTERED'] });
          continue;
        }
        window.SAGE.go(route, null, { replace: true });
        const root = document.querySelector('#screen');
        const controls = Array.from(root?.querySelectorAll('button, [role="button"], input[type="button"], input[type="submit"]') || []) as HTMLElement[];
        const actions = controls.map(el => el.getAttribute('data-act')).filter((value): value is string => Boolean(value));
        const noAction = controls.filter(el => !el.hasAttribute('data-act') && !el.hasAttribute('disabled') && el.getAttribute('aria-disabled') !== 'true')
          .map(el => (el.innerText || el.getAttribute('aria-label') || el.title || el.tagName).trim().slice(0, 100));
        perScreen.push({ route, controls: controls.length, actions: Array.from(new Set(actions)).sort(), noAction });
      } catch (error) {
        perScreen.push({ route, controls: 0, actions: [], noAction: ['RENDER ERROR: ' + String(error)] });
      }
    }
    const actions = Array.from(new Set(perScreen.flatMap(screen => screen.actions))).sort();
    const unhandledActions = actions.filter(action => !known.has(action));
    return {
      routesChecked: routes.length,
      registeredRoutes: perScreen.filter(screen => !screen.noAction.includes('SCREEN NOT REGISTERED')).length,
      totalControls: perScreen.reduce((sum, screen) => sum + screen.controls, 0),
      uniqueActions: actions.length,
      unhandledActions,
      perScreen
    };
  });
  await test.info().attach('all-screen-action-wiring-audit.json', {
    body: JSON.stringify(audit, null, 2),
    contentType: 'application/json'
  });
  expect(audit.registeredRoutes, 'primary screens missing from the app').toBe(audit.routesChecked);
  expect(audit.totalControls, 'no screen controls were inventoried').toBeGreaterThan(0);
  const controlsWithoutActions = audit.perScreen.flatMap(screen => screen.noAction.filter(item => item !== 'SCREEN NOT REGISTERED').map(item => ({ route: screen.route, item })));
  expect(controlsWithoutActions, 'interactive-looking controls without an action or disabled state').toEqual([]);
  expect(audit.unhandledActions, 'visible actions without a recognized dispatcher; inspect attached audit report').toEqual([]);
});

test('voice button captures a transcript and waits for explicit user send', async ({ page }) => {
  test.setTimeout(20_000);
  await page.addInitScript(() => {
    class FakeSpeechRecognition {
      onresult: ((event: any) => void) | null = null;
      onend: (() => void) | null = null;
      onerror: ((event: any) => void) | null = null;
      lang = '';
      continuous = false;
      interimResults = false;
      start() { (window as any).__fakeSageRecognition = this; }
      stop() { this.onend?.(); }
    }
    (window as any).SpeechRecognition = FakeSpeechRecognition;
  });
  await page.goto('/');
  await page.evaluate(() => window.SAGE.go('chat', null, { replace: true }));
  await expect(page.locator('#chatInput')).toBeVisible();
  await page.locator('#screen [data-act="voice-toggle"][data-arg="#chatInput"]').click();
  await expect(page.locator('#sageBackendStatus')).toContainText('LISTENING');
  await page.evaluate(() => {
    const recognition = (window as any).__fakeSageRecognition;
    const phrase = { 0: { transcript: 'Hello SAGE, this is a voice QA test.' }, isFinal: true, length: 1 };
    recognition.onresult({ resultIndex: 0, results: [phrase] });
    recognition.onend();
  });
  await expect(page.locator('#chatInput')).toHaveValue('Hello SAGE, this is a voice QA test.');
  await expect(page.locator('#sageBackendStatus')).toContainText('VOICE CAPTURED');
  const state = await page.evaluate(() => window.SAGE.state().chat);
  expect(state, 'voice recognition must not silently send a task or chat message').toEqual([]);
});

test('Files category buttons filter the visible file list', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => window.SAGE.go('files', null, { replace: true }));
  const recent = await page.locator('#screen .list-item').count();
  await page.locator('#screen [data-act="files-tab"][data-arg="Documents"]').click();
  await expect(page.locator('#screen [data-act="files-tab"][data-arg="Documents"]')).toHaveClass(/active/);
  const documents = await page.locator('#screen .list-item').count();
  await page.locator('#screen [data-act="files-tab"][data-arg="Media"]').click();
  await expect(page.locator('#screen [data-act="files-tab"][data-arg="Media"]')).toHaveClass(/active/);
  const media = await page.locator('#screen .list-item').count();
  expect(recent).toBeGreaterThan(0);
  expect(documents).toBeGreaterThan(0);
  expect(media).toBeGreaterThan(0);
  expect(documents).not.toBe(recent);
});

test('unconnected community membership and file upload are not falsely marked successful', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => window.SAGE.go('community', null, { replace: true }));
  const join = page.locator('#screen button[disabled][title*="Group membership"]');
  await expect(join.first()).toBeDisabled();
  await page.locator('#screen [data-act="comm-tab"][data-arg="Training"]').click();
  await expect(page.locator('#screen button[disabled][title*="Event registration"]')).toBeDisabled();
  await page.evaluate(() => window.SAGE.go('files', null, { replace: true }));
  await expect(page.locator('#screen button[disabled][title*="Real file uploads"]')).toBeDisabled();
});

const coreUrl = 'https://sage-one-api.onrender.com';

async function signInAsMockOwner(page: import('@playwright/test').Page) {
  await page.route(coreUrl + '/identity/config', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    json: { success: true, google_client_id: 'qa-client.apps.googleusercontent.com', owner_mode_available: true }
  }));
  await page.route(coreUrl + '/identity/google', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    json: { success: true, owner_mode: true, profile: { name: 'Browser QA Owner' }, identity: { email: 'qa-owner@example.test' } }
  }));
  await page.addInitScript(() => {
    (window as any).google = { accounts: { id: {
      initialize: function(options: any) { (window as any).__sageQaGoogleCallback = options.callback; },
      renderButton: function(mount: HTMLElement) {
        const button = document.createElement('button');
        button.id = 'qa-google-sign-in';
        button.type = 'button';
        button.textContent = 'Continue with Google';
        button.onclick = function() { (window as any).__sageQaGoogleCallback({ credential: 'qa-owner-token' }); };
        mount.appendChild(button);
      }
    } } };
  });
  await page.goto('/');
  await page.evaluate(() => window.SAGE.go('auth', null, { replace: true }));
  await expect(page.locator('#sageGoogleButton')).toBeVisible();
  await expect(page.locator('#qa-google-sign-in')).toBeVisible();
  await page.locator('#qa-google-sign-in').click();
  await expect(page.locator('#screen')).toContainText('Namaste');
}

test('saved conversations load, archive, restore, and reopen through real UI actions', async ({ page }) => {
  let archived = false;
  await page.route(coreUrl + '/sessions*', async route => {
    const isArchived = new URL(route.request().url()).searchParams.get('archived') === 'true';
    const include = isArchived === archived;
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      json: {
        success: true,
        archived: isArchived,
        sessions: include ? [{
          id: 'qa-session-1',
          preview: 'How do I recover my saved SAGE conversation?',
          created_at: '2026-10-14T10:00:00Z',
          message_count: 2,
          archived: isArchived
        }] : []
      }
    });
  });
  await page.route(coreUrl + '/session/qa-session-1/archive', async route => {
    archived = true;
    await route.fulfill({ status: 200, contentType: 'application/json', json: { success: true, session_id: 'qa-session-1', archived: true } });
  });
  await page.route(coreUrl + '/session/qa-session-1/restore', async route => {
    archived = false;
    await route.fulfill({ status: 200, contentType: 'application/json', json: { success: true, session_id: 'qa-session-1', archived: false } });
  });
  await page.route(coreUrl + '/session/qa-session-1/messages*', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    json: {
      success: true,
      session_id: 'qa-session-1',
      messages: [
        { role: 'user', content: 'How do I recover my saved SAGE conversation?' },
        { role: 'assistant', content: 'Open Chat History and restore the archived conversation.' }
      ]
    }
  }));

  await signInAsMockOwner(page);
  await page.evaluate(() => window.SAGE.go('history', null, { replace: true }));
  await expect(page.locator('#sageHistoryList')).toContainText('How do I recover my saved SAGE conversation?');
  await page.locator('#sageHistoryList [data-act="history-archive"]').click();
  await expect(page.locator('#sageHistoryList')).toContainText('No conversations in this list yet');
  await page.locator('#screen [data-act="history-filter"][data-arg="archived"]').click();
  await expect(page.locator('#sageHistoryList')).toContainText('How do I recover my saved SAGE conversation?');
  await page.locator('#sageHistoryList [data-act="history-restore"]').click();
  await expect(page.locator('#sageHistoryList')).toContainText('No conversations in this list yet');
  await page.locator('#screen [data-act="history-filter"][data-arg="active"]').click();
  await expect(page.locator('#sageHistoryList')).toContainText('How do I recover my saved SAGE conversation?');
  await page.locator('#sageHistoryList [data-act="history-archive"]').click();
  await page.locator('#screen [data-act="history-filter"][data-arg="archived"]').click();
  await page.locator('#sageHistoryList [data-act="history-open"]').click();
  await expect(page.locator('#chatBody')).toContainText('How do I recover my saved SAGE conversation?');
  await expect(page.locator('#chatBody')).toContainText('Open Chat History and restore the archived conversation.');
});

test('Activity Center loads owner tasks and notifications and marks notifications read', async ({ page }) => {
  let read = false;
  await page.route(coreUrl + '/tasks*', async route => {
    expect(route.request().headers()['authorization']).toBe('Bearer qa-owner-token');
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      json: { success: true, tasks: [{ id: 'qa-task-1', title: 'Browser QA task', status: 'completed', result: 'Task result verified by the QA fixture', created_at: '2026-10-14T10:00:00Z' }] }
    });
  });
  await page.route(coreUrl + '/notifications*', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      json: { success: true, notifications: [{ id: 'qa-notice-1', title: 'SAGE task completed', body: 'Your test task finished.', read, created_at: '2026-10-14T10:01:00Z' }] }
    });
  });
  await page.route(coreUrl + '/notifications/qa-notice-1/read', async route => {
    read = true;
    await route.fulfill({ status: 200, contentType: 'application/json', json: { success: true, notification: { id: 'qa-notice-1', read: true } } });
  });
  await signInAsMockOwner(page);
  await page.evaluate(() => window.SAGE.go('activity', null, { replace: true }));
  await expect(page.locator('#sageActivityContent')).toContainText('Browser QA task');
  await expect(page.locator('#sageActivityContent')).toContainText('Task result verified by the QA fixture');
  await expect(page.locator('#sageActivityContent')).toContainText('SAGE task completed');
  await page.locator('#sageActivityContent [data-act="activity-read"]').click();
  await expect(page.locator('#sageActivityContent')).toContainText('Read');
});

test('New Chat clears the current local transcript and session pointer', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => {
    window.SAGE.state().chatSessionId = 'old-session';
    window.SAGE.state().chat = [{ role: 'user', text: 'Old conversation must not carry over.' }];
    window.SAGE.save();
    window.SAGE.go('history', null, { replace: true });
  });
  await page.locator('#screen [data-act="chat-new"]').click();
  await expect(page.locator('#chatInput')).toBeVisible();
  const state = await page.evaluate(() => ({
    sessionId: window.SAGE.state().chatSessionId || null,
    messages: window.SAGE.state().chat
  }));
  expect(state.sessionId).toBeNull();
  expect(state.messages).toEqual([]);
});

test('dashboard and Chat do not display fake live or financial success states', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => window.SAGE.go('home', null, { replace: true }));
  await expect(page.locator('#screen')).toContainText('Verified real earnings');
  await expect(page.locator('#screen')).toContainText('Open Activity Center');
  await expect(page.locator('#screen')).not.toContainText('+12%');
  await expect(page.locator('#screen')).not.toContainText('Found 24 sources');
  await page.evaluate(() => window.SAGE.go('chat', null, { replace: true }));
  await expect(page.locator('#screen')).toContainText('connection status shown below');
  await expect(page.locator('#screen')).not.toContainText('Online · AI Mentor');
});

test('authenticated Chat sends through the Core API contract and displays the returned answer', async ({ page }) => {
  let chatRequest: Record<string, unknown> | null = null;
  await page.route(coreUrl + '/chat', async route => {
    expect(route.request().headers()['authorization']).toBe('Bearer qa-owner-token');
    chatRequest = route.request().postDataJSON();
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      json: { success: true, session_id: 'qa-chat-session', response: { text: 'SAGE Core mock response verified.' } }
    });
  });
  await page.route(coreUrl + '/sessions*', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    json: { success: true, archived: false, sessions: [{
      id: 'qa-chat-session',
      preview: 'Please reply with the browser QA result.',
      created_at: '2026-10-14T10:00:00Z',
      message_count: 2,
      archived: false
    }] }
  }));
  await signInAsMockOwner(page);
  await page.evaluate(() => window.SAGE.go('chat', null, { replace: true }));
  await page.locator('#chatInput').fill('Please reply with the browser QA result.');
  await page.locator('#screen [data-act="chat-send"]').click();
  await expect(page.locator('#chatBody')).toContainText('SAGE Core mock response verified.');
  expect(chatRequest).toMatchObject({ message: 'Please reply with the browser QA result.' });
  const state = await page.evaluate(() => window.SAGE.state().chatSessionId);
  expect(state).toBe('qa-chat-session');
  await page.evaluate(() => window.SAGE.go('history', null, { replace: true }));
  await expect(page.locator('#sageHistoryList')).toContainText('Please reply with the browser QA result.');
});
