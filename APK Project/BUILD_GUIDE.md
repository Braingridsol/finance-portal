# Finance Portal — Complete Build Guide

> **Single self-contained document** to build the Finance Portal sprint-by-sprint using any AI coding assistant (Claude, ChatGPT, Gemini, etc.).

---

## How to Use This Document

1. **Read Sections 1–4** to understand what we're building (overview, tech stack, data models, design system).
2. **Each sprint has a "PROMPT TO COPY" block.** Paste it verbatim into your AI coding assistant of choice.
3. **The AI produces code.** Save the output file.
4. **Run the acceptance checklist** at the end of each sprint before moving to the next.
5. **Do not skip sprints** — each builds on the previous.

**Tip for best results:** Use a capable model (Claude Sonnet/Opus, GPT-4/5, Gemini Pro). Smaller models may struggle with the larger sprints.

---

# PART 1 — OVERVIEW

## Section 1: Product Summary

**Finance Portal** is a personal finance management web app — single HTML file, runs in any browser on desktop and mobile.

**Modules (15):**
1. **Auth & Profiles** — login + Tally-style multi-profile (Personal / Business / Family)
2. **People** — family members linked to insurance
3. **Accounts** — bank accounts with AMB/AQB tracking
4. **Credit Cards** — with billing cycles & statement view
5. **Loans** — full amortization, prepayment recalc, rate/tenure edits, foreclosure
6. **Insurance** — health/life/vehicle/etc. with insured persons
7. **Investments** — SIP, MF, stocks, gold, EPF, PPF with purpose & asset class
8. **Transactions** — 4 types (Income/Expense/Settlement/Transfer) × 2 statuses (Draft/Settled)
9. **Recurring** — templates auto-generate Draft transactions
10. **Projection** — forward cash flow forecast
11. **Dashboard** — net worth, alerts, charts
12. **Settings** — preferences, categories editor, profile management
13. **Reports** — Net Worth Statement, Income & Expense, Cash Flow, Ledger, Day Book, Analytical reports
14. **Export & Backup** — PDF, Excel, CSV, encrypted JSON
15. **Financial Health** — 24 personal finance ratios with scoring

**Phased delivery in 6 sprints** (one batch of working code per sprint).

---

## Section 2: Tech Stack & File Structure

### Sprint 1–3 (local-first)
- **Single HTML file** (`finance-tracker.html`) — embedded CSS and JavaScript
- **Lucide Icons** via CDN (`https://unpkg.com/lucide@latest/dist/umd/lucide.js`)
- **Chart.js** via CDN for charts
- **Inter font** via Google Fonts
- **IndexedDB** for local storage (NOT localStorage — too small)
- **No frameworks** — vanilla JS for portability

### Sprint 4+ (backend)
- **Supabase** for auth + database + real-time
- **Supabase JS client** via CDN
- Still single HTML file but talks to Supabase API

### Sprint 5+ (mobile-distinct + PWA)
- **PWA manifest** + service worker
- Adaptive UI based on viewport

### File deliverables per sprint
- `finance-tracker.html` — the app (gets replaced each sprint)
- Sprint 4 adds: `supabase_schema.sql` (run once in Supabase)
- Sprint 5 adds: `manifest.webmanifest`, `sw.js`, icon assets

---

## Section 3: Core Data Models (used across all sprints)

These TypeScript-style schemas describe every entity. All IDs are UUIDs (random strings).

```typescript
// Settings (per profile)
type Settings = {
  currency: string;          // default '₹'
  theme: 'light' | 'dark';
  projectionDays: number;    // default 60
  fyStartMonth: number;      // 1-12, default 4 (April for India)
  retirementAge: number;     // default 60
  inflationRate: number;     // default 6.0 (%)
  equityBenchmarkReturn: number; // default 12.0 (%)
  cardMinPaymentPct: number; // default 5.0 (%)
  roundingDecimals: 0 | 2;   // default 0 for display, storage always 2
};

// Profile (Tally-style — one user can have many)
type Profile = {
  id: string;
  name: string;             // "Personal", "Business"
  type: 'Personal'|'Business'|'Family'|'Other';
  currency: string;         // default '₹'
  color?: string;           // accent color
  icon?: string;            // Lucide icon name
  isDefault: boolean;
  archived: boolean;
  createdAt: string;        // ISO timestamp
};

// Person (family member)
type Person = {
  id: string;
  name: string;
  relationship: 'Self'|'Spouse'|'Father'|'Mother'|'Son'|'Daughter'|'Brother'|'Sister'|'Father-in-law'|'Mother-in-law'|'Other';
  dob?: string;             // YYYY-MM-DD; required on "Self" for age-based ratios
  pan?: string;
  notes?: string;
};

// Account (bank, FD, RD, wallet, cash)
type Account = {
  id: string;
  name: string;             // "HDFC Salary"
  bank?: string;
  type: 'Savings'|'Current'|'Salary'|'Fixed Deposit'|'Recurring Deposit'|'Wallet'|'Cash'|'NRE'|'NRO'|'Demat Cash'|'Other';
  status: 'Active'|'Dormant'|'Closed';
  last4?: string;           // max 4 digits
  balance: number;          // auto-updated by settled transactions
  minBalance: number;       // default 0
  minBalanceType: 'None'|'Daily'|'AMB'|'AQB';  // default 'None'
  interestRate?: number;    // % p.a.
  interestPayout?: 'Cumulative'|'Monthly'|'Quarterly'|'Half-yearly'|'Yearly';
  ifsc?: string;
  openingDate?: string;
  maturityDate?: string;    // for FD/RD
  maturityAmount?: number;  // for FD/RD
  jointHolder?: string;
  nominee?: string;
  notes?: string;
};

// Card (credit card)
type Card = {
  id: string;
  name: string;
  bank?: string;
  network: 'Visa'|'Mastercard'|'Rupay'|'Amex'|'Diners';
  status: 'Active'|'Blocked'|'Closed';
  last4?: string;
  limit: number;            // credit limit
  interestRate?: number;    // for revolving credit
  billDay: number;          // 1-31, statement generation day
  dueDay: number;           // 1-31, payment due day
  annualFee?: number;
  waiver?: string;          // fee waiver criteria
  rewardType: 'Cashback'|'Points'|'Miles'|'None';
  rewardRate?: number;      // % or pts/₹
  autoDebitAccountId?: string;
  notes?: string;
  // Note: Outstanding is DERIVED, not stored. Computed from transactions.
  // Note: Min payment is DERIVED as max(settings.cardMinPaymentPct% of outstanding, 0)
};

// Loan
type Loan = {
  id: string;
  name: string;
  lender?: string;
  type: 'Home'|'Car'|'Personal'|'Education'|'Gold'|'Business'|'Mortgage'|'Credit Card EMI'|'Two-wheeler'|'Other';
  status: 'Active'|'Foreclosed'|'Closed'|'Restructured';
  last4?: string;
  sanctionedAmount: number;
  outstanding: number;      // current balance owed
  originalEmi: number;
  currentEmi: number;
  emiDay?: number;          // 1-31
  originalRate: number;     // % p.a.
  currentRate: number;
  rateType: 'Fixed'|'Floating';
  disbursementDate?: string;
  originalTenureMonths?: number;
  currentTenureRemaining?: number;
  paidFromAccountId?: string;
  processingFee?: number;
  otherCharges?: number;
  notes?: string;
};

// Loan event log (history of all changes — source of truth for amortization)
type LoanEvent = {
  id: string;
  loanId: string;
  date: string;
  eventType: 'Disbursement'|'EMI'|'Prepayment'|'RateChange'|'TenureChange'|'EmiChange'|'Foreclosure';
  amount?: number;
  fromAccountId?: string;
  principalComponent?: number;
  interestComponent?: number;
  balanceAfter?: number;
  oldValue?: number;        // for RateChange/TenureChange/EmiChange
  newValue?: number;
  strategy?: 'ReduceTenure'|'ReduceEMI';   // for prepayment
  note?: string;
  createdAt: string;
};

// Insurance
type Insurance = {
  id: string;
  name: string;
  insurer?: string;
  type: 'Health'|'Term Life'|'Endowment'|'ULIP'|'Vehicle (Car)'|'Vehicle (Bike)'|'Home'|'Travel'|'Personal Accident'|'Critical Illness'|'Other';
  status: 'Active'|'Lapsed'|'Matured'|'Surrendered';
  policyLast4?: string;
  premium: number;
  frequency: 'Yearly'|'Half-yearly'|'Quarterly'|'Monthly'|'Single';
  cover: number;
  renewalDate?: string;
  startDate?: string;
  endDate?: string;
  insuredPersonIds: string[];   // FK to People
  paidFromAccountId?: string;
  nominee?: string;
  agent?: string;
  agentContact?: string;
  notes?: string;
};

// Investment
type Investment = {
  id: string;
  name: string;
  provider?: string;
  type: 'Mutual Fund - SIP'|'Mutual Fund - Lumpsum'|'Stock'|'ETF'|'Gold'|'EPF'|'PPF'|'NPS'|'Bonds'|'Crypto'|'Other';
  status: 'Active'|'Closed'|'Matured'|'Sold';
  folio?: string;
  invested: number;
  currentValue: number;
  sipAmount?: number;
  sipDay?: number;
  paidFromAccountId?: string;
  startDate?: string;
  maturityDate?: string;
  taxBenefit?: '80C'|'80D'|'80CCD'|'HRA'|'TDS'|'GST'|'LTA'|'Section 24'|'Other'|'';
  units?: number;
  // NEW v5 additions:
  purpose: 'Retirement'|'Emergency'|'Tax Saving'|'Specific Goal'|'Wealth Building'|'Liquidity'|'Other';
  assetClass: 'Equity'|'Debt'|'Hybrid'|'Gold'|'Real Estate'|'Cash'|'Crypto'|'Other';
  notes?: string;
};

// Transaction (the core entity)
type Transaction = {
  id: string;
  type: 'income'|'expense'|'settlement'|'transfer';
  status: 'Draft'|'Settled';      // NEW v3
  source: 'Manual'|'Recurring'|'LoanEMI'|'Premium'|'Settlement';
  date: string;                   // YYYY-MM-DD
  amount: number;
  category?: string;              // from categories list
  subcategory?: string;
  fromAccountId?: string;         // required for expense (if not card), settlement, transfer
  toAccountId?: string;           // required for income, transfer
  cardId?: string;                // required for settlement; optional for expense
  loanId?: string;                // auto-set when from EMI/prepayment
  insuranceId?: string;           // auto-set when from premium payment
  recurringId?: string;           // auto-set when from recurring template
  payee?: string;
  mode?: 'NEFT'|'IMPS'|'UPI'|'RTGS'|'Cheque'|'Cash withdrawal'|'Cash deposit'|'Wallet'|'Other';
  reference?: string;
  taxFlag?: string;               // user-customizable list
  note?: string;
  draftCreatedAt: string;         // ISO
  settledAt?: string;             // ISO
};

// Recurring template
type Recurring = {
  id: string;
  label: string;                  // "Salary", "Rent", "Netflix"
  type: 'income'|'expense'|'settlement'|'transfer';
  amount: number;
  category?: string;
  frequency: 'monthly'|'weekly'|'quarterly'|'yearly';
  dayOfMonth: number;             // 1-31
  month?: number;                 // 1-12, required if yearly
  fromAccountId?: string;
  toAccountId?: string;
  cardId?: string;
  startDate?: string;
  endDate?: string;
  active: boolean;
  autoCreateDrafts: boolean;      // default true
  draftAdvanceMonths: number;     // default 3
};

// Category (user-customizable, NEW v5)
type Category = {
  id: string;
  kind: 'income'|'expense';
  name: string;
  icon?: string;                  // Lucide icon name
  color?: string;
  essential: boolean;             // NEW — used in Financial Health ratios
  defaultTaxFlag?: string;
  displayOrder: number;
};

type Subcategory = {
  id: string;
  categoryId: string;
  name: string;
  displayOrder: number;
};

// Audit log (immutable)
type AuditLog = {
  id: string;
  timestamp: string;              // ISO
  action: 'create'|'update'|'delete'|'login'|'logout'|'profileSwitch'|'export'|'import';
  entityType: string;             // 'account', 'transaction', etc.
  entityId?: string;
  beforeData?: any;               // JSON snapshot before change
  afterData?: any;                // JSON snapshot after change
  notes?: string;
};
```

### Default essential categories (Sprint 1)
**Income (all considered "essential" for cash flow purposes):** Salary · Freelance · Business · Interest · Dividend · Rental · Refund · Gift · Bonus · Other

**Expense:**
- Essential: EMI · Housing · Utilities · Groceries · Health · Insurance Premium · Education · Tax
- Non-essential: Food · Entertainment · Shopping · Travel · Subscription · Personal · Investment · Other

### Default subcategories
- Food → Restaurants · Tiffin · Cafe · Snacks
- Groceries → Vegetables · Dairy · Provisions · Online
- Transport → Fuel · Public · Cab · Parking · Service
- Utilities → Electricity · Water · Gas · Internet · Mobile · DTH
- Health → Doctor · Medicine · Lab · Hospital
- Subscription → OTT · Music · Software · Cloud · Gym

### Default tax flags (user-editable)
80C · 80D · 80CCD · HRA · TDS · GST · LTA · Section 24 · Other

---

## Section 4: Design System

### Typography
- Font: **Inter** (Google Fonts)
- Sizes: 32px display · 24px page title · 16px section · 14px body · 13px label · 12px small · 11px tiny
- Weights: 400 body · 600 emphasis · 700 headings

### Spacing scale (4px grid)
- xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48 — NEVER use other values

### Color tokens (light mode)
```
--bg:           #fafbfc
--surface:      #ffffff
--surface-2:    #f4f6f8
--border:       #e1e5ea
--border-strong:#c8cfd6
--text-primary: #1a1f36
--text-secondary:#5e6c84
--text-tertiary:#8b95a5
--primary:      #4f46e5    /* indigo */
--primary-hover:#4338ca
--success:      #15803d    /* green */
--success-soft: #dcfce7
--danger:       #dc2626    /* red */
--danger-soft:  #fee2e2
--warning:      #d97706    /* amber */
--warning-soft: #fef3c7
--info:         #0369a1    /* blue */
--info-soft:    #dbeafe
```

Dark mode: mirror with darker bgs, lighter texts.

### Border radius
sm 6px (buttons) · md 10px (inputs) · lg 14px (cards) · xl 20px (mobile modals) · full 9999px (pills)

### Shadows
- Card: `0 1px 2px rgba(0,0,0,0.04)`
- Hover: `0 4px 8px rgba(0,0,0,0.06)`
- Modal: `0 10px 25px rgba(0,0,0,0.08)`

### Lucide icon mapping (NO EMOJIS)
```
Dashboard:      layout-dashboard
Transactions:   receipt
Projection:     line-chart
Recurring:      repeat
Accounts:       building-bank (or wallet)
Cards:          credit-card
Loans:          landmark
Insurance:      shield-check
Investments:    trending-up
People:         users
Settings:       settings
Reports:        bar-chart-3
Export:         download
Financial Health: heart-pulse

Add:            plus
Edit:           pencil
Delete:         trash-2
Settle/Done:    check
Draft:          file-clock
Warning:        alert-triangle
Notifications:  bell
Income arrow:   arrow-down-left
Expense arrow:  arrow-up-right
Transfer:       arrow-right-left
Settlement:     banknote
Dropdown:       chevron-down
Search:         search
Filter:         filter
More menu:      more-horizontal
Logout:         log-out
Profile:        user-circle
Business:       building
Home:           home
```

Load via:
```html
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>
<script>lucide.createIcons();</script>
```

Use as:
```html
<i data-lucide="building-bank"></i>
```

### Navigation grouping (desktop sidebar)
- **Overview:** Dashboard · Financial Health · Reports
- **Daily:** Transactions · Projection · Recurring
- **Assets:** Accounts · Investments
- **Liabilities:** Cards · Loans
- **Protection:** Insurance
- **Setup:** People · Settings

### Mobile bottom navigation (5 tabs)
Dashboard · Transactions · Projection · Accounts · **More** (opens sheet with rest)

### Component patterns
- **Card:** 18px padding, 14px radius, 1px border, optional hover shadow
- **Button:** 40px tall, 10px radius, 10px×16px padding, primary=indigo, danger=red
- **Input:** 40px tall, 10px radius, focus ring 3px primary at 20% opacity
- **Modal (desktop):** Centered, max 560px wide, backdrop blur
- **Modal (mobile):** Slide up from bottom, full-screen
- **FAB (mobile only):** 56px circle, bottom-right, fixed, primary color

---

# PART 2 — SPRINT PROMPTS

Below are 6 sprint prompts, each ready to copy-paste into your AI coding assistant.

**Workflow per sprint:**
1. Copy the entire `PROMPT TO COPY` block
2. Paste into your AI (Claude, ChatGPT, etc.)
3. The AI produces `finance-tracker.html` (and other files where noted)
4. Save the output
5. Open in browser and test against the acceptance checklist
6. If anything fails, ask the AI to fix it
7. Move to next sprint when checklist passes

---

## SPRINT 1 — Foundation Rebuild

**Goal:** Replace the current emoji-heavy `finance-tracker.html` with a professional foundation including IndexedDB storage, Lucide icons, customizable categories, Draft/Settled transactions, and Recurring auto-drafts.

**Estimated effort for AI:** 1 large response (~3000-4000 lines of HTML/CSS/JS)

**Files produced:** `finance-tracker.html`

### PROMPT TO COPY (give this to your AI coding assistant)

````
You are building Sprint 1 of a personal finance portal called "Finance Portal". This is a single-file HTML app that runs in any browser.

## Goal
Create a complete `finance-tracker.html` with the foundation: professional design system, IndexedDB storage, customizable categories, Draft/Settled transaction workflow, Recurring auto-drafts, audit log, and Fiscal Year support. Modules built in this sprint: Dashboard (basic), Transactions (with Draft/Settled), Recurring (with auto-drafts), Accounts, Cards (basic), Loans (basic), Insurance, Investments, People, Settings (with categories editor). Reports, Financial Health, Statement view, full amortization, Auth — these come in later sprints; stub them with "Coming in Sprint X" placeholder.

## Tech requirements
- Single HTML file with embedded CSS and JS
- Lucide Icons via CDN: <script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>, NO EMOJIS anywhere
- Chart.js via CDN for charts
- Inter font from Google Fonts
- IndexedDB for storage (NOT localStorage)
- Vanilla JavaScript only — no React, no frameworks
- Must work offline once loaded
- Must be mobile-responsive (single column on <768px, bottom nav, FAB)

## Data models
Use these exact entity shapes (TypeScript-style):

[PASTE the data models from Section 3 of BUILD_GUIDE.md here — Settings, Profile, Person, Account, Card, Loan, LoanEvent, Insurance, Investment, Transaction, Recurring, Category, Subcategory, AuditLog]

Note for Sprint 1: We don't need Auth/Profile yet — operate as if a single default profile exists. Just initialize one in IndexedDB on first load.

## Design system
[PASTE Section 4 of BUILD_GUIDE.md — Typography, Spacing, Colors, Radius, Shadows, Lucide icon mapping, Component patterns]

## Module specifications for Sprint 1

### Dashboard (basic version)
- Top: page title "Dashboard", date, [Notifications bell] [+Transaction button]
- Alert strip (max 5 alerts from: card dues, loan EMIs, insurance renewals, low balance)
- 4 stat cards: Net Worth · Liquid Balance · This Month (income−expense) · Next 7 Days (projected outflow)
- "Accounts at a glance" mini-card grid (up to 8 active accounts)
- Two charts: Spending by Category (doughnut, this month, expenses only) · Income vs Expense (bar, last 6 months)
- Recent Transactions (last 6, with "View all" button)
- All stat cards clickable, navigate to relevant module

### Transactions
- Filter bar: type, month, category, account, card, tax flag, status (All/Drafts/Settled), search
- List shows status badge (Draft=yellow border-left, Settled=normal), type icon, category, note, date, from/to, signed amount
- Draft rows have a "Settle" quick button
- Add/Edit modal:
  - Pill selector for type (Income / Expense / Card Settlement / Internal Transfer)
  - Amount, date
  - Type-specific fields (see below)
  - Note, optional tax flag
  - Two save options: "Save Draft" (no balance effect) OR "Settle" (apply to balances)
  
Transaction type fields:
- Income: amount, date, category, To account, payee, reference
- Expense: amount, date, category, subcategory, Paid via (account or card), From account OR card, payee, tax flag
- Card Settlement: amount, date, From account, To card, reference
- Internal Transfer: amount, date, From account, To account, mode, reference

Behavior:
- Settling a draft converts status to Settled, applies balance effect, sets settledAt timestamp
- Editing a Settled txn: reverse old effect, apply new effect
- Deleting a Settled txn: reverse effect
- Future-dated txns default to Draft
- Past/today-dated txns default to Settled (but user can choose)

### Recurring
- Two sections: Active templates, Paused templates
- Each row: type icon, label, category badge, schedule ("Monthly on 25th"), from/to, signed amount, actions (pause/resume, edit, delete)
- Add/Edit modal: label, type, amount, category, frequency (monthly/weekly/quarterly/yearly), day of month, month (if yearly), from/to/card accounts, start/end dates
- Auto-draft engine:
  - Runs on app open + after any template change
  - For each Active template, ensure Draft transactions exist for next N months (default 3, configurable per template via draftAdvanceMonths)
  - Skip if a draft already exists for that (recurringId, date) pair
- Editing a template updates future unsettled drafts (amount, category, account)
- Pausing a template: existing future drafts get a prompt "Delete pending drafts from this template too?"
- Settling a draft from a recurring template auto-generates the NEXT draft to maintain horizon

### Accounts
[Use existing data model. Card-based UI showing name, bank, last4, current balance, type badge, status, AMB/AQB compliance indicator if minBalanceType is AMB/AQB, txn count badge. Filter pills by status. Actions: Passbook view, Quick update balance, Edit, Delete.]

For AMB/AQB calculations:
- AMB = Σ End-of-Day balances for each day in month / number of days
- AQB = same for quarter
- EOD balance computed by reconstructing from current balance and transactions
- For in-progress periods, only elapsed days used
- Show "AMB this month: ₹X / Min ₹Y" with green ✓ or red ⚠️ status

Passbook view: opens a modal with:
- Account header
- Balance Summary table (AMB current+previous month, AQB current+previous quarter) — highlight row matching account's minBalanceType
- Transaction history table with running balance

### Cards (basic — full statement view comes in Sprint 2)
- Card-based UI with: name, bank, network, last4, status, outstanding (derived), available, utilization gauge, current cycle banner with due date countdown
- Actions: Settle button (creates settlement transaction), Cycle history (last 12 cycles as table), Edit, Delete
- Settle modal: pre-fills outstanding, picks source account
- Outstanding is DERIVED: sum(expense txns on card) − sum(settlement txns on card)
- Current cycle computed from billDay and dueDay

### Loans (basic — full amortization comes in Sprint 2)
- Card UI: name, lender, type, status, outstanding, EMI, rate, EMI day, paid-from account, prepaid total, progress bar
- Actions for Active loans: Pay EMI, Prepayment, Foreclose, Edit, Delete
- Pay EMI: creates Settled Expense (category "EMI"), reduces outstanding, status → Closed when outstanding = 0
- Prepayment: creates Settled Expense + prepayment record, reduces outstanding (no recalc yet — Sprint 2)
- Foreclose: prompts for charges, creates Expense (outstanding + charges), sets outstanding = 0, status = Foreclosed
- Filter pills by status

### Insurance
- Card UI: name, insurer, type, status, premium + frequency, cover, renewal countdown, insured persons names, tenure
- Action: Pay Premium (creates Settled Expense, advances renewal date by 12 months, auto-tags 80D for Health, 80C for Term Life/Endowment)
- Insured persons: multi-select checkboxes from People list
- Filter pills by status

### Investments
- Card UI: name, provider, folio, invested, current value, gain/loss with arrow + %, type, SIP details if applicable, purpose tag, assetClass tag, taxBenefit
- Actions: Update value (quick), Edit, Delete
- NEW fields: purpose (Retirement/Emergency/Tax Saving/etc.), assetClass (Equity/Debt/Hybrid/Gold/Real Estate/Cash/Crypto/Other)
- Auto-suggest assetClass from type: Stock/ETF→Equity, Bonds/PPF/EPF/NPS→Debt, Gold/SGB→Gold, Crypto→Crypto, MF→Equity (user override)
- Auto-suggest purpose from type: EPF/PPF/NPS→Retirement, ELSS→Tax Saving

### People
- Simple list: name, relationship badge, age (from DOB), count of insurance policies they're on
- Add/Edit modal: name, relationship, dob, pan, notes
- SOFT prompt: if relationship is "Self" and dob is empty, show subtle prompt "Set DOB to unlock age-based metrics"

### Settings
Sections (in order):
1. **Profile** (just shows "Default Profile" for now — full profile management in Sprint 4)
2. **Preferences:** currency, theme (light/dark), projection horizon (days), date format, FY start month (default 4=April), retirement age, inflation rate, equity benchmark return, card min payment %
3. **Categories & Subcategories** — NEW EDITOR (see below)
4. **Tax Flags** — list editable: 80C, 80D, etc. User can add/edit/delete
5. **Backup & Restore:** Export to JSON, Import from JSON
6. **Quick Start:** Load sample data, Reset profile data
7. **About:** version, modules list

Categories editor:
- Toggle between Income and Expense
- Show categories as collapsible cards. Each has: icon (Lucide picker), name, color (color picker), essential checkbox, drag handle to reorder
- Inside each: subcategories list with same drag-to-reorder, add/edit/delete
- "+ Add category" button at bottom
- Cannot delete category if used in transactions/recurring (validation)
- Renaming a category updates all references

### Audit Log
- Append-only collection in IndexedDB
- Every Create/Update/Delete creates an entry with timestamp, action, entityType, entityId, before/after JSON snapshots
- Retention: 365 days (auto-purge older)
- Hidden from main UI for Sprint 1, but data captured for later viewing

### IndexedDB schema
Create database "FinancePortal" version 1 with object stores:
- settings (keyPath: "id", single record id="default")
- people, accounts, cards, loans, loanEvents, insurance, investments, transactions, recurring, categories, subcategories, taxFlags, auditLog
- All use keyPath "id"

On first load:
- Initialize default settings
- Initialize default categories (essential flags pre-set as in BUILD_GUIDE Section 3)
- Initialize default tax flags
- Initialize one default "Self" person? No — let user add
- Migrate from old localStorage key "finance_portal_v2" or "finance_tracker_v1" if present

### Sample data button
Should populate: 4 people (Self with DOB, Spouse, Son, Mother), 5 accounts (HDFC Salary with minBalanceType=AMB ₹25k, ICICI Savings AQB ₹10k, FD, Wallet, Cash), 2 cards, 2 loans, 4 insurance policies, 4 investments (with purpose + assetClass), 12 recurring templates, 10 past settled transactions. Set realistic Indian-context numbers.

## Acceptance criteria
- [ ] File opens in browser with no JS errors in console
- [ ] No emojis anywhere — all icons use Lucide
- [ ] Sidebar nav grouped: Overview / Daily / Assets / Liabilities / Protection / Setup
- [ ] Mobile (<768px): bottom nav with Dashboard, Transactions, Projection, Accounts, More
- [ ] More button on mobile opens sheet listing remaining pages
- [ ] All 11 module pages render without errors
- [ ] Add Transaction modal: type pill selector works, switching type reshapes form
- [ ] Save Draft creates a Draft txn with yellow border, doesn't change balance
- [ ] Settle button on a Draft converts it and updates balance
- [ ] Recurring template creates 3 months of future Drafts on save
- [ ] Settings → Categories editor allows add/edit/delete/reorder
- [ ] Categories have "essential" checkbox
- [ ] Settings has all new preferences (FY start, retirement age, inflation, equity benchmark, card min %)
- [ ] AMB shows on account cards when minBalanceType=AMB
- [ ] Passbook modal shows Balance Summary table + transaction history
- [ ] Sample data loads and Dashboard shows realistic numbers
- [ ] Export to JSON works; Import from JSON works
- [ ] Reset confirms twice before wiping
- [ ] Audit log entries written on Create/Update/Delete (verify in IndexedDB inspector)
- [ ] Light/dark mode toggle works

## Deliverable
A single `finance-tracker.html` file. Make it comprehensive — this is the foundation everything else builds on. Use professional spacing, typography, and component patterns from the design system. Test the sample data flow end-to-end.
````

### Acceptance checklist (user — verify before moving to Sprint 2)
- [ ] Open the file. No console errors.
- [ ] Click "Load sample data" in Settings. See 4 people, 5 accounts, etc.
- [ ] Dashboard shows Net Worth, charts, recent transactions.
- [ ] Add a new transaction. Try "Save Draft" — confirm balance does NOT change.
- [ ] Find the draft in Transactions list (yellow border). Click "Settle" — confirm balance updates.
- [ ] Create a Recurring template (e.g., monthly Netflix). Confirm 3 future Drafts appear in Transactions.
- [ ] Go to Settings → Categories. Add a new expense category. Mark it as essential. Reorder it.
- [ ] On an account card with minBalanceType=AMB, verify AMB number shows.
- [ ] Open Passbook on an account — verify Balance Summary + Transaction history table.
- [ ] Toggle dark mode. UI should look correct.
- [ ] Resize browser to mobile width (~400px). Confirm bottom nav appears, sidebar disappears.
- [ ] Export backup → save JSON. Reset all data. Import backup → data restored.

---

## SPRINT 2 — Loans Depth + Cards Statement View

**Goal:** Add full loan amortization (schedule view, edit rate/tenure/EMI, prepayment recalc) and Credit Card Statement view.

**Files produced:** Updated `finance-tracker.html`

### PROMPT TO COPY

````
You are extending the Finance Portal (Sprint 2). The current `finance-tracker.html` has Sprint 1 features. You need to add:

## What to build

### 1. Loan Amortization Schedule (NEW view)
For each loan, add a "Schedule" action button (Lucide icon "calendar-days"). Opens modal showing:
- Header: loan name, current outstanding, current EMI, current rate
- Full amortization table, paginated by year, expandable per month:
  | Month | Date | Opening Balance | EMI | Interest | Principal | Closing Balance | Status |
- Status: "Paid" (gray, with date) / "Planned" (white) / "Today" (highlighted)
- Past EMIs (from loanEvents): use actual recorded data
- Future EMIs: compute using current outstanding, currentRate, remaining tenure

### 2. Loan Edit — Rate / Tenure / EMI tabs
Expand the existing Edit Loan modal with tabs:
- **Basic** (existing): name, lender, type, status
- **Schedule** (link to schedule view)
- **Edit Rate**: input new rate + effective date (default today). Preview: "EMI changes from ₹X to ₹Y effective <date>". On confirm: creates loanEvent(type=RateChange, oldValue, newValue), updates loan.currentRate, recomputes schedule from effective date forward.
- **Edit Tenure**: input new tenure months. Preview: "EMI changes from ₹X to ₹Y for N months". On confirm: loanEvent(type=TenureChange), updates loan.currentTenureRemaining, recomputes.
- **Edit EMI** (for restructured loans): input new EMI. On confirm: loanEvent(type=EmiChange), updates currentEmi.

### 3. Prepayment Recalculation
Current Prepayment modal accepts amount/account/date/note. ADD: a radio choice:
- ○ Reduce tenure (keep EMI same) — DEFAULT
- ○ Reduce EMI (keep tenure same)

After confirm:
- Create Settled Expense transaction (category=EMI, note="Prepayment: <loan>")
- Append loanEvent(type=Prepayment, amount, fromAccountId, strategy="ReduceTenure"|"ReduceEMI")
- Reduce loan.outstanding by amount
- Recompute based on strategy:
  - ReduceTenure: keep currentEmi, compute new currentTenureRemaining using formula n = ln(EMI/(EMI−B·r))/ln(1+r). Round up.
  - ReduceEMI: keep currentTenureRemaining, compute new currentEmi = B·r·(1+r)^n / ((1+r)^n−1)
- Show toast: "Saved you N months / ₹X in interest" (for ReduceTenure)
- Re-render schedule

### 4. Foreclosure Improvements
Existing flow creates an Expense. ADD:
- Append loanEvent(type=Foreclosure, amount=total, fromAccountId)
- Mark loan.status = "Foreclosed"
- Schedule view shows all future months as "Cancelled" with strikethrough

### 5. Credit Card Statement View (NEW)
For each card, add a "Statement" action button (Lucide icon "file-text"). Opens modal with:
- Header: card name, last4, "Cycle: [dropdown to pick any past cycle, default most recent closed]"
- Statement Summary block:
  - Previous balance (= outstanding at cycle start)
  - Purchases (= sum of expense txns in cycle)
  - Cash advances (separate if cardId expense with category="Cash Advance" — skip for now if no such category)
  - Fees & charges (txns with category="Fees")
  - Interest (txns with category="Interest")
  - Payments (= sum of settlement txns in cycle)
  - Credits/refunds (= negative purchases, if any)
  - Statement balance = previous + purchases + fees + interest − payments − credits
  - Minimum payment due = max(settings.cardMinPaymentPct% of statement balance, ₹100)
  - Payment due date (computed from card.dueDay + days until)
- Rewards block: points earned this cycle, total points (track only if rewardType ≠ None)
- Transactions table: date, description, category, amount, status
- Comparison block: vs last cycle (% change), vs 3-month avg, top spending category
- Buttons: Print, Export to PDF, Settle this bill

### 6. Bank Statement Reconciliation (optional but useful)
On each card, add: "📎 Upload statement" — optional. Stores:
- cycle period (start/end)
- statementBalance (what bank says)
- appBalance (what we computed)
- variance (difference)
- notes
If variance > 0, show "Reconciliation needed" badge on card.

(Use IndexedDB object store "statementUploads" with fields: id, cardId, cycleStart, cycleEnd, statementBalance, appBalance, variance, notes, uploadedAt)

## Updated data models
Add to LoanEvent: include `strategy` field for prepayments.

Loan schedule should always be recomputed from event log (not stored). Function signature:
```
function generateLoanSchedule(loan) returns array of:
  { month, date, openingBalance, emi, interest, principal, closingBalance, status, eventRef? }
```

## Formulas
- EMI = P × r × (1+r)^n / ((1+r)^n − 1) where r = annualRate/12/100, n = months
- Reduce tenure: n_new = ln(EMI / (EMI − B·r)) / ln(1 + r), rounded up
- Reduce EMI: EMI_new = B · r · (1+r)^n / ((1+r)^n − 1)
- Monthly split: interest = balance × r, principal = EMI − interest

## Acceptance criteria
- [ ] Loan card has a new "Schedule" button (Lucide calendar icon)
- [ ] Clicking it opens modal with full amortization table
- [ ] Past months show "Paid" status with actual date
- [ ] Edit Loan now has tabs including Edit Rate, Edit Tenure, Edit EMI
- [ ] Edit Rate flow: enter new rate → preview shows EMI change → confirm → schedule recomputes
- [ ] Prepayment modal has reduce-tenure vs reduce-EMI radio choice
- [ ] After prepayment, schedule reflects new EMI/tenure
- [ ] Toast shows interest saved
- [ ] Foreclosure marks loan Foreclosed, schedule shows cancelled future months
- [ ] Credit Card has "Statement" button
- [ ] Statement modal shows full breakdown (previous balance, purchases, payments, statement balance, min due, due date)
- [ ] Statement transactions table populated
- [ ] Can pick any past cycle from dropdown
- [ ] No regression of Sprint 1 features
````

### Acceptance checklist (user)
- [ ] On a sample loan, open Schedule — full amortization table appears, EMIs sum to outstanding
- [ ] Use Edit Loan → Edit Rate — change rate, EMI preview shows, confirm, schedule updates
- [ ] Make a prepayment with "Reduce tenure" choice — tenure shortens, EMI stays same
- [ ] Make another prepayment with "Reduce EMI" — EMI reduces, tenure stays
- [ ] On a credit card with transactions, open Statement — see complete statement-like view
- [ ] All Sprint 1 features still work

---

## SPRINT 3 — Reports + Financial Health + Export

**Goal:** Build the Reports module, Financial Health module (24 ratios), and Export module.

**Files produced:** Updated `finance-tracker.html`

### PROMPT TO COPY

````
You are extending the Finance Portal (Sprint 3). The current `finance-tracker.html` has Sprints 1–2. You need to add three major modules.

## 1. Reports Module

Add to sidebar nav under "Overview" group. Reports menu has these reports:

### Position & Performance
- **Net Worth Statement** [As on date]
- **Income & Expense Report** [Period]
- **Cash Flow Report** [Period]
- **Ledger** (per-account) [Period + Account]
- **Day Book** [Period]

### Analytical
- **Net Worth Trend** [Period — needs daily snapshots; if not available, show monthly approximation]
- **Category-wise Spending** [Period]
- **Payee/Vendor Analysis** [Period]
- **Monthly Comparison** [N months]
- **Recurring vs One-off** [Period]
- **Tax-tag Summary** [Period] — sum of transactions per tax flag (NOT a tax computation, just sums)

### Schedules
- **Loan Amortization** [pick loan]
- **Insurance Renewal Calendar** [12 months ahead]
- **Investment Performance** [Period]
- **Recurring Templates Schedule** [Period]

### Report layout (consistent for all)
- Filter bar at top (date range with quick-pick: This Month, Last Month, This FY, Last FY, Custom)
- View mode: Summary / Detailed (toggle)
- "Compare" toggle: vs Previous Period / vs Same Period Last Year / None
- Report body
- Footer: Export (PDF/Excel/CSV), Print

### Net Worth Statement layout
- Title, as-on date
- ASSETS section:
  - Liquid Assets subsection: list active accounts (non-FD/RD), sum
  - Deposit Assets subsection: FD/RD accounts, sum
  - Investment Assets subsection: investments with currentValue
  - TOTAL ASSETS line
- LIABILITIES section:
  - Credit Card Outstanding (per card)
  - Loans Outstanding (per loan)
  - TOTAL LIABILITIES
- NET WORTH = Assets − Liabilities
- Right-aligned numbers, tabular nums, bold totals

### Income & Expense Report layout
- Filter: FY or custom period
- INCOME section: each income category with amount, sum
- EXPENSES section: each expense category with amount (grouped or flat), sum
- NET SURPLUS/DEFICIT = Income − Expenses
- Drilldown: click any category → modal showing transactions

### Cash Flow Report layout
- OPENING BALANCE (on period start)
- INFLOWS section: Salary, Freelance, Interest, etc. with totals
- OUTFLOWS section: Operating, EMIs, Card settlements, Investments, Transfers, etc.
- NET CASH FLOW
- CLOSING BALANCE

### Ledger
- Filter: Account/Card/Loan + Period
- Table: Date, Particulars, Debit, Credit, Balance (running)
- Opening balance at top, Closing at bottom

### Day Book
- Chronological list of every Settled transaction in period
- Just a table view: Date, Description, From/To, Amount

### Analytical reports
- Category-wise: pie chart + table with amounts and %
- Payee Analysis: top 20 payees by total spend, with txn count
- Monthly Comparison: stacked bar chart, 6 or 12 months side-by-side
- Recurring vs One-off: 2-bar chart per month
- Tax-tag Summary: list of tax flags with total tagged amount

### Schedules
- Loan Amortization: reuse the schedule view from Sprint 2 as a report
- Insurance Renewal Calendar: month grid showing renewals coming up
- Investment Performance: each investment with invested, current value, gain/loss, CAGR/XIRR (approximated for SIPs)
- Recurring Templates Schedule: timeline of all template occurrences in next 12 months

### Export
Each report has Export buttons:
- PDF: use browser print-to-PDF (with proper print stylesheet)
- Excel: use SheetJS (load from CDN `https://cdn.sheetjs.com/xlsx-latest/package/dist/xlsx.full.min.js`)
- CSV: generate text file

## 2. Financial Health Module

Add to sidebar nav under "Overview" group (after Dashboard).

### Page layout
- Top: Overall Score card (large number 0-100 + grade: Excellent/Healthy/Watch/Needs Attention + "12 of 24 metrics in green")
- Below: 10 category sections, each with cards for the metrics in that category

### Categories and ratios (use formulas exactly as below)

[Paste the full ratio list from §26.1 of FINANCE_PORTAL_SPEC.md — 24 ratios across categories A-J]

For each ratio card show:
- Ratio name (with help tooltip)
- Current value (large)
- Status icon (green check / yellow warning / red alert)
- Benchmark range
- "Drill-down →" link (clicking expands an explanation)

### Computation rules
Most ratios derived from existing data. For ones requiring new fields:
- Essential expenses: filter by categories where `essential === true`
- Card min payment: derived as `settings.cardMinPaymentPct% × cardOutstanding`
- Age: from People where relationship === "Self" and dob is set; if missing, show "Set DOB" instead of value
- Retirement corpus: sum of investments where purpose === "Retirement" + EPF/PPF/NPS types
- Asset allocation: group by investment.assetClass
- Recommended equity %: 110 − age
- Life cover required: 10× annual income + total loan outstanding − total liquid assets
- Wealth ratio: total investment value / annual expenses
- Stanley-Danko expected NW: age × annual income / 10

### Recommendations section
At bottom of page, generate 3-5 recommendations based on which metrics are red/yellow:
- "Reduce EMI burden — consider prepaying Car Loan" (if A2 yellow/red)
- "Increase emergency fund by ₹X to reach 6-month target" (if B1 yellow/red)
- "Your asset allocation: X% equity vs Y% recommended for age" (if G2 deviation > 5%)
- "Term life cover ₹X vs recommended ₹Y (₹Z gap)" (if F1 < 90%)

### Scoring methodology
- Each metric: Green=1.0, Yellow=0.5, Red=0.0
- Weight: Savings Rate × 2, Emergency Fund × 1.5, all others × 1
- Overall = (Σ weighted scores) / (Σ weights) × 100
- Grade bands: 80+ Excellent, 65-80 Healthy, 50-65 Watch, <50 Needs Attention

### Dashboard widget
Add to Dashboard: a "Financial Health" widget showing just the overall score number + grade + link to full page.

## 3. Export & Backup Module

Add to sidebar under "Setup" group.

### Page layout
Four sections:

**FULL BACKUP**
- Export entire profile as JSON button
- Encryption checkbox + password field (use Web Crypto AES-GCM if encrypted)
- Includes everything: people, accounts, txns, etc. Filename: `<ProfileName>_full_<YYYY-MM-DD>.json` (or `.fpb` if encrypted)

**MODULE EXPORTS**
- For each module: Excel and CSV buttons, optional date range filter
- Transactions, Accounts, Loans (with schedules), Investments, Insurance, Cards + Cycles

**TAX-TAG BUNDLE**
- Single button: "Generate FY YYYY-YY Tax Bundle"
- Generates a ZIP (using JSZip from CDN `https://cdn.jsdelivr.net/npm/jszip/dist/jszip.min.js`) containing:
  - Tax-tag summary PDF
  - Year-end Net Worth Statement PDF
  - Income & Expense Report PDF
  - Excel with detailed tagged transactions

**STATEMENTS BUNDLE**
- Generate ZIP per FY containing all card statements + bank passbooks + loan amortization schedules as PDFs

**SCHEDULED BACKUPS** (UI only — actual scheduling needs cloud, do in Sprint 4)
- Checkboxes shown but disabled with tooltip "Available with cloud sync (Sprint 4)"

### Formatting conventions
- Excel: bold headers, frozen first row, ₹ formatting, conditional red for negatives
- PDF: use browser print with print stylesheet; include header (profile name, generated date)
- CSV: UTF-8 with BOM, comma-separated, quoted strings
- Filename pattern: `{ProfileName}_{Module}_{StartDate}_to_{EndDate}.ext`

## 4. New investment fields (if not already added in Sprint 1)
- `purpose` field
- `assetClass` field
- Auto-suggest defaults

## 5. New settings (if not already added)
- retirementAge (default 60)
- inflationRate (default 6.0)
- equityBenchmarkReturn (default 12.0)
- cardMinPaymentPct (default 5.0)

## Acceptance criteria
- [ ] Reports menu has 14 reports total
- [ ] Each report renders without errors
- [ ] Net Worth Statement shows correct totals
- [ ] Income & Expense Report period filters work
- [ ] Cash Flow Report shows opening + closing balance
- [ ] Ledger has running balance column
- [ ] Each report has working Export to Excel and CSV
- [ ] Print stylesheet hides nav + makes report fit page
- [ ] Financial Health page shows 24 ratios with status colors
- [ ] Overall score number shown prominently
- [ ] Dashboard has Financial Health widget linking to full page
- [ ] If "Self" person has no DOB, age-based ratios show "Set DOB" prompt
- [ ] Export module: Full backup with encryption works
- [ ] Module-specific Excel exports include all relevant fields
- [ ] Tax-tag bundle generates ZIP
- [ ] No regression of Sprints 1–2 features
````

### Acceptance checklist (user)
- [ ] Open Reports menu — see all reports listed by category
- [ ] Open Net Worth Statement — verify Assets and Liabilities totals match Dashboard
- [ ] Open Income & Expense for current FY — verify numbers
- [ ] Open Ledger for an account — verify running balance
- [ ] Export Income & Expense to Excel — confirm file downloads and opens cleanly
- [ ] Open Financial Health page — see 24 ratio cards with green/yellow/red status
- [ ] Verify overall score number
- [ ] If "Self" person missing DOB, age-based ratios show prompt
- [ ] Dashboard now has small Financial Health widget
- [ ] Export full backup with encryption — file is .fpb
- [ ] Re-import the .fpb backup — data restores

---

## SPRINT 4 — Backend (Supabase + Auth + Multi-profile + Cloud Sync)

**Goal:** Replace IndexedDB-only with Supabase backend. Add login, signup, multi-profile management, real-time cloud sync.

**Files produced:** Updated `finance-tracker.html` + `supabase_schema.sql`

### Pre-sprint setup (user does this BEFORE running the prompt)

1. Go to https://supabase.com — create free account
2. Create new project — name "FinancePortal", choose nearest region (Mumbai/Singapore)
3. Wait for project to provision (~2 min)
4. In Project Settings → API, copy:
   - Project URL
   - `anon` public key (NOT service_role)
5. Have these ready when running this sprint

### PROMPT TO COPY

````
You are extending the Finance Portal (Sprint 4). Add Supabase backend with auth and multi-profile support.

## What to produce
1. Updated `finance-tracker.html` with Supabase integration
2. `supabase_schema.sql` file with full schema + Row-Level Security policies

## supabase_schema.sql contents

[Generate full Postgres schema with tables: profiles, categories, subcategories, people, accounts, cards, loans, loan_events, insurance, insurance_insured, investments, transactions, recurring, audit_log, statement_uploads. Add indexes for performance (profile_id, date). Add Row-Level Security policies so users only access their own profiles' data.]

The schema should map cleanly from the IndexedDB structure in Sprints 1-3. Use UUID primary keys. snake_case column names. Use Postgres types: TEXT, NUMERIC(15,2), DATE, TIMESTAMP, BOOLEAN, UUID. Add ON DELETE CASCADE where appropriate.

## finance-tracker.html updates

### Supabase client setup
- Load via `<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>`
- First-time use: ask user for SUPABASE_URL and SUPABASE_ANON_KEY (stored in IndexedDB as 'config')
- Initialize: `const supabase = supabase.createClient(URL, ANON_KEY)`

### Auth screens (NEW)
Before any module loads, check auth state:
- If not logged in → show Login screen
- If logged in but no profile selected → show Profile Picker
- If both → load main app

Auth screens (centered card, no sidebar):
1. **Login** — email, password, "Remember me", "Forgot password?" link, "New here? Sign up" link
2. **Signup** — email, password (with strength meter), full name, ToS checkbox
3. **Forgot Password** — email field, "Send reset link" button
4. **Email Verification** — "Check your email" screen with resend option

### Profile Picker (NEW)
- After login, if user has > 1 profile, show picker:
  - Cards for each profile (name, type, last accessed, "Switch to this" button)
  - "+ Create new profile" card
- If user has only 1 profile, auto-enter

### Profile Switcher (in header)
- Top-right dropdown showing active profile + list of others + "Manage profiles"
- Switching is instant — just updates `active_profile_id` in memory, all subsequent queries scoped

### Profile Management (in Settings)
- Section: list all profiles
- Each profile row: name, type, accounts count, txn count, [Switch] [Rename] [Archive] [Delete]
- "+ Create new profile" button → modal: name, type (Personal/Business/Family/Other), color, icon

### Account Settings (in Settings)
- Show current user email
- Change password
- Change email
- 2FA setup (magic link only for now)
- Logout
- Delete account (double confirm, types "DELETE", then 7-day grace period)

### Data layer migration
- Replace all `db.get/set/delete` (IndexedDB) calls with Supabase queries
- All queries scoped to `profile_id` (use the in-memory `activeProfileId`)
- Cache reads in IndexedDB for offline + speed (read-through cache)
- Writes: optimistic UI (update local first, then sync to Supabase, rollback on error)

### Real-time sync
- Subscribe to changes on every table for active profile
- When other device updates: re-render affected views
- Conflict resolution: last-write-wins with timestamp comparison

### Optimistic locking
- Every entity has an `updated_at` timestamp
- On update: query first to get current updated_at, compare to local snapshot, abort if changed
- Show conflict toast: "This was edited elsewhere. Refresh to see latest."

### Audit log
- Push every action to Supabase audit_log table (Supabase RLS scoped to profile)
- Keep local IndexedDB copy as backup

### Migration from local-only
- On first cloud login, prompt: "You have local data. Migrate to cloud?"
- If yes: bulk-insert all IndexedDB data to Supabase, then mark migrated
- If no: keep cloud empty, IndexedDB unaffected

### Connection status indicator
- Header shows: green dot "Synced" / yellow "Syncing..." / red "Offline" / gray "No cloud"
- Offline mode: read from IndexedDB, queue writes, sync when back online

## RLS policies in schema
For every table with profile_id, add:
```sql
CREATE POLICY "users see own profile data" ON {tablename}
  FOR ALL USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  );
```

For `profiles` table:
```sql
CREATE POLICY "users see own profiles" ON profiles
  FOR ALL USING (user_id = auth.uid());
```

For `audit_log`: same as other tables (profile_id scoped).

## Acceptance criteria
- [ ] supabase_schema.sql is complete, can be pasted into Supabase SQL editor and runs without errors
- [ ] After running schema, all tables visible in Supabase dashboard
- [ ] First-time visit prompts for Supabase URL + key
- [ ] Signup screen creates user (verify in Supabase Auth dashboard)
- [ ] Email verification required before first login
- [ ] After login, auto-creates default profile "Personal"
- [ ] Add data — verify it appears in Supabase tables
- [ ] Open in second browser, login → see same data
- [ ] Edit in one browser, watch it appear in the other (real-time)
- [ ] Logout works, data persists
- [ ] Create second profile → switch between them → data is isolated
- [ ] Profile management UI: rename, archive, delete with double-confirm
- [ ] Connection status indicator updates correctly
- [ ] Offline: app still works, queues changes, syncs when back online
- [ ] Conflict scenario: edit same record from two browsers → second one shows conflict warning
- [ ] No regression of Sprint 1-3 features
````

### Pre-sprint user steps
1. Create Supabase account at supabase.com
2. New project → copy URL and anon key
3. After AI produces files: open `supabase_schema.sql`, paste into Supabase SQL editor, run
4. Open new `finance-tracker.html`, enter URL + key when prompted

### Acceptance checklist (user)
- [ ] supabase_schema.sql runs cleanly
- [ ] Signup → email verification → login flow works
- [ ] Create profile 1 ("Personal"), add some data — appears in Supabase
- [ ] Create profile 2 ("Business"), add different data — isolated from profile 1
- [ ] Login on phone browser — same data appears (cloud sync working)
- [ ] Edit on laptop, see change on phone in real time
- [ ] Disconnect WiFi, make changes, reconnect → changes sync
- [ ] All previous Sprint features still work

---

## SPRINT 5 — Mobile-Distinct UI + PWA

**Goal:** Build a mobile-specific UI experience (not just responsive) + PWA install.

**Files produced:** Updated `finance-tracker.html` + `manifest.webmanifest` + `sw.js` + icon assets

### PROMPT TO COPY

````
You are extending the Finance Portal (Sprint 5). Add a mobile-distinct UI experience and PWA capabilities.

## What to produce
- Updated `finance-tracker.html`
- `manifest.webmanifest`
- `sw.js` (service worker)
- `icon-192.png`, `icon-512.png` (placeholder — SVG-generated)

## Mobile UI improvements (when viewport < 768px)

### Layout
- Remove all multi-column layouts
- Tables become card lists (label-value pairs in each card)
- Forms always single column
- Modals slide up from bottom (use CSS `transform: translateY()`)
- FAB (floating action button) always visible bottom-right for primary action per page

### Gestures
- Swipe-left on transaction row reveals Settle/Edit/Delete actions
- Pull-to-refresh on list pages (custom CSS+JS, not native browser)
- Long-press on item shows context menu
- Tap & hold on FAB shows quick-add menu (Income / Expense / Transfer)

### Bottom navigation (already present from Sprint 1)
Keep, but improve transitions: tab switch uses subtle fade-in

### Modal patterns
- Full-screen on mobile
- Sticky header with title + close X
- Sticky footer with action buttons (full-width stacked, primary on top)
- Backdrop swipe-down to close

### Touch optimizations
- All tap targets minimum 44×44px
- Spacing between tappable items minimum 8px
- Hover styles disabled (use :active instead)

### Native feel
- Bounce effect on scroll (use CSS `overscroll-behavior`)
- Tab bar hidden when keyboard open
- Use system fonts as fallback (-apple-system, BlinkMacSystemFont)

## PWA setup

### manifest.webmanifest
```json
{
  "name": "Finance Portal",
  "short_name": "Finance",
  "description": "Personal finance management",
  "start_url": "/finance-tracker.html",
  "display": "standalone",
  "background_color": "#fafbfc",
  "theme_color": "#4f46e5",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### sw.js (service worker)
- Cache-first strategy for static assets (HTML, CSS, JS, icons)
- Network-first for Supabase API calls (fall back to cache when offline)
- Background sync for queued writes when reconnecting
- Skip caching for non-GET requests

### Link in HTML
```html
<link rel="manifest" href="manifest.webmanifest">
<meta name="theme-color" content="#4f46e5">
<link rel="apple-touch-icon" href="icon-192.png">
```

### Register service worker
```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js');
}
```

### Install prompt
- Detect `beforeinstallprompt` event
- Show install button in header (mobile only) when available
- Click → trigger install dialog

## Push notifications (basic)
- Request permission on first visit (with explainer modal first)
- Notify for: card payment due tomorrow, EMI due tomorrow, insurance renewal in 7 days
- Use Notification API (no push server needed for this — local notifications scheduled via service worker)

## Icons
Generate placeholder icons using inline SVG. Create both 192×192 and 512×512 PNG files. Simple "₹" symbol on indigo background.

## Acceptance criteria
- [ ] On mobile viewport (<768px), tables convert to card lists
- [ ] Modals slide up from bottom on mobile
- [ ] Swipe-left on transaction row reveals action buttons
- [ ] FAB visible on relevant pages, opens quick-add menu
- [ ] manifest.webmanifest valid (Chrome DevTools → Application → Manifest)
- [ ] sw.js registers without errors (Chrome DevTools → Application → Service Workers)
- [ ] "Install app" prompt shown in supported browsers
- [ ] Installed app opens fullscreen without browser chrome
- [ ] Works offline: open after disconnecting WiFi, can browse cached pages
- [ ] Push notification permission can be granted; test notification shows
- [ ] All Sprint 1-4 features still work on mobile and desktop
````

### Acceptance checklist (user)
- [ ] Open on phone browser. UI looks like a mobile app, not a desktop site shrunk
- [ ] Tables show as cards, modals slide up from bottom
- [ ] Swipe a transaction row left → see action buttons
- [ ] Chrome on Android shows "Install app" — install it
- [ ] Installed app opens fullscreen (no browser UI)
- [ ] Test offline mode: turn off WiFi, refresh, app still works
- [ ] Get permission for notifications, schedule a test one
- [ ] All Sprint 1-4 features work on the installed mobile app

---

## SPRINT 6 — Polish (Optional Enhancements)

**Goal:** Investment cost basis, split transactions, receipt attachments, CSV import, reconciliation, period locking, net worth snapshots.

**Files produced:** Updated `finance-tracker.html` (+ schema additions for Sprint 4 backend)

### PROMPT TO COPY

````
You are extending the Finance Portal (Sprint 6 — Polish). Add the following enhancements.

## 1. Investment Buy/Sell with FIFO Cost Basis (optional but recommended)
Add a sub-collection on each investment: `investmentTransactions` table.

Fields: id, investmentId, date, type ('buy'|'sell'|'dividend'|'split'|'bonus'), units, pricePerUnit, totalAmount, charges, fromAccountId, notes.

UI: in Investment detail, add "Transactions" tab showing buy/sell history. Add buttons for Buy, Sell, Dividend.

On Sell: use FIFO to determine cost basis, compute realized gain/loss (short-term <1yr / long-term >1yr).

Update XIRR/CAGR to use actual cash flows from buy/sell history.

## 2. Split Transactions
Allow a single transaction to be split across multiple categories.

UI: on transaction form, click "Split" button. Adds rows for: amount, category, subcategory, note. Total of all rows must equal main amount.

Data: store as `subTransactions[]` array on the parent transaction, OR as separate child txns with parentId.

Reports: split-aware (count under each category).

## 3. Receipt / Document Attachments
Allow attaching files (photo or PDF) to: transactions, insurance policies, loans, accounts.

Storage:
- Local: store as base64 in IndexedDB (small files only, < 1MB warning)
- Cloud: upload to Supabase Storage bucket (Sprint 4 backend)

UI: paperclip icon on entity. Modal shows attachments grid, upload button.

## 4. CSV Import for Transactions
Allow importing bank statements as CSV.

UI: Settings → "Import transactions from CSV". Wizard:
1. Upload CSV
2. Map columns (Date / Description / Debit / Credit / Reference)
3. Pick destination account
4. Preview parsed transactions
5. Confirm import — all created as Settled

Auto-detect common bank formats (HDFC, ICICI, SBI) by header signature.

## 5. Reconciliation Flag
Add `reconciled: boolean` to transactions.

UI on account passbook: checkbox per transaction. "Reconcile" mode toggles a sticky toolbar showing matched amount vs expected statement balance.

## 6. Period Locking
Settings → "Lock periods": shows years/quarters, with lock toggle.

When period is locked, all transactions with date in that period become read-only (with "Locked" badge). Editing requires unlocking the period first (with confirmation).

## 7. Net Worth Snapshots
Daily background job: at midnight, snapshot total net worth.

Storage: `netWorthSnapshots` table with id, date, totalAssets, totalLiabilities, netWorth.

Use for: Net Worth Trend report (Sprint 3). Replace approximation with real history.

## Acceptance criteria
- [ ] Investment Transactions tab works for buy/sell
- [ ] Selling an investment shows realized gain/loss with ST/LT classification
- [ ] Split transactions: total of splits = parent amount enforced
- [ ] Reports show split categories correctly
- [ ] Receipt attachments work for txns and insurance
- [ ] CSV import wizard handles HDFC sample correctly
- [ ] Reconciliation checkbox saves state
- [ ] Period locking prevents edits with clear message
- [ ] Net worth snapshots created daily (verify after a day)
- [ ] Net Worth Trend chart in Reports uses real snapshot data
- [ ] No regression of Sprints 1-5 features
````

### Acceptance checklist (user)
- [ ] Sell one of your investments — verify gain/loss calculation
- [ ] Split a grocery transaction into Vegetables + Personal Care — verify reports show split
- [ ] Attach a receipt photo to a transaction
- [ ] Import an actual CSV from your bank — verify parsing
- [ ] Lock FY 2024-25 → try to edit a txn from that period → see locked message
- [ ] Wait a day, check Net Worth Trend → see new data point

---

# PART 3 — Common Issues & Tips

## If AI produces broken code
1. Test in browser, open DevTools console
2. Copy the error message back to the AI: "I got this error: [paste]. Fix it."
3. Repeat until clean

## If sprint is too big and AI runs out of context
Split into sub-tasks. E.g., for Sprint 3, do reports module first, then financial health, then export — in separate prompts.

## If AI deviates from spec
Quote the specific section back: "Per BUILD_GUIDE Section 3, the Transaction type should have field X. Add it."

## Validating data integrity after each sprint
1. Load sample data
2. Make a few changes
3. Export backup JSON
4. Reset all data
5. Import backup
6. Verify everything restored exactly

## Browser compatibility
Test in latest Chrome, Firefox, Safari. If something breaks in Safari, ask AI to "make this work in Safari too — it doesn't support [feature]".

## Cost
- Sprints 1-3, 5, 6: ₹0 (local-first, no infrastructure)
- Sprint 4 (backend): ₹0 on Supabase free tier indefinitely for personal use
- Total: free

## After completing all sprints
Host the file on:
- **Netlify Drop** (https://app.netlify.com/drop): drag-drop, get free URL in seconds
- **GitHub Pages**: requires GitHub account
- **Vercel**: similar to Netlify
- Or just open the HTML file locally — no hosting needed

---

# PART 4 — Quick Reference

## Lucide icon list (memorize for quick reference)
[Same as Section 4]

## Color tokens
[Same as Section 4]

## Data model field names
[Same as Section 3]

## Default categories
[Same as Section 3 end]

---

## END OF BUILD GUIDE

You now have everything needed to build the Finance Portal end-to-end using any AI coding assistant. Work sprint by sprint, verify each before moving on. Total estimated time: 2-6 weeks depending on iteration cycles with your AI.

For deep design context, consult the companion document **FINANCE_PORTAL_SPEC.md** which has detailed rationale, flowcharts, and business rule explanations.
