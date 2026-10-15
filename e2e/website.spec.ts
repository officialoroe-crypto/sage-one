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

test.describe('SAGE ONE website interactions', () => {
  test('landing page metadata, navigation, logo and menu work', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle('SAGE ONE');
    await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', /SAGE ONE/);
    await expect(page.locator('link[rel="icon"]')).toHaveCount(1);
    await expect(page.locator('.wordmark').first()).toHaveAttribute('href', '#top');

    const menu = page.locator('#menuToggle');
    await expect(menu).toBeVisible();
    await menu.click();
    await expect(menu).toHaveAttribute('aria-expanded', 'true');
    await page.locator('#primaryNav a[href="#evolution"]').click();
    await expect(page).toHaveURL(/#evolution$/);
    await expect(menu).toHaveAttribute('aria-expanded', 'false');
    await menu.click();
    await expect(menu).toHaveAttribute('aria-expanded', 'true');
    await page.keyboard.press('Escape');
    await expect(menu).toHaveAttribute('aria-expanded', 'false');
  });

  test('landing, Chat preview and phone preview have no local missing assets or uncaught errors', async ({ page }) => {
    const pageErrors: string[] = [];
    const localFailures: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('response', response => {
      if (response.url().startsWith('http://127.0.0.1:8080/') && response.status() >= 400) {
        localFailures.push(`${response.status()} ${response.url()}`);
      }
    });

    for (const route of ['/', '/chat/', '/app-preview/']) {
      await page.goto(route);
      await expect(page.locator('body')).toBeVisible();
    }
    expect(localFailures, 'local page or asset requests failed').toEqual([]);
    expect(pageErrors, 'uncaught browser JavaScript errors').toEqual([]);
  });

  test('layout has no accidental horizontal overflow at narrow and desktop widths', async ({ page }) => {
    await page.goto('/');
    for (const width of [320, 360, 390, 768, 1024, 1280]) {
      await page.setViewportSize({ width, height: 844 });
      const dimensions = await page.evaluate(() => ({
        viewport: window.innerWidth,
        document: document.documentElement.scrollWidth,
        body: document.body.scrollWidth,
      }));
      expect(dimensions.document, `document overflow at ${width}px: ${JSON.stringify(dimensions)}`).toBeLessThanOrEqual(width);
      expect(dimensions.body, `body overflow at ${width}px: ${JSON.stringify(dimensions)}`).toBeLessThanOrEqual(width);
    }
  });

  test('buttons and form controls have accessible names on all preview pages', async ({ page }) => {
    for (const route of ['/', '/chat/', '/app-preview/']) {
      await page.goto(route);
      const unnamed = await page.locator('button, input, textarea, select').evaluateAll(elements => elements
        .filter(el => {
          const item = el as HTMLInputElement;
          if (item.type === 'hidden') return false;
          const text = item.innerText?.trim() || '';
          const label = item.getAttribute('aria-label') || item.getAttribute('aria-labelledby') ||
            item.getAttribute('title') || '';
          const id = item.id;
          const associated = id ? document.querySelector(`label[for="${CSS.escape(id)}"]`) : null;
          return !(text || label || associated);
        })
        .map(el => `${el.tagName.toLowerCase()}#${(el as HTMLElement).id}`));
      expect(unnamed, `unnamed controls on ${route}`).toEqual([]);
    }
  });

  test('Chat preview clearly identifies simulated sign-in and scripted replies; send button works', async ({ page }) => {
    await page.goto('/chat/');
    await expect(page.locator('#googleBtn')).toContainText('Preview Google sign-in');
    await expect(page.locator('.signin-card .fine')).toContainText('simulated');
    await page.locator('#googleBtn').click();
    await expect(page.locator('#shell')).toBeVisible();
    await page.locator('#input').fill('hello SAGE');
    await expect(page.locator('#sendBtn')).toBeEnabled();
    await page.locator('#sendBtn').click();
    await expect(page.locator('#feed')).toContainText('hello SAGE');
    await expect(page.locator('.topline')).toContainText('Demo replies');
  });

  test('phone preview Talk button opens the sheet and sends a scripted reply', async ({ page }) => {
    await page.goto('/app-preview/');
    await expect(page.locator('.preview-note')).toContainText('Preview only');
    await page.locator('#sageBtn').click();
    await expect(page.locator('#sheet')).toBeVisible();
    await page.locator('#msg').fill('show my Spark balance');
    await page.locator('#send').click();
    await expect(page.locator('#transcript')).toContainText('SS');
    await expect(page.locator('#transcript')).toContainText('No live wallet');
  });
});
