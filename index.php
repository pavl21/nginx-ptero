<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PVQ Panel – Webserver</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background: #0b0b14;
            color: #e2e8f0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
        }

        .card {
            background: #13131f;
            border: 1px solid #1e1e35;
            border-radius: 20px;
            padding: 2.75rem 3rem;
            max-width: 460px;
            width: 100%;
            position: relative;
            overflow: hidden;
        }

        .card::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 3px;
            background: linear-gradient(90deg, #6366f1, #a855f7, #ec4899);
        }

        .card::after {
            content: '';
            position: absolute;
            top: -120px; right: -80px;
            width: 300px; height: 300px;
            background: radial-gradient(circle, rgba(99,102,241,0.07) 0%, transparent 70%);
            pointer-events: none;
        }

        .logo-wrap {
            display: flex;
            justify-content: center;
            margin-bottom: 1.5rem;
        }

        .logo-wrap img {
            width: 80px;
            height: 80px;
            object-fit: contain;
            filter: drop-shadow(0 0 18px rgba(168,85,247,0.4));
        }

        .title {
            font-size: 1.7rem;
            font-weight: 700;
            letter-spacing: -0.03em;
            text-align: center;
            background: linear-gradient(135deg, #f1f5f9 20%, #a855f7 80%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 0.3rem;
        }

        .subtitle {
            text-align: center;
            color: #475569;
            font-size: 0.88rem;
            margin-bottom: 2rem;
        }

        .divider {
            height: 1px;
            background: linear-gradient(90deg, transparent, #1e1e35, transparent);
            margin-bottom: 1.75rem;
        }

        .rows { display: flex; flex-direction: column; gap: 0.75rem; }

        .row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
            padding: 0.65rem 0.9rem;
            border-radius: 10px;
            background: #0f0f1c;
            border: 1px solid #1a1a2e;
        }

        .row-label {
            color: #64748b;
            font-size: 0.82rem;
            font-weight: 500;
        }

        .row-value {
            font-size: 0.82rem;
            font-family: 'SF Mono', 'Fira Code', monospace;
            color: #94a3b8;
        }

        .row-value.highlight {
            color: #a78bfa;
            background: rgba(99,102,241,0.1);
            border: 1px solid rgba(99,102,241,0.2);
            padding: 0.15rem 0.55rem;
            border-radius: 6px;
        }

        .dot {
            display: inline-block;
            width: 7px; height: 7px;
            border-radius: 50%;
            background: #22c55e;
            box-shadow: 0 0 6px #22c55e;
            margin-right: 0.4rem;
            vertical-align: middle;
        }

        .footer {
            margin-top: 1.75rem;
            text-align: center;
            font-size: 0.76rem;
            color: #2d2d50;
        }

        .footer code {
            color: #6366f1;
            font-family: 'SF Mono', 'Fira Code', monospace;
        }

        .next-steps {
            margin-top: 1.75rem;
            padding-top: 1.5rem;
            border-top: 1px solid #1a1a2e;
        }

        .next-title {
            font-size: 0.72rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: #334155;
            margin-bottom: 1rem;
        }

        .step {
            display: flex;
            gap: 0.85rem;
            align-items: flex-start;
            margin-bottom: 0.85rem;
        }

        .step:last-child { margin-bottom: 0; }

        .step-icon {
            font-size: 1.1rem;
            line-height: 1;
            margin-top: 1px;
            flex-shrink: 0;
        }

        .step strong {
            display: block;
            font-size: 0.82rem;
            font-weight: 600;
            color: #94a3b8;
            margin-bottom: 0.15rem;
        }

        .step span {
            font-size: 0.78rem;
            color: #475569;
            line-height: 1.45;
        }

        .step code {
            color: #6366f1;
            font-family: 'SF Mono', 'Fira Code', monospace;
            font-size: 0.76rem;
        }

        @media (max-width: 480px) {
            .card { padding: 2rem 1.5rem; }
            .title { font-size: 1.45rem; }
        }
    </style>
</head>
<body>
<div class="card">

    <div class="logo-wrap">
        <img src="https://pv-q.de/panel-assets/logos/pvq-logo.webp" alt="PVQ Panel Logo">
    </div>

    <h1 class="title">PVQ Panel</h1>
    <p class="subtitle">Webserver bereit &amp; aktiv</p>

    <div class="divider"></div>

    <div class="rows">
        <div class="row">
            <span class="row-label">PHP-Version</span>
            <span class="row-value highlight"><?php echo htmlspecialchars(phpversion()); ?></span>
        </div>
        <div class="row">
            <span class="row-label">Webroot</span>
            <span class="row-value">/home/container/webroot</span>
        </div>
        <div class="row">
            <span class="row-label">Status</span>
            <span class="row-value"><span class="dot"></span>Online</span>
        </div>
    </div>

    <div class="next-steps">
        <p class="next-title">Wie geht es weiter?</p>
        <div class="step">
            <div class="step-icon">&#128194;</div>
            <div>
                <strong>Eigene Website</strong>
                <span>Lege deine Dateien in <code>/webroot</code> ab &mdash; diese Seite wird automatisch ersetzt.</span>
            </div>
        </div>
        <div class="step">
            <div class="step-icon">&#128736;</div>
            <div>
                <strong>WordPress</strong>
                <span>Aktiviere <code>WORDPRESS=1</code> in den Starteinstellungen und installiere den Server neu.</span>
            </div>
        </div>
    </div>

</div>
</body>
</html>
