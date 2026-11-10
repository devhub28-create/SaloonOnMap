import { Request, Response } from 'express';

export function registerWebRoutes(app: any) {
  // 1. Root Landing Page
  app.get('/', (_req: Request, res: Response) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SalonOnMap — Smart Salon Discovery & Real-Time Booking</title>
  <link rel="icon" type="image/png" href="https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=128">
  <style>
    :root {
      --bg: #0b0f19;
      --card-bg: #131b2e;
      --border: #232f48;
      --gold: #f59e0b;
      --gold-light: #fbbf24;
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --success: #10b981;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text-main);
      line-height: 1.6;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }
    header {
      border-bottom: 1px solid var(--border);
      padding: 1rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: rgba(11, 15, 25, 0.8);
      backdrop-filter: blur(12px);
      position: sticky;
      top: 0;
      z-index: 100;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
      font-weight: 800;
      font-size: 1.3rem;
      letter-spacing: -0.5px;
    }
    .brand-icon {
      width: 36px;
      height: 36px;
      background: linear-gradient(135deg, var(--gold), #d97706);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 900;
      color: #0b0f19;
      font-size: 1.1rem;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: var(--success);
      padding: 6px 14px;
      border-radius: 999px;
      font-size: 0.85rem;
      font-weight: 600;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background: var(--success);
      border-radius: 50%;
      box-shadow: 0 0 10px var(--success);
    }
    main {
      flex: 1;
      max-width: 1100px;
      width: 100%;
      margin: 0 auto;
      padding: 4rem 1.5rem 2rem;
    }
    .hero {
      text-align: center;
      margin-bottom: 4rem;
    }
    .hero-tag {
      display: inline-block;
      text-transform: uppercase;
      font-size: 0.8rem;
      letter-spacing: 2px;
      color: var(--gold-light);
      font-weight: 700;
      margin-bottom: 1rem;
    }
    .hero h1 {
      font-size: 2.8rem;
      font-weight: 800;
      letter-spacing: -1px;
      margin-bottom: 1.2rem;
      background: linear-gradient(to right, #ffffff, #cbd5e1);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .hero p {
      font-size: 1.15rem;
      color: var(--text-muted);
      max-width: 650px;
      margin: 0 auto 2rem;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 1.5rem;
      margin-bottom: 3rem;
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 2rem;
      transition: transform 0.2s, border-color 0.2s;
    }
    .card:hover {
      transform: translateY(-2px);
      border-color: rgba(245, 158, 11, 0.4);
    }
    .card h3 {
      font-size: 1.3rem;
      margin-bottom: 0.8rem;
      color: #fff;
    }
    .card p {
      color: var(--text-muted);
      font-size: 0.95rem;
      margin-bottom: 1.5rem;
    }
    .btn {
      display: inline-block;
      background: linear-gradient(135deg, var(--gold), #d97706);
      color: #0b0f19;
      font-weight: 700;
      text-decoration: none;
      padding: 10px 20px;
      border-radius: 10px;
      font-size: 0.9rem;
      transition: opacity 0.2s;
    }
    .btn:hover { opacity: 0.9; }
    .btn-outline {
      background: transparent;
      border: 1px solid var(--border);
      color: var(--text-main);
      margin-left: 8px;
    }
    .btn-outline:hover {
      background: rgba(255, 255, 255, 0.05);
      border-color: var(--gold);
    }
    .api-status {
      background: rgba(19, 27, 46, 0.6);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 1.5rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 1rem;
    }
    .api-status-left {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .api-status-left span {
      font-size: 0.85rem;
      color: var(--text-muted);
    }
    .api-status-left strong {
      font-size: 1rem;
      color: var(--text-main);
    }
    footer {
      border-top: 1px solid var(--border);
      padding: 2rem;
      text-align: center;
      color: var(--text-muted);
      font-size: 0.85rem;
      margin-top: 3rem;
    }
    .footer-links {
      display: flex;
      justify-content: center;
      gap: 1.5rem;
      margin-bottom: 1rem;
      flex-wrap: wrap;
    }
    .footer-links a {
      color: var(--text-muted);
      text-decoration: none;
      transition: color 0.2s;
    }
    .footer-links a:hover { color: var(--gold); }
    @media (max-width: 640px) {
      .hero h1 { font-size: 2rem; }
      header { padding: 1rem; }
    }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <div class="brand-icon">S</div>
      <span>SalonOnMap</span>
    </div>
    <div class="status-badge">
      <span class="status-dot"></span>
      API Operational
    </div>
  </header>

  <main>
    <section class="hero">
      <div class="hero-tag">Cloud Backend & Mobile API</div>
      <h1>Smart Salon Discovery & Real-Time Booking</h1>
      <p>The centralized backend powering both the <strong>SalonOnMap</strong> customer mobile app and <strong>SalonOnMap Business</strong> partner app.</p>
      <div>
        <a href="/api/v1/health" class="btn">View API Health</a>
        <a href="/api/v1/salons" class="btn btn-outline">Explore Salons Endpoint</a>
      </div>
    </section>

    <div class="grid">
      <div class="card">
        <h3>📱 SalonOnMap App</h3>
        <p>Customer mobile app for live salon discovery, real-time chair queue tracking, AI hairstyle preview, and instant digital QR passes.</p>
        <span style="font-size: 0.85rem; color: var(--gold);">Package: com.app.salononmap</span>
      </div>

      <div class="card">
        <h3>💼 SalonOnMap Business</h3>
        <p>Salon management suite for salon owners and stylists. Manage live chair matrices, track queues, staff schedules, and daily revenues.</p>
        <span style="font-size: 0.85rem; color: var(--gold);">Package: com.app.salononmap.partner</span>
      </div>
    </div>

    <div class="api-status">
      <div class="api-status-left">
        <strong>Base API Prefix</strong>
        <span>All mobile REST endpoints are located at <code>/api/v1/*</code></span>
      </div>
      <div>
        <a href="/api/v1/health" style="color: var(--gold); text-decoration: none; font-size: 0.9rem; font-weight: 600;">Check Health JSON &rarr;</a>
      </div>
    </div>
  </main>

  <footer>
    <div class="footer-links">
      <a href="/privacy">Privacy Policy</a>
      <a href="/terms">Terms of Service</a>
      <a href="/delete-account">Account Deletion</a>
      <a href="/api/v1/health">System Status</a>
    </div>
    <p>&copy; 2026 SalonOnMap. All rights reserved. Support: <a href="mailto:support@salononmap.com" style="color: var(--gold); text-decoration: none;">support@salononmap.com</a></p>
  </footer>
</body>
</html>`);
  });

  // 2. Privacy Policy Page (Mandatory for Google Play Store)
  app.get('/privacy', (_req: Request, res: Response) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy — SalonOnMap</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.7;
      color: #334155;
      background: #f8fafc;
      padding: 2rem 1rem;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: #ffffff;
      padding: 3rem;
      border-radius: 16px;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
      border: 1px solid #e2e8f0;
    }
    h1 { color: #0f172a; font-size: 2.2rem; margin-bottom: 0.5rem; }
    h2 { color: #1e293b; font-size: 1.3rem; margin-top: 2rem; margin-bottom: 0.75rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 0.4rem; }
    p, li { font-size: 1rem; margin-bottom: 0.8rem; }
    ul { padding-left: 1.5rem; }
    .updated { color: #64748b; font-size: 0.9rem; margin-bottom: 2rem; }
    a { color: #d97706; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Privacy Policy</h1>
    <div class="updated">Last Updated: October 2026 | Effective for <strong>SalonOnMap</strong> and <strong>SalonOnMap Business</strong></div>

    <p>SalonOnMap ("we", "us", or "our") respects your privacy. This policy describes how we collect, use, and protect your information when using the <strong>SalonOnMap</strong> customer application and the <strong>SalonOnMap Business</strong> partner application.</p>

    <h2>1. Information We Collect</h2>
    <ul>
      <li><strong>Personal Information:</strong> Name, phone number, and optional email address provided during registration or login.</li>
      <li><strong>Location Data:</strong> Approximate and precise geolocation (with user consent) to display nearby salons on the map and calculate estimated travel distances. Location is processed when the app is in use and not tracked in the background.</li>
      <li><strong>Booking & Transaction Data:</strong> Appointment times, selected services, chair reservations, and payment receipts.</li>
      <li><strong>Camera & Photos (Optional):</strong> Uploaded user photos for the AI Style Studio feature to simulate haircuts and beard styles. Photos are processed strictly for style generation and are never sold or shared.</li>
    </ul>

    <h2>2. How We Use Information</h2>
    <ul>
      <li>To discover nearby salons, barbershops, and spas.</li>
      <li>To reserve salon chairs and manage real-time queues.</li>
      <li>To transmit booking confirmations, reminders, and digital QR passes.</li>
      <li>To enable salon partners to process walk-in and digital reservations.</li>
    </ul>

    <h2>3. Data Protection & Security</h2>
    <p>All data transmitted between mobile clients and our cloud servers is encrypted in transit using standard Transport Layer Security (TLS/HTTPS). Sensitive credentials and access tokens are hashed and stored securely.</p>

    <h2>4. Third-Party Sharing</h2>
    <p>We do not sell, rent, or trade your personal data. We only share information with:</p>
    <ul>
      <li><strong>Participating Salons:</strong> Sharing your name, reserved service, and appointment time for order fulfillment.</li>
      <li><strong>Infrastructure & SMS Providers:</strong> Cloud hosting, database, and SMS/OTP verification providers under strict confidentiality agreements.</li>
    </ul>

    <h2>5. User Rights & Account Deletion</h2>
    <p>You have the right to access, rectify, or delete your personal account and associated booking history. You can initiate account deletion at any time via our <a href="/delete-account">Account Deletion Page</a> or by emailing <a href="mailto:support@salononmap.com">support@salononmap.com</a>.</p>

    <h2>6. Contact Us</h2>
    <p>If you have questions about this Privacy Policy, please reach out to us:</p>
    <ul>
      <li>Email: <a href="mailto:support@salononmap.com">support@salononmap.com</a></li>
      <li>Website: <a href="https://salononmap.vercel.app">https://salononmap.vercel.app</a></li>
    </ul>
  </div>
</body>
</html>`);
  });

  // 3. Terms of Service Page
  app.get('/terms', (_req: Request, res: Response) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Terms of Service — SalonOnMap</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.7;
      color: #334155;
      background: #f8fafc;
      padding: 2rem 1rem;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: #ffffff;
      padding: 3rem;
      border-radius: 16px;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
      border: 1px solid #e2e8f0;
    }
    h1 { color: #0f172a; font-size: 2.2rem; margin-bottom: 0.5rem; }
    h2 { color: #1e293b; font-size: 1.3rem; margin-top: 2rem; margin-bottom: 0.75rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 0.4rem; }
    p, li { font-size: 1rem; margin-bottom: 0.8rem; }
    ul { padding-left: 1.5rem; }
    .updated { color: #64748b; font-size: 0.9rem; margin-bottom: 2rem; }
    a { color: #d97706; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Terms of Service</h1>
    <div class="updated">Last Updated: October 2026</div>

    <h2>1. Acceptance of Terms</h2>
    <p>By creating an account or accessing <strong>SalonOnMap</strong> or <strong>SalonOnMap Business</strong>, you agree to comply with and be bound by these Terms of Service.</p>

    <h2>2. Description of Service</h2>
    <p>SalonOnMap provides an online marketplace and real-time chair reservation platform connecting customers with independent salons, barbershops, and spas. SalonOnMap facilitates discovery and booking but is not the direct provider of grooming or beauty services.</p>

    <h2>3. Bookings & Cancellations</h2>
    <ul>
      <li>Customers must arrive at the salon on or before their scheduled chair time.</li>
      <li>Cancellations and rescheduling must adhere to the specific policy displayed during checkout.</li>
      <li>Salon partners are responsible for honoring confirmed reservations and maintaining accurate service listings.</li>
    </ul>

    <h2>4. Contact Information</h2>
    <p>For questions regarding terms, contact <a href="mailto:support@salononmap.com">support@salononmap.com</a>.</p>
  </div>
</body>
</html>`);
  });

  // 4. Account Deletion Request Page (Mandatory for Google Play Console Data Safety)
  app.get('/delete-account', (_req: Request, res: Response) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Account Deletion Request — SalonOnMap</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.7;
      color: #334155;
      background: #f8fafc;
      padding: 2rem 1rem;
    }
    .container {
      max-width: 650px;
      margin: 0 auto;
      background: #ffffff;
      padding: 3rem;
      border-radius: 16px;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
      border: 1px solid #e2e8f0;
    }
    h1 { color: #0f172a; font-size: 2rem; margin-bottom: 0.5rem; }
    p { margin-bottom: 1.2rem; color: #475569; }
    .card-box {
      background: #f1f5f9;
      border-radius: 10px;
      padding: 1.2rem;
      margin-bottom: 1.5rem;
      font-size: 0.95rem;
    }
    .btn {
      display: inline-block;
      background: #dc2626;
      color: white;
      text-decoration: none;
      padding: 12px 24px;
      border-radius: 8px;
      font-weight: 600;
    }
    .btn:hover { background: #b91c1c; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Request Account & Data Deletion</h1>
    <p>In compliance with Google Play Data Safety policies, users of <strong>SalonOnMap</strong> and <strong>SalonOnMap Business</strong> may request permanent deletion of their account and all associated data.</p>

    <div class="card-box">
      <strong>What will be deleted:</strong>
      <ul>
        <li>Your profile (name, phone number, email address)</li>
        <li>Past booking histories and appointment records</li>
        <li>Saved hairstyle studio previews and preferences</li>
      </ul>
      <p style="margin-top: 8px; font-size: 0.85rem; color: #64748b;">Financial transaction logs required for tax and statutory auditing are retained in an anonymized format for the legally required duration.</p>
    </div>

    <p>To request deletion, send an email from your registered email address or mentioning your registered phone number to our data privacy team:</p>
    
    <a href="mailto:support@salononmap.com?subject=Account%20Deletion%20Request%20-%20SalonOnMap" class="btn">Send Account Deletion Request</a>
    
    <p style="margin-top: 1.5rem; font-size: 0.9rem; color: #64748b;">Requests are processed within 48 to 72 business hours. You will receive a final confirmation email/SMS once deletion is complete.</p>
  </div>
</body>
</html>`);
  });
}
