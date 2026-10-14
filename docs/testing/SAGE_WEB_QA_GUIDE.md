# SAGE ONE — Web QA guide (Windows)

This guide is for checking the real Flutter web application without publishing it publicly. The public GitHub Pages website is the marketing page; the app build is a separate, temporary GitHub Actions artifact.

## 1. Find the latest test build

1. Open the [SAGE ONE repository](https://github.com/officialoroe-crypto/sage-one).
2. Select **Actions** near the top.
3. Open **SAGE ONE Marketing Website and Web App QA**.
4. Choose the latest successful run on `main`.
5. Scroll to **Artifacts** at the bottom and download `sage-one-web-qa-...`.
6. Right-click the downloaded ZIP and choose **Extract All**. Extract it to a simple folder such as `C:\SageOne\web-qa`.

If there is no artifact, or the run is red, do not test an older artifact as if it were current. Open the failed run and send the run link and the red step name.

## 2. Start the website on your computer

Flutter web must be opened over HTTP; do not double-click `index.html` and use a `file://` URL.

1. Open the extracted folder and confirm that `index.html` and `flutter_bootstrap.js` are present.
2. Open **Command Prompt** (not a browser address bar).
3. Run:

```bat
cd /d C:\SageOne\web-qa
py -m http.server 8080
```

If you extracted the ZIP to a different folder, replace `C:\SageOne\web-qa` with your actual folder path.

4. Keep the black Command Prompt window open.
5. Open Chrome or Opera and visit **http://127.0.0.1:8080**.

To stop the local server later, click the Command Prompt window and press **Ctrl+C**.

## 3. Check the backend connection

The QA build is configured to use the HTTPS SAGE Core API, not `localhost:8010`.

1. Wait for the sign-in screen to finish loading.
2. Try **Continue with Google** using the configured SAGE owner account.
3. If sign-in succeeds, send a simple chat request such as: `Reply with exactly: SAGE WEB CONNECTION OK`.
4. Confirm that SAGE returns a response and that the screen does not show an offline, CORS, or configuration error.
5. Open the Tasks screen and check that it loads. Do not create real tasks that could trigger external actions unless you intend to run them.

A successful page load alone does **not** prove backend connectivity. The sign-in and chat steps test the real API path.

## 4. If something fails

- **Page is blank:** check that the Command Prompt server is still running, and reload `http://127.0.0.1:8080`.
- **Google sign-in says origin/client error:** the Google OAuth web client must allow `http://127.0.0.1:8080` as an authorized JavaScript origin. Do not paste client secrets or ID tokens into chat.
- **Core offline / network error:** open the latest QA run and check the **Smoke-test live backend for web integration** result on a main-branch run.
- **CORS error:** report the exact error text and the website origin shown in the browser. Do not disable browser security.
- **401 / owner access denied:** use the configured owner Google account; normal Google sign-in does not grant owner access.
- **Chat fails after login:** press **F12**, select **Console**, take a screenshot of the red error, and send it with the QA run link. Never share cookies, authorization headers, tokens, or passwords.

## What counts as a pass?

- The page loads without a blank screen.
- Owner Google sign-in succeeds.
- The app displays the owner workspace.
- A chat request receives a real response from SAGE Core.
- Tasks can be opened without an unexplained error.
- The GitHub Actions Python tests, Flutter analysis/tests, web QA build, and live-backend smoke check are green.

Passing these checks does not automatically verify Android device sign-in, SMS OTP delivery, voice permissions, or screen-aware assistance. Those need separate device tests.
