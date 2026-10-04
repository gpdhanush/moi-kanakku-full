export function renderErrorPage(): string {
  return `<!doctype html>
<html lang="ta" class="lang-ta">
  <head>
    <meta charset="utf-8" />
    <title>Moi Kanakku – This page didn't load</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" href="/favicon.png" type="image/png" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;700;800&family=Mukta+Malar:wght@200;300;400;500;600;700;800&family=Noto+Sans+Tamil:wght@100..900&display=swap"
      rel="stylesheet"
    />
    <style>
      :root {
        --forest: #0b3d2e;
        --lime: #90d01f;
        --lime-bright: #9ae214;
        --mist: #eef6e4;
        --ink: #09090b;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        min-height: 100dvh;
        display: grid;
        place-items: center;
        padding: 2rem 1.25rem;
        font-family: "Mukta Malar", "Noto Sans Tamil", system-ui, sans-serif;
        color: var(--forest);
        background:
          radial-gradient(ellipse 80% 60% at 50% -10%, rgba(144, 208, 31, 0.18), transparent 55%),
          radial-gradient(ellipse 70% 50% at 100% 100%, rgba(11, 61, 46, 0.08), transparent 50%),
          linear-gradient(180deg, #f7faf8 0%, #ffffff 45%, var(--mist) 100%);
      }
      body::before {
        content: "";
        position: fixed;
        inset: 0;
        pointer-events: none;
        opacity: 0.35;
        background-image: radial-gradient(rgba(11, 61, 46, 0.06) 1px, transparent 1px);
        background-size: 22px 22px;
      }
      .wrap {
        position: relative;
        z-index: 1;
        width: 100%;
        max-width: 28rem;
        text-align: center;
      }
      .brand {
        display: inline-flex;
        align-items: center;
        gap: 0.65rem;
        margin-bottom: 2.5rem;
        text-decoration: none;
      }
      .logo-box {
        display: flex;
        width: 2.75rem;
        height: 2.75rem;
        align-items: center;
        justify-content: center;
        padding: 0.35rem;
        border-radius: 5px;
        border: 1px solid rgba(11, 61, 46, 0.1);
        background: #fff;
        box-shadow: 0 10px 30px -18px rgba(11, 61, 46, 0.45);
      }
      .logo-box img { width: 100%; height: 100%; object-fit: contain; }
      .wordmark {
        font-family: "Space Grotesk", "Noto Sans Tamil", system-ui, sans-serif;
        font-size: 1.15rem;
        font-weight: 700;
        letter-spacing: -0.03em;
        color: var(--forest);
      }
      .icon {
        display: flex;
        width: 3.5rem;
        height: 3.5rem;
        margin: 0 auto 1.25rem;
        align-items: center;
        justify-content: center;
        border-radius: 5px;
        background: var(--forest);
        color: var(--lime);
      }
      h1 {
        margin: 0;
        font-family: "Space Grotesk", "Noto Sans Tamil", system-ui, sans-serif;
        font-size: clamp(1.75rem, 4vw, 2.25rem);
        font-weight: 800;
        letter-spacing: -0.04em;
        line-height: 1.15;
      }
      p {
        margin: 0.85rem auto 0;
        max-width: 36ch;
        font-size: 0.95rem;
        line-height: 1.6;
        color: rgba(11, 61, 46, 0.7);
      }
      .actions {
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        justify-content: center;
        margin-top: 2rem;
      }
      button, a {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-height: 2.75rem;
        padding: 0 1.25rem;
        border-radius: 5px;
        border: none;
        font: inherit;
        font-size: 0.875rem;
        font-weight: 600;
        text-decoration: none;
        cursor: pointer;
        transition: background-color 0.15s ease, transform 0.1s ease;
      }
      button:active, a:active { transform: scale(0.98); }
      .primary {
        background: var(--lime);
        color: var(--ink);
      }
      .primary:hover { background: var(--lime-bright); }
      .secondary {
        background: var(--forest);
        color: #fff;
      }
      .secondary:hover { background: #000; }
      .ta { display: none; }
      html.lang-ta .ta, html[lang="ta"] .ta { display: inline; }
      html.lang-ta .en, html[lang="ta"] .en { display: none; }
      html.lang-en .ta, html[lang="en"] .ta { display: none; }
      html.lang-en .en, html[lang="en"] .en { display: inline; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <a class="brand" href="/" aria-label="Moi Kanakku">
        <span class="logo-box"><img src="/logo.png" alt="" /></span>
        <span class="wordmark">Moi Kanakku</span>
      </a>
      <div class="icon" aria-hidden="true">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 9v4" />
          <path d="M12 17h.01" />
          <path d="M10.3 3.9 1.9 18a2 2 0 0 0 1.7 3h16.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
        </svg>
      </div>
      <h1>
        <span class="ta">பக்கம் ஏற்றப்படவில்லை</span>
        <span class="en">This page didn't load</span>
      </h1>
      <p>
        <span class="ta">எங்கள் பக்கத்தில் ஏதோ தவறு நடந்துவிட்டது. மீண்டும் முயலவும் அல்லது முகப்பிற்குச் செல்லவும்.</span>
        <span class="en">Something went wrong on our end. Try refreshing, or head back home.</span>
      </p>
      <div class="actions">
        <button class="primary" type="button" onclick="location.reload()">
          <span class="ta">மீண்டும் முயலவும்</span>
          <span class="en">Try again</span>
        </button>
        <a class="secondary" href="/">
          <span class="ta">முகப்புக்குச் செல்ல</span>
          <span class="en">Go home</span>
        </a>
      </div>
    </div>
    <script>
      (function () {
        try {
          var s = localStorage.getItem("preferred-language") || localStorage.getItem("moi-lang");
          var lang = s === "en" ? "en" : "ta";
          document.documentElement.lang = lang;
          document.documentElement.classList.add(lang === "ta" ? "lang-ta" : "lang-en");
          document.documentElement.classList.remove(lang === "ta" ? "lang-en" : "lang-ta");
        } catch (e) {}
      })();
    </script>
  </body>
</html>`;
}
