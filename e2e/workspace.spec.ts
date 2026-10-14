import { test, expect, request as playwrightRequest } from '@playwright/test';

const apiBase = (process.env.SAGE_API_URL || 'https://sage-one-api.onrender.com').replace(/\/+$/, '');

test.describe('SAGE Core live API smoke checks', () => {
  test('health endpoint reports healthy', async () => {
    const api = await playwrightRequest.newContext();
    const response = await api.get(`${apiBase}/health`, { timeout: 30_000 });
    expect(response.ok(), `GET ${apiBase}/health returned HTTP ${response.status()}`).toBeTruthy();
    const body = await response.json();
    expect(body.status).toBe('healthy');
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
});

test.describe('SAGE ONE actual browser interactions', () => {
  test.beforeEach(async ({ page }) => {
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
    expect(pageErrors, 'uncaught browser JavaScript errors').toEqual([]);
  });

  test('real click actions navigate to Chat and the app hub', async ({ page }) => {
    await page.goto('/');
    await page.locator('#screen [data-act="chat"]').first().click();
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
    await page.locator('#screen [data-act="chat"]').first().click();
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
    const routes = ['home', 'apps', 'chat', 'research', 'jobs', 'marketplace', 'learning', 'community', 'aistudio', 'files', 'logostates', 'premium', 'profile', 'settings', 'wallet', 'spark', 'earn', 'evolution', 'agents', 'workflow', 'integrations', 'memory', 'aisettings'];
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
    const routes = ['home', 'apps', 'chat', 'research', 'jobs', 'marketplace', 'learning', 'community', 'aistudio', 'files', 'logostates', 'premium', 'profile', 'settings', 'wallet', 'spark', 'earn', 'evolution', 'agents', 'workflow', 'integrations', 'memory', 'aisettings'];
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
