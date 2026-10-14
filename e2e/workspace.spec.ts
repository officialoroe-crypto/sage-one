import { test, expect, request as playwrightRequest } from '@playwright/test';

const apiBase = (process.env.SAGE_API_URL || 'https://sage-one-api.onrender.com').replace(/\/+$/, '');

test.describe('SAGE Core read-only smoke checks', () => {
  test('health endpoint reports healthy', async () => {
    const api = await playwrightRequest.newContext();
    const response = await api.get(`${apiBase}/health`, { timeout: 30_000 });
    expect(response.ok(), `GET ${apiBase}/health returned HTTP ${response.status()}`).toBeTruthy();
    const body = await response.json();
    expect(body.status).toBe('healthy');
    await api.dispose();
  });

  test('identity config advertises Google sign-in', async () => {
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

test.describe('SAGE ONE public website browser interactions', () => {
  test('landing page renders metadata, brand artwork and the evolution explorer', async ({ page }) => {
    const pageErrors: string[] = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    await page.goto('/');
    await expect(page).toHaveTitle(/SAGE ONE/);
    await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', /personal AI mentor/i);
    await expect(page.locator('.hero h1')).toContainText('Think less.');
    await expect(page.locator('.hero-logo')).toHaveAttribute('alt', /SAGE ONE logo/i);
    await expect(page.locator('.hero-logo-link')).toHaveAttribute('href', '#top');
    await expect(page.locator('#rankChips button[data-rank="1"]')).toBeVisible();
    await expect(page.locator('#evolveBtn')).toBeVisible();
    expect(pageErrors, 'uncaught landing-page JavaScript errors').toEqual([]);
  });

  test('mobile menu opens, navigates and closes accessibly', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/');
    const toggle = page.locator('#menuToggle');
    const nav = page.locator('#primaryNav');
    await expect(toggle).toBeVisible();
    await expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await expect(nav).toBeHidden();
    await toggle.click();
    await expect(toggle).toHaveAttribute('aria-expanded', 'true');
    await expect(nav).toBeVisible();
    await nav.locator('a[href="#evolution"]').click();
    await expect(page).toHaveURL(/#evolution$/);
    await expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await expect(nav).toBeHidden();
  });

  test('Spark converter and spend-limit calculator respond to input', async ({ page }) => {
    await page.goto('/');
    await page.locator('#sparkIn').fill('123');
    await expect(page.locator('#nprIn')).toHaveValue('123');
    await page.locator('#nprIn').fill('456');
    await expect(page.locator('#sparkIn')).toHaveValue('456');
    await page.locator('#lifeIn').fill('60');
    await page.locator('#balIn').fill('60');
    await page.locator('#askIn').fill('5');
    await expect(page.locator('#verdict')).toContainText('may show you a 5 Spark spend');
  });

  test('all 13 Evolution ranks, all intensities and the Evolve action work', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto('/');
    const ranks = page.locator('#rankChips button[data-rank]');
    await expect(ranks).toHaveCount(13);
    for (let i = 0; i < 13; i++) {
      const rank = ranks.nth(i);
      const label = (await rank.innerText()).replace(/^\d+\s*/, '');
      await rank.click();
      await expect(page.locator('#rankTitle')).toContainText(label);
      await expect(rank).toHaveAttribute('aria-pressed', 'true');
    }
    for (const level of ['0', '1', '2']) {
      const button = page.locator(`#levelSeg button[data-level="${level}"]`);
      await button.click();
      await expect(button).toHaveAttribute('aria-pressed', 'true');
    }
    await ranks.first().click();
    await page.locator('#evolveBtn').click();
    await expect(page.locator('#rankTitle')).toContainText('Silver');
  });

  test('chat preview clearly discloses simulated sign-in and replies', async ({ page }) => {
    await page.goto('/chat/');
    await expect(page).toHaveTitle(/Chat Preview/);
    await expect(page.locator('#signin')).toContainText('sign-in is simulated on this page');
    await page.locator('#googleBtn').click();
    await expect(page.locator('#shell')).toBeVisible();
    await expect(page.locator('#accMode')).toContainText('simulated');
    await page.locator('#input').fill('Hello SAGE, this is a preview test.');
    await page.locator('#sendBtn').click();
    await expect(page.locator('#feed')).toContainText('Hello SAGE, this is a preview test.');
    await expect(page.locator('.composer-note')).toContainText('scripted examples');
    await page.locator('#menuBtn').click();
    await expect(page.locator('#shell')).toHaveClass(/rail-open/);
    await page.locator('#newChat').click();
    await expect(page.locator('#chatTitle')).toHaveText('New chat');
    const features = page.locator('#nav button[data-feature]');
    const featureCount = await features.count();
    expect(featureCount).toBeGreaterThan(0);
    for (let i = 0; i < featureCount; i++) {
      await page.locator('#menuBtn').click();
      await features.nth(i).click();
      await expect(page.locator('#pane')).toBeVisible();
      await expect(page.locator('#paneTitle')).not.toBeEmpty();
      await page.locator('#paneClose').click();
    }
  });

  test('phone preview opens its chat sheet and labels sample values', async ({ page }) => {
    await page.goto('/app-preview/');
    await expect(page).toHaveTitle(/Phone App Preview/);
    await expect(page.locator('.preview-note')).toContainText('example numbers');
    await expect(page.locator('#balance')).toBeVisible();
    await page.locator('#sageBtn').click();
    await expect(page.locator('#sheet')).toBeVisible();
    await page.locator('#msg').fill('What is my Evolution rank?');
    await page.locator('#send').click();
    await expect(page.locator('#transcript')).toContainText('Evolution');
    await page.locator('#sheetClose').click();
    await expect(page.locator('#sheet')).toBeHidden();
    await page.locator('#sageBtn').click();
    const prompts = page.locator('#prompts button[data-cmd]');
    const promptCount = await prompts.count();
    expect(promptCount).toBe(4);
    for (let i = 0; i < promptCount; i++) {
      await prompts.nth(i).click();
      await expect(page.locator('#stateLabel')).toHaveText(/Done|Waiting for your approval/);
    }
  });

  test('all preview pages fit narrow, mobile, tablet and desktop widths', async ({ page }) => {
    for (const path of ['/', '/chat/', '/app-preview/']) {
      for (const width of [320, 375, 768, 1280]) {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(path);
        const dimensions = await page.evaluate(() => ({
          viewport: window.innerWidth,
          document: document.documentElement.scrollWidth,
          body: document.body.scrollWidth
        }));
        expect(dimensions.document, `horizontal overflow on ${path} at ${width}px: ${JSON.stringify(dimensions)}`)
          .toBeLessThanOrEqual(width + 1);
        expect(dimensions.body, `body overflow on ${path} at ${width}px: ${JSON.stringify(dimensions)}`)
          .toBeLessThanOrEqual(width + 1);
      }
    }
  });

  test('visible buttons have a readable name or are disabled', async ({ page }) => {
    for (const path of ['/', '/chat/', '/app-preview/']) {
      await page.goto(path);
      if (path === '/chat/') await page.locator('#ownerBtn').waitFor();
      const unnamed = await page.locator('button').evaluateAll(buttons => buttons
        .filter(button => {
          const element = button as HTMLButtonElement;
          if (element.disabled) return false;
          return !element.innerText.trim() && !element.getAttribute('aria-label') &&
            !element.getAttribute('title') && !element.getAttribute('aria-labelledby');
        })
        .map(button => ({ id: button.id, title: button.getAttribute('title') })));
      expect(unnamed, `unnamed buttons on ${path}`).toEqual([]);
    }
  });
});
