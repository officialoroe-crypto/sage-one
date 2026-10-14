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
