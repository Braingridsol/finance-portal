# Finance Portal v2 — How to Use

An advanced personal finance management portal. Single HTML file. Runs in any browser on phone, tablet, or computer.

---

## Open it

1. **Double-click `finance-tracker.html`** — opens in your browser.
2. **Settings → Load sample data** to see every module in action.
3. **Settings → Reset all data** when you're ready to use it with your real numbers.

---

## What's inside

**Daily**
- **Dashboard** — Net Worth, Liquid Balance, monthly summary, next-7-days outflow, alerts, account chips, charts, recent transactions
- **Transactions** — 4 types: Income · Expense · Card Settlement · Internal Transfer
- **Projection** — day-by-day cash flow forecast with low-balance warnings
- **Recurring** — define salary/EMI/rent/subscriptions once → auto-populates Projection

**Assets**
- **Accounts** — Savings, Current, Salary, FD, RD, Wallet, Cash, NRE/NRO. Passbook view per account, min-balance alerts, FD maturity tracking
- **Investments** — SIP, MF, Stocks, ETF, Gold, EPF, PPF, NPS, Bonds, Crypto. Tracks invested vs current value with gain/loss

**Liabilities**
- **Credit Cards** — billing cycle (bill gen day, due day), per-cycle history, settlement flow, utilization alerts
- **Loans** — Home, Car, Personal, Education, etc. EMI auto-payment, prepayments, foreclosure, close lifecycle

**Protection**
- **Insurance** — Health, Term Life, ULIP, Vehicle, etc. Linked to insured persons (from People), tenure, cover, premium auto-payment

**Setup**
- **People** — Family members (Self, Spouse, Children, Parents). Used by Insurance.
- **Settings** — Currency, theme, projection horizon, backup/restore, sample data

---

## The 4 Transaction Types

| Type | What it does | Affects |
|---|---|---|
| **Income** | Money coming in | Increases destination account |
| **Expense** | Money going out (from account or on card) | Decreases account OR increases card outstanding |
| **Card Settlement** | Paying your credit card bill | Decreases account, decreases card outstanding. NOT counted as expense (already counted when you swiped) |
| **Internal Transfer** | Account → Account (or Cash) | Decreases source, increases destination. NOT counted as income/expense |

Account balances **update automatically** — no need to manually adjust them after every transaction.

---

## Recurring Templates → Projection

**The killer feature:** define each repeating money movement once, then the Projection page shows your future cash flow day-by-day.

**Example templates:**
- Salary ₹75,000 → HDFC Salary, every 25th
- Home Loan EMI ₹18,500 ← HDFC Salary, every 1st
- Rent ₹25,000 ← ICICI Savings, every 1st
- Netflix ₹649 ← HDFC Card, every 15th

**Projection shows:**
- Timeline of every projected item (next 30/60/90/180/365 days)
- Per-account running balance — **⚠️ warning** when any account drops below min balance
- Expected balance at end of period for each account
- Chart of total liquid balance over time

This is real cash-flow forecasting — common in business finance, rare in personal apps.

---

## Credit Card billing cycles

Each card has a **bill generation day** and a **due day**. The portal:
- Auto-creates the current cycle based on today's date
- Calculates outstanding = card expenses − settlements
- Warns when due in ≤7 days
- Tracks past 12 cycles (Billed / Settled / Overdue / Pending)

When you pay your card, use the **💵 Settle** button on the card → records a Settlement transaction → reduces account balance AND card outstanding in one shot.

---

## Loan lifecycle

- **Add loan** with sanctioned amount, EMI, rate, tenure, linked account
- **💸 Pay EMI** records the EMI, reduces account, reduces outstanding
- **⬆️ Prepayment** for any extra payment toward principal — full history kept
- **🔚 Foreclose** when paying off early — captures foreclosure charges, marks Foreclosed
- **Close** automatically when outstanding hits zero

---

## Tax tagging

When entering an expense, you can tag it with: **80C, 80D, 80CCD, HRA, TDS, GST, LTA, Section 24**.

Filter the Transactions page by tax tag to get a year-end view for ITR filing.

---

## Mobile experience

- **Bottom navigation** with: Dashboard · Transactions · Projection · Accounts · **⋯ More**
- "More" opens a sheet with all other sections
- **Floating + button** to quickly add transactions
- All forms are touch-friendly
- **Add to Home Screen** from your browser menu — installs like a real app

---

## Backup (essential)

Your data lives in your browser. Backup regularly.

**Backup:** Settings → "⬇️ Export backup" → downloads a .json file. Save to Google Drive / Dropbox / email to yourself.

**Restore on new device:** Open the HTML file → Settings → "⬆️ Import backup" → select the file.

**Recommended cadence:** Once a week, or after entering a lot of data.

---

## Cloud sync (later)

When you want your data to sync across devices, ask in a new chat: **"add Firebase cloud sync to my finance portal"** — I'll guide you through the free Firebase setup (5–10 mins) and add ~20 lines of code that swap localStorage for cloud storage.

---

## Hosting it on the internet

Want a real URL like `myfinance.netlify.app`?
- **Netlify Drop** — drag the HTML file onto https://app.netlify.com/drop → get a free URL in seconds

---

## Phase 2 (when you're ready)

I'll add on request:
- **Reports & Excel export** — monthly/yearly P&L, category drilldown, ITR summary as .xlsx
- **Receipt/document attachments** — photos of bills, policy docs
- **Per-card statement upload** — paste/import statement and reconcile
- **Reports for individual people** — expenses split by family member
- **Cloud sync** (Firebase or Supabase)
- **Multi-currency** for NRI accounts
- **PWA offline-first** with proper install banner

Just tell me what you want next.

---

## Common questions

**Q: Is my data private?** Yes. Everything stays in your browser. No servers, no tracking.

**Q: Can I change currency?** Settings → Currency.

**Q: Two people sharing?** Each browser has its own data. Cloud sync (Phase 2) solves this.

**Q: What if I make a mistake on a transaction?** Edit it — balance adjusts automatically. Delete it — balance reverses automatically.

**Q: Can I import from my bank's CSV?** Not yet — say "add CSV import" if you need it.

---

## Need help / want changes?

Open a new chat and describe what you want. The portal is one file — changes are quick.
