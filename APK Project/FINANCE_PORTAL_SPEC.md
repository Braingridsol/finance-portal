# Finance Portal — Master Specification (v5)

> **Single source of truth.** All design, data, rules, dropdowns, flows live here. Code never gets touched until the spec is updated and approved.
>
> **Revision history:**
> - v1 — Initial advanced portal
> - v2 — AMB/AQB tracking
> - v3 — Draft/Settled workflow, multi-profile auth, professional UI (Lucide icons), customizable categories, full loan amortization, adaptive web/mobile, backend (Supabase), security spec
> - v4 — Credit Card Statement view, Reports module, Data Export module, gap analysis
> - **v5 (current)** — Scope locked per user decisions. Removed: double-entry accounting, TDS, Receivables/Payables, India statutory compliance. Reports adjusted to single-entry semantics (Net Worth Statement, Income & Expense Report — not "Balance Sheet" / "P&L").

---

## 0. Decisions Log (LOCKED)

Items the user has **explicitly approved or declined**. Once here, do not re-propose without asking.

### 0.1 ✅ APPROVED for build

| # | Decision | Source |
|---|---|---|
| D1 | Draft → Settled transaction workflow | v3 |
| D2 | Multi-profile architecture (Tally-style) | v3 |
| D3 | Lucide icons, no emojis | v3 |
| D4 | Professional UI redesign | v3 |
| D5 | Customizable categories/subcategories in Settings | v3 |
| D6 | Loan full amortization + Edit (rate/tenure/EMI) + prepayment recalc | v3 |
| D7 | Recurring auto-generates Draft transactions | v3 |
| D8 | Projection: remove balance forecast chart | v3 |
| D9 | Supabase backend with auth + RLS | v3 |
| D10 | Adaptive web/mobile (not just responsive) | v3 |
| D11 | Security spec (HTTPS, RLS, hashed pw, encrypted cache, no full account numbers) | v3 |
| D12 | Credit Card Statement view (inside Cards module) | v4 |
| D13 | Reports module — Net Worth Statement, Income & Expense, Cash Flow, Ledger, Day Book | v4 (revised v5) |
| D14 | Data Export & Backup module | v4 |
| D15 | AMB / AQB tracking on accounts | v2 |
| D16 | Financial Health module with 24 ratios (§26) — Option A locked | v5 |
| D17 | Categories carry `essential: boolean` flag | v5 |
| D18 | Card min payment auto-derived as 5% of outstanding (RBI standard) | v5 |
| D19 | Investments carry `purpose` and `assetClass` fields (auto-suggested) | v5 |
| D20 | Settings adds: retirementAge, inflationRate, equityBenchmarkReturn, cardMinPaymentPct | v5 |
| D21 | DOB on "Self" person — soft-required (Financial Health prompts but doesn't block) | v5 |

### 0.2 ❌ DECLINED — do not build

| # | Decision | Reason / Implication |
|---|---|---|
| X1 | **Double-entry bookkeeping & Chart of Accounts** | User says not needed. Reports will be single-entry — i.e., we'll show Net Worth (Assets − Liabilities) but NOT a formal Trial Balance or accounting-grade Balance Sheet. Reports are renamed to honest labels: "Net Worth Statement", "Income & Expense Report". |
| X2 | **TDS handling** on income transactions | User says not needed. Income recorded as net amount received. Tax reports will not separate gross vs TDS. |
| X3 | **Receivables module** (money owed TO user) | User says not needed. If user wants to track an informal loan to a friend, they'll just use a normal transaction with a note. |
| X4 | **Payables module** (money user owes informally) | Same as above. |
| X5 | **India statutory compliance** (GST, advance tax dates, Form 26AS / AIS reconciliation, HUF profile, Schedule FA, Section 80EE/80EEA, etc.) | User says not needed. Tax flags (80C/80D etc.) remain as a simple tagging mechanism for personal awareness, not for compliance/reporting integration. |
| X6 | **Trial Balance report** | Implied by X1 — no double-entry means Trial Balance is meaningless. Removed from Reports list. |

### 0.3 ⏸️ DEFERRED — discuss later

(None yet — open questions in §24 still pending answers.)

---

---

## Table of Contents

1. [What I Understood From Your Latest Requirements](#1-what-i-understood-from-your-latest-requirements)
2. [Design Principles (updated)](#2-design-principles-updated)
3. [System Architecture (v3)](#3-system-architecture-v3)
4. [Web vs Mobile UI Strategy](#4-web-vs-mobile-ui-strategy)
5. [Module Specifications](#5-module-specifications)
   - 5.0 **Auth & Profiles** (NEW)
   - 5.1 People
   - 5.2 Accounts
   - 5.3 Credit Cards
   - 5.4 Loans (with full amortization)
   - 5.5 Insurance
   - 5.6 Investments
   - 5.7 Transactions (Draft / Settled workflow)
   - 5.8 Recurring Templates (auto-generates drafts)
   - 5.9 Projection (simplified)
   - 5.10 Dashboard
   - 5.11 Settings (with Categories editor + Profile management)
6. [Cross-Module Business Rules](#6-cross-module-business-rules)
7. [Calculation Rules (incl. Amortization)](#7-calculation-rules-incl-amortization)
8. [Flow Charts](#8-flow-charts)
9. [UI / UX Conventions (PROFESSIONAL)](#9-ui--ux-conventions-professional)
10. [Backend & Database Setup](#10-backend--database-setup)
11. [Security Specification](#11-security-specification)
12. [Validation Rules Master List](#12-validation-rules-master-list)
13. [Status of Implementation](#13-status-of-implementation)
14. [Phase Roadmap](#14-phase-roadmap)
15. [Open Questions for You](#15-open-questions-for-you)
16. [Glossary](#16-glossary)

---

## 1. What I Understood From Your Latest Requirements

You gave me 11 changes. Here's my interpretation of each — please confirm or correct:

### 1.1 Customizable categories and subcategories
Expense category list, income category list, AND subcategory list must be **user-editable** through Settings. No hard-coded master list. User can add new ones, rename, delete (if not in use), reorder.

### 1.2 No emojis — real icons
The current emoji-based UI is replaced with a professional icon system. SVG icons, consistent style, all the same visual weight. I'll use **Lucide Icons** (open-source, MIT, ~1500 icons, professional-grade, used by Notion, Vercel, etc.).

### 1.3 Professional UI/UX
Move from "good enough" to **looking like a real fintech product**. This means:
- Real icons (not emojis)
- Consistent spacing system (4px / 8px / 16px / 24px / 32px grid)
- Typography hierarchy (proper heading sizes, weights)
- Color system with semantic tokens
- Hover states, focus rings, subtle animations
- Empty states with illustrations
- Skeleton loaders during data load
- Proper data density (not too sparse, not too cramped)
- Card shadows, borders, and depth

### 1.4 Draft → Settled transaction workflow
**The biggest workflow change.** Every transaction now has a **status**:
- **Draft** — planned but hasn't actually happened yet. Does NOT affect account balances. DOES appear in Projection.
- **Settled** — actually happened. DOES affect balances. The truth of your finances.

**Flow:**
- Add transaction → choose to save as Draft OR Settle immediately
- Future-dated transactions default to Draft
- Past-dated transactions default to Settled
- A Draft has a **"Settle" button** that converts it to Settled (and applies balance changes)
- Drafts can be edited or deleted without affecting balances

Add-Transaction popup now has all 4 types AS BEFORE (Income / Expense / Card Settlement / Internal Transfer) PLUS the Draft/Settle choice.

### 1.5 Recurring → auto-generated Drafts
When you create a Recurring Template, the system **automatically creates Draft transactions for the next N months** (configurable, default 3 months ahead). These drafts:
- Appear in the Transactions list (under a "Drafts" filter or distinguished by status badge)
- Appear in Projection
- Are not real until you Settle them
- When you Settle on the actual date → they become real and affect balances

This makes Recurring + Projection + Transactions all work together as one coherent system.

### 1.6 Projection cleanup
Remove the "Account balance forecast" line chart. Keep:
- Stat cards (Starting / Inflow / Outflow / Expected End)
- Per-account expected end-of-period grid
- Timeline table

### 1.7 Loans — full amortization & lifecycle edits
Loans need:
- **Full amortization schedule** — month-by-month: Month / EMI / Principal / Interest / Balance
- **Prepayment recalculation** — if you pay ₹1L today, the schedule from today onwards recomputes (user chooses: reduce EMI OR reduce tenure)
- **Edit tenure** — change tenure mid-loan (e.g., extend by 24 months → EMI recalculates)
- **Edit interest rate** — for floating-rate loans, when bank changes the rate, you enter the new rate → EMI recalculates from that point
- **Edit EMI** — for restructured loans
- All edits **preserve history** — past EMIs/prepayments stay intact

### 1.8 User login + multi-profile (Tally-style)
A user has an account (email + password). After login, the user can manage **multiple profiles** (like Tally's "Companies"):
- Personal Finance
- Business Finance
- Parents' Finance
- Wife's Finance

Each profile is a **completely isolated dataset** — own accounts, cards, loans, etc. User switches between profiles via a dropdown. One login, multiple namespaces.

### 1.9 Free database recommendation
You want a free, effective database. My analysis is in Section 10 — short answer: **Supabase** (free tier: 500MB DB, 50K monthly active users, built-in auth, Postgres, real-time, easy setup). Fallback: Firebase.

### 1.10 Adaptive Web vs Mobile UI
Not just "mobile responsive" — actually **two different UIs** that share data:
- **Web UI**: rich, dense, multi-column, sidebar navigation, hover-heavy
- **Mobile UI**: simplified, single-column, bottom navigation, swipe gestures, native-app feel, larger touch targets, full-screen modals

Same codebase, different layouts triggered by viewport size + device detection. UI can show/hide features per device.

### 1.11 Security is paramount
Section 11 is dedicated to this. Highlights:
- Strong password hashing (bcrypt via Supabase Auth)
- All data encrypted at rest (Supabase Postgres encrypted by default)
- HTTPS everywhere
- Row-Level Security (RLS) — your data isolated from other users
- No financial account numbers stored (only last 4 digits)
- Optional 2FA via email magic link
- Session timeout
- Audit log of sensitive actions
- Local cache encrypted (Web Crypto API) when "Remember me" is used

---

## 2. Design Principles (updated)

| # | Principle | What it means in practice |
|---|---|---|
| P1 | **Every rupee has an account** | No transaction is "in the air" — must specify source and/or destination |
| P2 | **Balances are derived, not entered** | After setup, balances move only via Settled transactions |
| P3 | **Type semantics matter** | Settlement ≠ Expense, Transfer ≠ Income/Expense — no double counting |
| P4 | **Plans vs reality** *(NEW)* | Draft = plan (affects Projection only). Settled = reality (affects Balance) |
| P5 | **Forward visibility** | The system shows what's coming, not just what happened |
| P6 | **No destructive deletes** | Closed accounts preserved. Drafts can be deleted freely; Settled are protected |
| P7 | **Multi-tenant by default** *(NEW)* | One user = many profiles. Switching profile is instant. |
| P8 | **Security non-negotiable** *(NEW)* | Hashed passwords, RLS, HTTPS, encrypted cache, never store full account numbers |
| P9 | **Adaptive UI** *(NEW)* | Web and mobile are different products sharing one brain |
| P10 | **Professional aesthetics** *(NEW)* | Real icons, typography hierarchy, consistent spacing, no emojis in production UI |
| P11 | **Cloud-first, offline-tolerant** *(NEW)* | Cloud is the source of truth. Local cache makes it fast & offline-capable. |
| P12 | **Customization where it matters** *(NEW)* | Categories, subcategories, currency, projection horizon all user-editable |

---

## 3. System Architecture (v3)

### 3.1 High-level

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT (Browser)                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Web UI Layout              │   Mobile UI Layout              │  │
│  │  (≥1024px desktop)          │   (<768px phone)                │  │
│  │  Sidebar + Main + Density   │   Bottom Nav + Single Column    │  │
│  └────────────────┬──────────────────────────┬───────────────────┘  │
│                   │                          │                      │
│                   └────────┬─────────────────┘                      │
│                            │                                        │
│  ┌─────────────────────────▼──────────────────────────────────────┐ │
│  │              Shared Business Logic Layer                       │ │
│  │  Modules · Engines · Validators · Calculators                  │ │
│  └─────────────────────────┬──────────────────────────────────────┘ │
│                            │                                        │
│  ┌─────────────────────────▼──────────────────────────────────────┐ │
│  │              Profile-aware State Layer                         │ │
│  │  Active profile id · Switches namespace on login/profile change│ │
│  └─────────────────────────┬──────────────────────────────────────┘ │
│                            │                                        │
│  ┌─────────────────────────▼──────────────────────────────────────┐ │
│  │           Local Cache (encrypted IndexedDB)                    │ │
│  │  Read-through cache for offline & speed                        │ │
│  └─────────────────────────┬──────────────────────────────────────┘ │
└────────────────────────────┼────────────────────────────────────────┘
                             │ HTTPS + JWT
┌────────────────────────────▼────────────────────────────────────────┐
│                    BACKEND (Supabase)                               │
│  ┌───────────────────────┐  ┌────────────────────────────────────┐  │
│  │  Auth Service         │  │  Postgres Database                 │  │
│  │  · Email + password   │  │  · users, profiles, accounts,      │  │
│  │  · Magic link 2FA     │  │    cards, loans, insurance,        │  │
│  │  · JWT tokens         │  │    investments, transactions,      │  │
│  │  · Sessions           │  │    recurring, prepayments,         │  │
│  │                       │  │    categories, subcategories       │  │
│  │                       │  │  · Row-Level Security (RLS)        │  │
│  └───────────────────────┘  └────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  Real-time subscriptions (websocket) — for multi-device sync    ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Logical Data Hierarchy

```
USER (login)
  ├── PROFILE 1 "Personal Finance"
  │     ├── settings (currency, theme, etc.)
  │     ├── categories (custom)
  │     ├── people
  │     ├── accounts
  │     ├── cards
  │     ├── loans
  │     ├── insurance
  │     ├── investments
  │     ├── transactions (Draft + Settled)
  │     ├── recurring
  │     └── prepayments
  ├── PROFILE 2 "Business Finance"
  │     └── (same structure, separate data)
  └── PROFILE 3 "Wife's Finance"
        └── (same structure, separate data)
```

User selects active profile on login. All API queries are scoped to `profile_id`.

---

## 4. Web vs Mobile UI Strategy

### 4.1 Breakpoints

| Device | Viewport | Layout |
|---|---|---|
| **Mobile** | < 768px | Single column, bottom nav, full-screen modals, swipe gestures |
| **Tablet** | 768–1023px | Hybrid — collapsible sidebar + main, 2-column where useful |
| **Desktop** | ≥ 1024px | Full sidebar + main + density (cards in grid) |

### 4.2 Behavior differences

| Aspect | Web (Desktop) | Mobile |
|---|---|---|
| Navigation | Sidebar (always visible) with grouped sections | Bottom nav (4 primary + More) |
| Tables | Full table with all columns | Card list (label-value pairs) |
| Modals | Centered, ≤560px wide, backdrop | Full-screen, slide up from bottom |
| Forms | Multi-column where appropriate | Always single column |
| Actions | Hover reveals secondary actions | Always visible icons, swipe for delete |
| FAB | No (use header buttons) | Yes (bottom-right floating + button) |
| Transitions | Subtle fades | Native-like slide/push |
| Charts | Full-size, interactive | Simplified, may collapse to summary |
| Density | Higher (more visible at once) | Lower (touch-friendly spacing) |

### 4.3 Examples — same data, different presentation

**Account card on web:**
```
┌─────────────────────────────────────────────────────────────┐
│ [icon] HDFC Salary              [📖][💰][✏️][🗑️]            │
│        HDFC Bank · ••4521                                   │
│                                                             │
│  CURRENT BALANCE        AMB THIS MONTH                      │
│  ₹1,28,400              ₹95,200 ✓                           │
│                         18 of 31 days · need ₹25k           │
│                                                             │
│  [Salary] [3.5% p.a.] [12 txns]      [Above by ₹70,200]    │
└─────────────────────────────────────────────────────────────┘
```

**Same account on mobile:**
```
┌──────────────────────────────────┐
│ [icon] HDFC Salary           [>] │
│ HDFC Bank · ••4521               │
│                                  │
│ ₹1,28,400                        │
│                                  │
│ AMB ✓ ₹95,200                    │
│ Above min by ₹70,200             │
└──────────────────────────────────┘
                              (tap [>] for full detail screen)
```

### 4.4 Implementation strategy
- **Single codebase**, two layout systems
- **CSS Grid + Flexbox** with media queries as primary mechanism
- **JS device detection** as enhancement (e.g., to enable swipe gestures only on touch)
- **PWA manifest** so the app can be "installed" to home screen and behaves like a native app on mobile

---

## 5. Module Specifications

### 5.0 Auth & Profiles (NEW)

**Purpose:** User authentication + multiple data namespaces (Tally-style companies).

#### 5.0.1 User entity

| Field | Type | Required | Notes |
|---|---|---|---|
| id | UUID | yes | Provided by Supabase Auth |
| email | string | yes | Unique, validated |
| password_hash | string | yes | bcrypt, managed by Supabase Auth (never seen by app) |
| full_name | string | yes | Display name |
| phone | string | no | Optional, for 2FA |
| created_at | timestamp | yes | Auto |
| last_login | timestamp | no | Updated on login |
| email_verified | boolean | yes | Email verification status |
| twofa_enabled | boolean | yes | Default false |

#### 5.0.2 Profile entity

| Field | Type | Required | Notes |
|---|---|---|---|
| id | UUID | yes | PK |
| user_id | UUID (FK → users) | yes | Owner |
| name | string | yes | "Personal", "Business", etc. |
| type | enum | yes | Personal · Business · Family · Other |
| currency | string | yes | Default '₹' |
| color | string | no | UI accent color per profile |
| icon | string | no | Icon name for this profile |
| created_at | timestamp | yes | Auto |
| is_default | boolean | yes | One per user |
| archived | boolean | yes | Default false |

#### 5.0.3 Screens

| Screen | Purpose |
|---|---|
| **Login** | Email + password, "Remember me", "Forgot password" link |
| **Signup** | Email, password (with strength meter), full name, terms accept |
| **Forgot password** | Email → magic reset link |
| **Profile picker** | After login, choose which profile to enter (if more than 1) |
| **Profile switcher** | Dropdown in top-right header — switch active profile any time |
| **Profile management** | Settings → list all profiles, create new, rename, archive, delete |
| **2FA setup** | Optional — enable magic-link 2FA |
| **Account settings** | Change password, change email, logout, delete account |

#### 5.0.4 Business Rules

- R1. Email must be verified before first login.
- R2. Password minimum: 8 chars, must contain at least one letter and one number. Recommended: 12+ chars with symbols (strength meter shows estimated entropy).
- R3. Failed login: rate-limited after 5 attempts in 15 minutes.
- R4. Session: JWT valid for 24 hours; refresh token valid for 7 days. "Remember me" extends refresh to 30 days.
- R5. **Every API call** carries the JWT; Supabase RLS ensures user can only see their own profiles' data.
- R6. Switching profile is **instant** (no relogin) — just updates the `active_profile_id` in local state, all subsequent queries scoped to that ID.
- R7. Default profile auto-created on signup ("Personal").
- R8. Deleting a profile requires double confirmation + typing the profile name. All data is permanently deleted.
- R9. Archiving a profile hides it from the picker but data is preserved.
- R10. Deleting a user account requires email confirmation + waits 7 days (soft delete with grace period).

#### 5.0.5 Profile-scoped queries

Every table (accounts, transactions, etc.) has a `profile_id` column. Supabase RLS policy:
```sql
CREATE POLICY "Users can only access their own profile data"
  ON accounts FOR ALL
  USING (
    profile_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  );
```

---

### 5.1 People

(Same as v2 — no changes.)

---

### 5.2 Accounts

(Same as v2 with AMB/AQB — no changes.)

---

### 5.3 Credit Cards

(Same as v2 with billing cycles — no changes.)

---

### 5.4 Loans (with FULL Amortization)

**MAJOR REVISION** — now includes proper amortization schedule and edit lifecycle.

#### 5.4.1 Data model (extended)

| Field | Type | Required | Notes |
|---|---|---|---|
| id | UUID | yes | PK |
| name | string | yes | "HDFC Home Loan" |
| lender | string | no | "HDFC", "SBI" |
| type | enum | yes | See dropdown |
| status | enum | yes | Active · Foreclosed · Closed · Restructured |
| last4 | string | no | Loan account # tail |
| sanctionedAmount | number | yes | Original principal |
| outstanding | number | yes | Current balance (derived from schedule) |
| originalEmi | number | yes | EMI at time of disbursement |
| currentEmi | number | yes | EMI as of now (may differ after prepayment/rate change) |
| emiDay | number 1–31 | no | Auto-debit day |
| originalRate | number | yes | Interest rate at disbursement |
| currentRate | number | yes | Current rate (after changes) |
| rateType | enum | yes | Fixed · Floating |
| disbursementDate | date | yes | When loan started |
| originalTenureMonths | number | yes | Tenure at disbursement |
| currentTenureRemaining | number | yes | Months still to go |
| paidFromAccountId | UUID (ref) | no | Default account |
| processingFee | number | no | One-time |
| otherCharges | number | no | — |
| notes | text | no | — |

#### 5.4.2 Loan event log (NEW)

A separate table tracks every change to the loan:

| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| loan_id | UUID (FK) | Which loan |
| date | date | When event happened |
| event_type | enum | EMI · Prepayment · RateChange · TenureChange · EmiChange · Disbursement · Foreclosure |
| amount | number | For payments |
| from_account_id | UUID | For payments |
| principal_component | number | For EMIs (computed) |
| interest_component | number | For EMIs (computed) |
| balance_after | number | Outstanding after this event |
| old_value | number | For changes (old rate/EMI/tenure) |
| new_value | number | For changes |
| note | text | — |

This event log is the **source of truth** for the loan. The schedule and outstanding are recomputed from it.

#### 5.4.3 Amortization Schedule

For any loan at any point in time, the schedule is:

| Month | Date | Opening Balance | EMI | Interest | Principal | Closing Balance |
|---|---|---|---|---|---|---|
| 1 | Jun '22 | ₹35,00,000 | ₹18,500 | ₹24,791 | (−₹6,291)* | ... |

*Note: For interest-heavy loans, principal can be negative in early months — fine, the formula corrects over time.

**Schedule is recomputed when:**
- Loan added (full schedule from disbursement to end)
- EMI paid (just appended to history)
- **Prepayment** (schedule recomputed from prepayment date forward, with user's choice: reduce tenure OR reduce EMI)
- **Rate change** (schedule recomputed with new rate)
- **Tenure change** (schedule recomputed with new tenure)

#### 5.4.4 New screens

- **Schedule view (📅)**: Full amortization table — paginated by year, expandable per month. Shows Past (gray, settled) and Future (white, planned).
- **Edit Loan modal**: Now has tabs:
  - **Basic** — name, lender, type, status
  - **Schedule** — view current schedule
  - **Edit Rate** — change interest rate from a date forward + auto-recalculate
  - **Edit Tenure** — extend or shorten + auto-recalculate
  - **Edit EMI** — for restructured loans
- **Prepayment modal (existing)** + asks "After this prepayment, do you want to: (a) Reduce tenure (same EMI) (b) Reduce EMI (same tenure)"

#### 5.4.5 Edit Rate flow

```
User opens Edit Loan → Rate tab
↓
Sees current rate (e.g., 8.5%)
Inputs new rate (e.g., 9.25%) + effective date (default: today)
↓
System calculates new EMI for remaining tenure
↓
Shows preview: "EMI changes from ₹18,500 to ₹19,140 effective from <date>"
↓
User confirms → event_log entry created → schedule recomputed
```

#### 5.4.6 Edit Tenure flow

```
User opens Edit Loan → Tenure tab
↓
Sees: current remaining tenure (e.g., 216 months)
Inputs: new tenure (e.g., 240 months — extending by 2 years)
↓
System recalculates EMI for new tenure
↓
Shows preview: "EMI changes from ₹18,500 to ₹17,200 (tenure 240 months)"
↓
User confirms → event_log entry → schedule recomputed
```

#### 5.4.7 Prepayment with recalculation

```
User clicks ⬆️ Prepayment
↓
Enters: amount, account, date, note
↓
Chooses: (a) Reduce tenure  (b) Reduce EMI
↓
System:
  - Reduces outstanding by prepayment amount
  - If (a) Reduce tenure:
      keep EMI same → recompute remaining months
      → "Saves you 14 months and ₹2,58,000 in interest"
  - If (b) Reduce EMI:
      keep tenure same → recompute new EMI
      → "Your new EMI is ₹17,350 (saved ₹1,150/month)"
↓
Confirms → Expense txn + event log entry → schedule recomputed
```

#### 5.4.8 Business rules (updated)

- R1. Schedule is always recomputed from the event log — never stored as a static table.
- R2. Rate changes apply forward only — past EMIs are not retroactively recalculated.
- R3. Prepayment reduces outstanding immediately; schedule reflects the chosen recalculation strategy.
- R4. When all EMIs paid (outstanding = 0), status → "Closed" automatically.
- R5. Foreclosure marks loan "Foreclosed" but keeps schedule visible for reference.
- R6. Edits to loan basics (name, lender) don't trigger recalculation. Only Rate/Tenure/EMI/Prepayment do.

---

### 5.5 Insurance

(Same as v2 — no changes.)

---

### 5.6 Investments

(Same as v2 — no changes.)

---

### 5.7 Transactions (Draft/Settled — MAJOR REVISION)

**MAJOR WORKFLOW CHANGE.** Transactions now have a status: `Draft` or `Settled`.

#### 5.7.1 Data model (extended)

All v2 fields PLUS:

| Field | Type | Required | Notes |
|---|---|---|---|
| **status** | enum | yes | `Draft` or `Settled` |
| source | enum | yes | `Manual` · `Recurring` · `LoanEMI` · `Premium` · `Settlement` |
| recurringId | UUID (ref) | no | If generated from a Recurring template |
| settledAt | timestamp | no | When draft was converted to settled |
| draftCreatedAt | timestamp | yes | When initially created |

#### 5.7.2 The 4 types stay the same

(Income, Expense, Card Settlement, Internal Transfer — semantics unchanged.)

#### 5.7.3 Draft vs Settled behavior

| | Draft | Settled |
|---|---|---|
| Affects account balance | ❌ No | ✅ Yes |
| Counts in monthly stats | ❌ No | ✅ Yes |
| Counts in Net Worth | ❌ No | ✅ Yes |
| Shows in Projection | ✅ Yes | ❌ No (it's already real, not a projection) |
| Shows in Transactions list | ✅ Yes (with badge) | ✅ Yes |
| Editable | ✅ Yes | ✅ Yes (with confirmation) |
| Deletable freely | ✅ Yes | Requires confirm (reverses balance) |
| Has "Settle" button | ✅ Yes | ❌ No |
| Has "Unsettle" button | ❌ No | ✅ Yes (reverts to draft, reverses balance) |

#### 5.7.4 Default status on creation

| Created via | Status default |
|---|---|
| Manual add, future date | Draft |
| Manual add, past/today date | User chooses (default: Settled) |
| Recurring template (auto-generated) | Draft |
| Pay EMI button | Settled (it's an action you just did) |
| Pay Premium button | Settled |
| Settle Card button | Settled |

#### 5.7.5 Add Transaction popup (revised)

```
┌─────────────────────────────────────┐
│ Add Transaction              [✕]    │
├─────────────────────────────────────┤
│ Type                                │
│  [Income] [Expense] [Settle] [Xfer] │
│                                     │
│ Amount         Date                 │
│  [        ]    [          ]         │
│                                     │
│ Category       Subcategory          │
│  [        v]   [           v]       │
│                                     │
│ From Account                        │
│  [HDFC Salary           v]          │
│                                     │
│ Payee / Note                        │
│  [                            ]     │
│                                     │
│ Tax Flag (optional)                 │
│  [— None —              v]          │
├─────────────────────────────────────┤
│  ○ Save as Draft (plan for later)   │
│  ● Settle Now (apply to balance)    │
├─────────────────────────────────────┤
│ [Cancel]       [Save Draft] [Settle]│
└─────────────────────────────────────┘
```

The two primary actions are explicit:
- **Save Draft** — plan only, no balance change
- **Settle** — affects balance immediately

#### 5.7.6 Transaction list view (revised)

- New filter: **All / Settled / Drafts**
- Draft rows have a yellow border-left + "Draft" badge + "Settle" quick-action button
- Settled rows show normally

#### 5.7.7 Settling a draft (later)

User goes to Transactions, finds the draft, clicks Settle button:
- A small modal appears: confirm amount, date (may have changed from plan), account
- On confirm:
  - Status → Settled
  - settledAt = now
  - Balance updated
  - If draft was generated from Recurring, the next draft for that recurring template auto-generated

#### 5.7.8 Cross-impact with Projection

- Projection now shows **Drafts + Recurring expanded events** (Recurring events that haven't been auto-drafted yet)
- Projection NO LONGER auto-expands recurring on the fly — it reads the drafts table

#### 5.7.9 Business rules

- R1. Draft transactions don't trigger any cascading balance updates.
- R2. Editing a Settled transaction reverses the old effect, then applies the new effect.
- R3. Drafts have no minimum required fields beyond a Draft type and amount (other fields can be filled at Settle time).
- R4. Unsettle: Settled → Draft reverses balance changes. Confirmation required.
- R5. Auto-cleanup: drafts older than 90 days past their scheduled date are auto-flagged (notification: "10 drafts are stale, review them").

---

### 5.8 Recurring Templates (auto-generates Drafts)

**REVISED behavior.**

#### 5.8.1 Data model (same as v2)

Plus:

| Field | Type | Required | Notes |
|---|---|---|---|
| autoCreateDrafts | boolean | yes | Default true |
| draftAdvanceMonths | number | yes | Default 3 — how many months ahead to keep drafts |

#### 5.8.2 The Recurring Engine (NEW behavior)

Instead of expanding events on the fly in Projection, the engine **runs periodically** and creates Draft transactions:

```
Trigger: On app open + every 24 hours + after any Recurring template change

For each Active Recurring Template R where autoCreateDrafts = true:
    nextOccurrences = compute all dates from today to today + R.draftAdvanceMonths months
    For each date D in nextOccurrences:
        if no draft transaction exists with recurringId = R.id AND date = D:
            create Draft transaction { recurringId: R.id, date: D, ... fields from R, status: 'Draft', source: 'Recurring' }
```

So Drafts get materialized into the Transactions table.

#### 5.8.3 What happens when a Recurring template is edited

- Future drafts (date > today, not yet settled) from this template are auto-updated (amount, category, account)
- Past drafts (already settled) are NOT touched

#### 5.8.4 What happens when a Recurring template is deleted

- Future drafts (date > today, not yet settled) from this template are also deleted
- Past drafts that are settled are preserved (they're already history)

#### 5.8.5 What happens when a Recurring template is paused

- No new drafts created going forward
- Existing future drafts: user prompted "Delete pending drafts from this template too? Y/N"

#### 5.8.6 What happens when a Draft from a Recurring template is settled

- Status flips to Settled, balance applied
- Engine ensures the NEXT draft for this template still exists (for projection continuity)

---

### 5.9 Projection (simplified)

**REVISED — Account balance forecast chart REMOVED.**

#### 5.9.1 Page sections (revised)

```
┌────────────────────────────────────────────────────────────┐
│ Projection                  [Horizon: Next 60 days ▼]      │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │ Starting │ │  Inflow  │ │ Outflow  │ │   End    │      │
│  │ ₹3,25,700│ │ +₹2,40,k │ │ −₹2,10,k │ │ ₹3,55,k  │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│                                                            │
│  PER-ACCOUNT EXPECTED END BALANCE                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │HDFC Salary  │ │ICICI Savings│ │  Tax Saver  │          │
│  │ ₹1,52,400   │ │  ₹68,200    │ │   ₹1,50,000 │          │
│  │ +₹24,000    │ │  +₹23,000   │ │     —       │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
│                                                            │
│  TIMELINE                                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Date  │ Item  │ Cat │ Account │ Amount │ Balance ⚠️  │  │
│  │ ...   │ ...   │ ... │ ...     │ ...    │ ...        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

#### 5.9.2 What's removed
- Total liquid balance line chart over time (removed per your request)

#### 5.9.3 Data source

Projection reads:
1. **All Draft transactions** with date > today, within horizon
2. **Optional**: expanded recurring events that haven't been drafted yet (in case engine hasn't run)

Sorted by date. Computes running balance per account. Flags low-balance warnings.

---

### 5.10 Dashboard

(Same structure as v2 with these tweaks:)

- "Next 7 days" stat card → counts Draft transactions in next 7 days (not auto-expanded recurring)
- New alert type: **Stale drafts** (drafts past their scheduled date, not yet settled)
- New stat: **Drafts pending settle** (count of overdue drafts)

---

### 5.11 Settings (with Categories editor + Profile management)

#### 5.11.1 Sections (revised)

```
┌── Profile ──────────────────────────────────────┐
│ Active profile: [Personal Finance ▼]            │
│ [Manage profiles] [Switch profile]              │
└─────────────────────────────────────────────────┘

┌── Account (User) ───────────────────────────────┐
│ Email: tushar@example.com                       │
│ [Change password] [Change email] [2FA Setup]    │
│ [Logout] [Delete account]                       │
└─────────────────────────────────────────────────┘

┌── Preferences ──────────────────────────────────┐
│ Currency: [₹]                                   │
│ Theme: [Light v]                                │
│ Projection horizon: [60 days]                   │
│ Date format: [DD MMM YYYY v]                    │
│ First day of week: [Monday v]                   │
└─────────────────────────────────────────────────┘

┌── Categories & Subcategories ─────────────── NEW│
│  [Income] [Expense]                             │
│  Categories:                                    │
│  ┌─────────────────────────────────────────┐    │
│  │ Food            [✏️][🗑️] ▼ subcats        │    │
│  │   - Restaurants  [✏️][🗑️]                │    │
│  │   - Tiffin       [✏️][🗑️]                │    │
│  │   - Cafe         [✏️][🗑️]                │    │
│  │   + Add subcategory                      │    │
│  │ Groceries       [✏️][🗑️] ▼ subcats        │    │
│  │   ...                                    │    │
│  │ + Add category                           │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘

┌── Tax Flags ────────────────────────────────────┐
│ [+ Add custom tax flag]                         │
│ • 80C [✏️][🗑️]  • 80D [✏️][🗑️]  • HRA ...     │
└─────────────────────────────────────────────────┘

┌── Backup & Sync ────────────────────────────────┐
│ Cloud sync: ✅ Active (last synced 2 min ago)   │
│ [⬇️ Export backup] [⬆️ Import]                  │
│ [Force sync]                                    │
└─────────────────────────────────────────────────┘

┌── Sample Data ──────────────────────────────────┐
│ [Load sample data] [Reset profile data]         │
└─────────────────────────────────────────────────┘

┌── About ────────────────────────────────────────┐
│ Version 3.0 · Modules: ... · Storage: cloud     │
└─────────────────────────────────────────────────┘
```

#### 5.11.2 Categories editor business rules

- R1. Cannot delete a category if any transaction uses it. (Soft prompt: "Re-categorize X transactions first.")
- R2. Renaming a category updates all transactions using it.
- R3. Subcategories are scoped per parent category.
- R4. Income categories and Expense categories are separate lists.
- R5. Order can be changed via drag-handle (web) or up/down arrows (mobile).
- R6. Each category can have:
  - Name (required)
  - Icon (optional, from Lucide library)
  - Color (optional, defaults to neutral)
  - Tax-flag default (optional — e.g., "Investment" category auto-suggests 80C tag)

#### 5.11.3 Profile management screen

```
┌── Profiles ─────────────────────────────────────┐
│  [+ Create new profile]                         │
│                                                 │
│  ● Personal Finance         (active)            │
│    Created 2024-08-15 · 24 accounts · 1,840 txn │
│    [Switch to] [Rename] [Archive] [Delete]      │
│                                                 │
│  ○ Business Finance                             │
│    Created 2025-01-12 · 8 accounts · 412 txn    │
│    [Switch to] [Rename] [Archive] [Delete]      │
│                                                 │
│  ○ Wife's Personal           (archived)         │
│    [Unarchive] [Delete]                         │
└─────────────────────────────────────────────────┘
```

---

## 6. Cross-Module Business Rules

### 6.1 Sacred rules (updated)

| Rule | Description |
|---|---|
| Conservation | Every settled rupee comes from somewhere and goes somewhere |
| No double-count | Settlements ≠ expenses, Transfers ≠ income/expense |
| Drafts are plans | Drafts never affect balances; they only affect Projection |
| Single source of truth | Account balance = Initial + Σ(settled income) − Σ(settled expense+settlement+transfer-out) + Σ(settled transfer-in) |
| Cascade carefully | Edit a settled txn → reverse old, apply new. Delete → reverse |
| Loan schedule from log | Loan schedule always recomputed from event log, never stored statically |
| RLS enforced | Server-side: user X can never see user Y's data, period |
| Drafts auto-regenerate | Settling a draft from a recurring template triggers next draft creation |

### 6.2 Cascade behavior

| Action | Effect on related entities |
|---|---|
| Delete Account | Blocked if any Settled transactions exist. Drafts referencing it get unlinked. |
| Delete Card | Same as account. |
| Delete Loan | Cascades: all prepayments, all event_log entries, all auto-generated EMI drafts. Settled EMI transactions: keeps them but unlinks loanId. |
| Delete Insurance | Keeps premium-payment transactions (they're real money out). Unlinks insuranceId. |
| Delete Person | Unlinks from insurance policies after confirm. |
| Delete Recurring | Deletes future unsettled drafts from this template. Settled past drafts preserved. |
| Delete Transaction (Draft) | Just removed. |
| Delete Transaction (Settled) | Reverses balance changes, then removes. |
| Delete Profile | DESTROYS all data in that profile after double confirmation. |

---

## 7. Calculation Rules (incl. Amortization)

### 7.1 Net Worth, Card Outstanding, AMB, AQB, Cycle calculations

(Same as v2 — see prior section.)

### 7.2 Amortization formula (EMI calculation)

```
EMI = P × r × (1+r)^n / ((1+r)^n − 1)

where:
  P = principal (current outstanding for recalc, sanctioned for initial)
  r = monthly interest rate = annual_rate / 12 / 100
  n = tenure in months
```

### 7.3 Monthly split (principal vs interest)

For any given EMI payment month:
```
interest_component = current_balance × monthly_rate
principal_component = EMI − interest_component
new_balance = current_balance − principal_component
```

### 7.4 Prepayment — Recalculation strategy A (reduce tenure, keep EMI)

```
After prepayment, balance reduced.
Solve for new n (number of months):

n_new = ln(EMI / (EMI − new_balance × r)) / ln(1 + r)

Round up to next whole month.
```

### 7.5 Prepayment — Recalculation strategy B (reduce EMI, keep tenure)

```
After prepayment, balance reduced. Use same n.
EMI_new = new_balance × r × (1+r)^n / ((1+r)^n − 1)
```

### 7.6 Rate change recalculation

```
Same as Strategy B but with new r.
EMI_new = current_balance × r_new × (1+r_new)^n_remaining / ((1+r_new)^n_remaining − 1)
```

### 7.7 Full amortization schedule generation (pseudocode)

```
function generateSchedule(loan):
    schedule = []
    balance = loan.sanctionedAmount
    monthly_rate = loan.originalRate / 12 / 100
    emi = loan.originalEmi
    date = loan.disbursementDate
    
    # Replay all events to determine current state
    for event in loan.event_log sorted by date:
        # Generate scheduled EMIs between last event and this event
        while date < event.date:
            interest = balance × monthly_rate
            principal = emi − interest
            balance −= principal
            schedule.push({ date, opening: balance + principal, emi, interest, principal, closing: balance })
            date = date + 1 month
        
        # Apply this event
        if event.type == "Prepayment":
            balance −= event.amount
            schedule.push({ date: event.date, type: "Prepayment", amount: event.amount, balance })
            if event.strategy == "ReduceTenure":
                # recompute remaining n with same EMI
            else:
                # recompute new EMI with same n
                emi = recompute(balance, monthly_rate, remaining_n)
        elif event.type == "RateChange":
            monthly_rate = event.new_rate / 12 / 100
            emi = recompute(balance, monthly_rate, remaining_n)
        elif event.type == "TenureChange":
            remaining_n = event.new_n
            emi = recompute(balance, monthly_rate, remaining_n)
    
    # Project future EMIs after last event
    while balance > 0:
        interest = balance × monthly_rate
        principal = emi − interest
        balance −= principal
        schedule.push({ date, ..., closing: balance })
        date = date + 1 month
    
    return schedule
```

---

## 8. Flow Charts

### 8.1 Login & Profile Selection

```
        App opens
            │
            ▼
    Is user logged in?
       │           │
       No          Yes (valid JWT)
       │           │
       ▼           ▼
    Login    Load profiles
    Screen   for user
       │           │
       │      Has 2+ profiles?
       │           │
       │      ┌────┴────┐
       │      No        Yes
       │      │         │
       │      ▼         ▼
       │   Enter    Show
       │   default  Profile
       │   profile  Picker
       │      │         │
       │      │    User picks
       │      │    profile
       │      └────┬────┘
       │           │
       └─→ Validate ─▼
              JWT
            Load profile
            data from API
                │
                ▼
            Dashboard
```

### 8.2 Add Transaction (Draft or Settle)

```
User clicks + Transaction
        │
        ▼
Modal opens with type pills
        │
User picks type + fills form
        │
        ▼
User picks: ○ Save Draft  ● Settle Now
        │
   ┌────┴────┐
   ▼         ▼
Save      Settle
Draft     Now
   │         │
   ▼         ▼
Validate  Validate
   │         │
   ▼         ▼
Status    Status = Settled
= Draft   Apply balance effect
   │         │
   ▼         ▼
Store     Store
   │         │
   ▼         ▼
Toast    Toast "Settled"
"Draft       │
saved"   Re-render Dashboard
   │
Show in
Transactions
with badge
```

### 8.3 Settle a Draft Later

```
User views Transactions list
        │
Finds draft (yellow border + Draft badge)
        │
        ▼
Clicks Settle button
        │
        ▼
Mini-modal: confirm amount, date,
account (pre-filled from draft)
        │
        ▼
User confirms
        │
        ▼
Status: Draft → Settled
settledAt = now
Apply balance effect
        │
        ▼
If draft was from Recurring:
  Engine generates NEXT draft for this template
        │
        ▼
Re-render
```

### 8.4 Recurring template → Draft generation

```
Trigger: App open OR every 24h OR after recurring template change
                │
                ▼
For each Active recurring template R:
                │
                ▼
        Compute next N months of occurrences
        (N = R.draftAdvanceMonths, default 3)
                │
                ▼
        For each occurrence date D:
          Does a draft txn already exist
          with recurringId = R.id AND date = D ?
                │
           ┌────┴────┐
           Yes       No
           │         │
           ▼         ▼
        Skip     Create Draft transaction
                  (status: Draft, source: Recurring)
                  All fields copied from R
                  │
                  ▼
              Save to DB
```

### 8.5 Loan Prepayment with Recalc

```
User clicks ⬆️ Prepayment on loan
        │
        ▼
Modal: amount, date, account, note
        │
        ▼
Asks: Recalculation strategy?
○ Reduce tenure (keep EMI)
○ Reduce EMI (keep tenure)
        │
User confirms
        │
        ▼
1. Create Expense transaction (Settled, category EMI)
2. Create event_log entry (type: Prepayment, strategy: X)
3. Reduce loan.outstanding by amount
4. Recompute schedule from this date forward
5. If strategy A → new tenure shown
   If strategy B → new EMI shown
        │
        ▼
Show "Saved you X months / ₹Y in interest"
        │
        ▼
Re-render loan card with new schedule
```

### 8.6 Loan Rate Change

```
User opens Edit Loan → Rate tab
        │
        ▼
Sees current rate, current EMI
        │
        ▼
Enters new rate + effective date (default today)
        │
        ▼
System previews:
  - Computes new EMI for remaining tenure
  - Shows: "EMI changes from ₹18,500 to ₹19,140"
        │
User confirms
        │
        ▼
1. Create event_log entry (type: RateChange, old: 8.5, new: 9.25)
2. Update loan.currentRate
3. Recompute schedule from effective date forward
```

### 8.7 Profile Switching

```
User clicks profile dropdown in header
        │
        ▼
Sees list of all their profiles
        │
        ▼
Clicks "Business Finance"
        │
        ▼
1. Confirm if there are unsaved drafts in current profile
2. Clear current profile data from memory
3. Set active_profile_id = "Business Finance"
4. Fetch this profile's data from API (or load from local cache)
5. Re-render Dashboard
        │
        ▼
Brand color in UI subtly changes to new profile's color
Title bar shows "Business Finance" indicator
```

---

## 9. UI / UX Conventions (PROFESSIONAL)

### 9.1 Design system — Foundations

#### 9.1.1 Typography

| Use | Font | Size | Weight | Line Height |
|---|---|---|---|---|
| Display (large stat) | Inter | 32px | 700 | 1.2 |
| Page title | Inter | 24px | 700 | 1.3 |
| Section title | Inter | 16px | 600 | 1.4 |
| Card title | Inter | 14px | 600 | 1.4 |
| Body | Inter | 14px | 400 | 1.5 |
| Small | Inter | 12px | 400 | 1.4 |
| Tiny / label | Inter | 11px | 600 | 1.3 (uppercase, letterspaced) |

**Font:** Inter (Google Fonts, free) — clean, professional, designed for UI.

#### 9.1.2 Spacing scale (4px grid)

```
xs:  4px
sm:  8px
md: 16px
lg: 24px
xl: 32px
xxl: 48px
```

Use **only these values** — never random numbers like 13px or 19px.

#### 9.1.3 Color tokens

**Light mode (primary):**

| Token | Value | Use |
|---|---|---|
| bg | #fafbfc | Page background |
| surface | #ffffff | Cards |
| surface-2 | #f4f6f8 | Hover states, mini-cards inside cards |
| border | #e1e5ea | Card borders |
| border-strong | #c8cfd6 | Inputs |
| text-primary | #1a1f36 | Body text |
| text-secondary | #5e6c84 | Sub-text |
| text-tertiary | #8b95a5 | Hints, labels |
| primary | #4f46e5 | Brand, CTAs |
| primary-hover | #4338ca | CTA hover |
| success | #15803d | Income, positive |
| success-soft | #dcfce7 | Success bg |
| danger | #dc2626 | Expense, alerts |
| danger-soft | #fee2e2 | Danger bg |
| warning | #d97706 | Pending |
| warning-soft | #fef3c7 | Warning bg |
| info | #0369a1 | Info |
| info-soft | #dbeafe | Info bg |

**Dark mode:** Mirror of above with appropriate inversions.

#### 9.1.4 Elevation (shadows)

| Level | Shadow | Use |
|---|---|---|
| 0 | none | Flat surfaces |
| 1 | 0 1px 2px rgba(0,0,0,0.04) | Cards |
| 2 | 0 4px 8px rgba(0,0,0,0.06) | Hover state on cards |
| 3 | 0 10px 25px rgba(0,0,0,0.08) | Modals, dropdowns |

#### 9.1.5 Border radius

| Token | Value | Use |
|---|---|---|
| sm | 6px | Buttons, badges |
| md | 10px | Inputs, small cards |
| lg | 14px | Cards |
| xl | 20px | Modals (mobile) |
| full | 9999px | Pills, badges, avatars |

### 9.2 Icon system — Lucide Icons (NO EMOJIS)

**Library:** [Lucide](https://lucide.dev) — open source (MIT), ~1500 icons, consistent stroke style, used by professional fintech products.

**Loading:**
```html
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>
<script>lucide.createIcons();</script>
```

**Usage:**
```html
<i data-lucide="building-bank"></i>      <!-- bank/account -->
<i data-lucide="credit-card"></i>        <!-- card -->
<i data-lucide="landmark"></i>           <!-- loan -->
<i data-lucide="shield-check"></i>       <!-- insurance -->
<i data-lucide="trending-up"></i>        <!-- investment -->
<i data-lucide="users"></i>              <!-- people -->
<i data-lucide="receipt"></i>            <!-- transaction -->
<i data-lucide="repeat"></i>             <!-- recurring -->
<i data-lucide="line-chart"></i>         <!-- projection -->
<i data-lucide="layout-dashboard"></i>   <!-- dashboard -->
<i data-lucide="settings"></i>           <!-- settings -->
<i data-lucide="plus"></i>               <!-- add -->
<i data-lucide="pencil"></i>             <!-- edit -->
<i data-lucide="trash-2"></i>            <!-- delete -->
<i data-lucide="check"></i>              <!-- settle / done -->
<i data-lucide="file-clock"></i>         <!-- draft -->
<i data-lucide="alert-triangle"></i>     <!-- warning -->
<i data-lucide="bell"></i>               <!-- notifications -->
<i data-lucide="arrow-down-left"></i>    <!-- income -->
<i data-lucide="arrow-up-right"></i>     <!-- expense -->
<i data-lucide="arrow-right-left"></i>   <!-- transfer -->
<i data-lucide="banknote"></i>           <!-- settlement -->
<i data-lucide="chevron-down"></i>       <!-- dropdown -->
<i data-lucide="search"></i>             <!-- search -->
<i data-lucide="filter"></i>             <!-- filter -->
<i data-lucide="more-horizontal"></i>    <!-- More menu -->
<i data-lucide="log-out"></i>            <!-- logout -->
<i data-lucide="user-circle"></i>        <!-- profile -->
<i data-lucide="building"></i>           <!-- business profile -->
<i data-lucide="home"></i>               <!-- personal profile -->
```

**Sizes:**
- Default: 18px (in lists, buttons)
- Large: 24px (in nav items, cards)
- Small: 14px (inline with text)
- Tiny: 12px (in small labels)

**Color:** Always inherited from surrounding text color via `currentColor`. Icons in danger-colored text are danger-colored, etc.

### 9.3 Component patterns

#### Buttons
```
Primary:    [Blue button, white text, 10px radius, 10px 16px padding]
Secondary:  [Gray button, dark text]
Danger:     [Red button, white text]
Ghost:      [No background, hover shows subtle gray]
Sizes:      Default (40px tall) / Small (32px) / Large (48px)
With icon:  [icon] Text  OR  [icon]
```

#### Cards
```
┌─ Padding 18px on all sides ─────────────┐
│ Header: icon + title + actions (right)  │
│                                         │
│ Body: key metric (large, bold)          │
│       sub-text (12px, muted)            │
│                                         │
│ Footer: badges, timestamp               │
└─ Border 1px, radius 14px ───────────────┘
```

#### Tables (web)
- Sticky header row
- Zebra-stripe rows (subtle)
- Hover highlights row
- Right-align numeric columns
- Tabular numerals (`font-variant-numeric: tabular-nums`)

#### Forms
- Label above field, 13px, muted color
- Field 40px tall, 10px radius
- Focus ring: 3px primary-soft halo
- Error: red border + red helper text below
- Disabled: 40% opacity
- Required: small red dot after label

#### Modals
- Web: centered, max 560px, backdrop blur
- Mobile: full screen, slides up from bottom
- Sticky header with title + close (×)
- Sticky footer with action buttons (right-aligned on web, full-width stacked on mobile)

#### Empty states
Every empty list shows:
1. Large illustration / icon
2. Title (e.g., "No accounts yet")
3. Sub-text (1 line, explains)
4. Primary CTA button

### 9.4 Animations

- All hover states: 150ms ease-out
- Modal open/close: 200ms ease-out
- Page transitions: 150ms fade
- Toast: slide-in from right (web) / bottom (mobile), 200ms
- Skeleton loaders: shimmer animation

### 9.5 Mobile-specific patterns

- **Bottom sheet modals** instead of centered
- **Pull to refresh** on lists
- **Swipe-left to reveal Delete/Edit** on list items
- **FAB** for primary add action
- **Tab bar** at bottom (4 items + More)
- **Large tap targets** — minimum 44×44px
- **Native back gesture** (browser back works as expected)

### 9.6 Accessibility

- All interactive elements keyboard-accessible (Tab, Enter, Esc)
- Focus visible (3px halo)
- Screen reader labels (`aria-label`) on icon-only buttons
- Color contrast: WCAG AA minimum (4.5:1 for text)
- Reduced motion: respect `prefers-reduced-motion`
- Dark mode: not just inverted colors — proper dark surface treatment

---

## 10. Backend & Database Setup

### 10.1 Recommendation: **Supabase**

After evaluating the options, Supabase is the best fit. Here's the comparison:

| Option | Free tier | Pros | Cons |
|---|---|---|---|
| **Supabase** | 500MB DB, 50K MAU, 5GB transfer, 1GB file storage, unlimited API requests | Postgres (real SQL), built-in auth, RLS, real-time, JS SDK, no vendor lock-in | Free tier project pauses after 1 week of inactivity (auto-restores on visit) |
| Firebase | 1GB DB, 50K reads/day, 20K writes/day, 10GB transfer | Mature, simple, integrated everything | NoSQL (Firestore) — awkward for relational financial data, vendor lock-in |
| PocketBase | Self-hosted (you provide hosting) | Single binary, SQLite, full control, no limits | YOU host it (Hetzner/DigitalOcean ~$5/month) |
| Appwrite | 75K MAU, 5GB storage on cloud free tier | Open source, similar to Firebase | Less mature than Supabase, smaller community |

**Recommendation: Supabase** because:
- Postgres = familiar SQL, your finance data IS relational
- RLS = ironclad security at the database layer (not just app layer)
- Built-in auth (email/password + magic link + Google)
- Real-time subscriptions for multi-device sync
- Excellent JS SDK
- Open source — you can self-host later if you outgrow free tier
- Free tier supports your use case for years

### 10.2 Database Schema (Postgres)

```sql
-- Auth handled by Supabase Auth (auth.users table is built-in)

-- Profiles (tenant per user)
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'Personal',
  currency TEXT DEFAULT '₹',
  color TEXT,
  icon TEXT,
  is_default BOOLEAN DEFAULT false,
  archived BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);

-- Categories (per-profile, user-customizable)
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('income','expense')),
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  default_tax_flag TEXT,
  display_order INTEGER DEFAULT 0,
  UNIQUE(profile_id, kind, name)
);

CREATE TABLE subcategories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  UNIQUE(category_id, name)
);

-- People
CREATE TABLE people (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT,
  dob DATE,
  pan TEXT,
  notes TEXT
);

-- Accounts
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  bank TEXT,
  type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Active',
  last4 TEXT,
  balance NUMERIC(15,2) DEFAULT 0,
  min_balance NUMERIC(15,2) DEFAULT 0,
  min_balance_type TEXT DEFAULT 'None',
  interest_rate NUMERIC(5,2) DEFAULT 0,
  interest_payout TEXT,
  ifsc TEXT,
  opening_date DATE,
  maturity_date DATE,
  maturity_amount NUMERIC(15,2),
  joint_holder TEXT,
  nominee TEXT,
  notes TEXT
);

-- Cards
CREATE TABLE cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  bank TEXT,
  network TEXT,
  status TEXT NOT NULL DEFAULT 'Active',
  last4 TEXT,
  credit_limit NUMERIC(15,2) DEFAULT 0,
  interest_rate NUMERIC(5,2),
  bill_day INTEGER CHECK (bill_day BETWEEN 1 AND 31),
  due_day INTEGER CHECK (due_day BETWEEN 1 AND 31),
  annual_fee NUMERIC(10,2),
  waiver TEXT,
  reward_type TEXT,
  reward_rate NUMERIC(5,2),
  auto_debit_account_id UUID REFERENCES accounts(id),
  notes TEXT
);

-- Loans
CREATE TABLE loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  lender TEXT,
  type TEXT,
  status TEXT NOT NULL DEFAULT 'Active',
  last4 TEXT,
  sanctioned_amount NUMERIC(15,2),
  outstanding NUMERIC(15,2),
  original_emi NUMERIC(12,2),
  current_emi NUMERIC(12,2),
  emi_day INTEGER,
  original_rate NUMERIC(5,2),
  current_rate NUMERIC(5,2),
  rate_type TEXT,
  disbursement_date DATE,
  original_tenure_months INTEGER,
  current_tenure_remaining INTEGER,
  paid_from_account_id UUID REFERENCES accounts(id),
  processing_fee NUMERIC(12,2),
  other_charges NUMERIC(12,2),
  notes TEXT
);

-- Loan event log
CREATE TABLE loan_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  event_type TEXT NOT NULL,
  amount NUMERIC(15,2),
  from_account_id UUID REFERENCES accounts(id),
  principal_component NUMERIC(15,2),
  interest_component NUMERIC(15,2),
  balance_after NUMERIC(15,2),
  old_value NUMERIC(12,2),
  new_value NUMERIC(12,2),
  strategy TEXT,
  note TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Insurance
CREATE TABLE insurance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  insurer TEXT,
  type TEXT,
  status TEXT DEFAULT 'Active',
  policy_last4 TEXT,
  premium NUMERIC(12,2),
  frequency TEXT,
  cover NUMERIC(15,2),
  renewal_date DATE,
  start_date DATE,
  end_date DATE,
  paid_from_account_id UUID REFERENCES accounts(id),
  nominee TEXT,
  agent TEXT,
  agent_contact TEXT,
  notes TEXT
);

CREATE TABLE insurance_insured (
  insurance_id UUID REFERENCES insurance(id) ON DELETE CASCADE,
  person_id UUID REFERENCES people(id) ON DELETE CASCADE,
  PRIMARY KEY (insurance_id, person_id)
);

-- Investments
CREATE TABLE investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  provider TEXT,
  type TEXT,
  status TEXT DEFAULT 'Active',
  folio TEXT,
  invested NUMERIC(15,2),
  current_value NUMERIC(15,2),
  sip_amount NUMERIC(12,2),
  sip_day INTEGER,
  paid_from_account_id UUID REFERENCES accounts(id),
  start_date DATE,
  maturity_date DATE,
  tax_benefit TEXT,
  units NUMERIC(15,4),
  notes TEXT
);

-- Recurring templates
CREATE TABLE recurring (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  type TEXT NOT NULL,
  amount NUMERIC(15,2),
  category TEXT,
  frequency TEXT,
  day_of_month INTEGER,
  month INTEGER,
  from_account_id UUID REFERENCES accounts(id),
  to_account_id UUID REFERENCES accounts(id),
  card_id UUID REFERENCES cards(id),
  start_date DATE,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  auto_create_drafts BOOLEAN DEFAULT true,
  draft_advance_months INTEGER DEFAULT 3
);

-- Transactions (Draft + Settled)
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Settled',
  source TEXT NOT NULL DEFAULT 'Manual',
  date DATE NOT NULL,
  amount NUMERIC(15,2),
  category TEXT,
  subcategory TEXT,
  from_account_id UUID REFERENCES accounts(id),
  to_account_id UUID REFERENCES accounts(id),
  card_id UUID REFERENCES cards(id),
  loan_id UUID REFERENCES loans(id),
  insurance_id UUID REFERENCES insurance(id),
  recurring_id UUID REFERENCES recurring(id),
  payee TEXT,
  mode TEXT,
  reference TEXT,
  tax_flag TEXT,
  note TEXT,
  draft_created_at TIMESTAMP DEFAULT now(),
  settled_at TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_txn_profile_date ON transactions(profile_id, date DESC);
CREATE INDEX idx_txn_profile_status ON transactions(profile_id, status);
CREATE INDEX idx_txn_from ON transactions(from_account_id);
CREATE INDEX idx_txn_to ON transactions(to_account_id);
CREATE INDEX idx_txn_card ON transactions(card_id);
CREATE INDEX idx_loan_events_loan_date ON loan_events(loan_id, date);

-- Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users see own profiles" ON profiles
  FOR ALL USING (user_id = auth.uid());

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users see own accounts" ON accounts
  FOR ALL USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

-- ... (same RLS policy for every other table)
```

### 10.3 Setup steps for you (non-technical)

1. **Create Supabase account** at supabase.com (free, takes 2 min)
2. **Create new project** — name "FinancePortal", choose closest region (Mumbai/Singapore)
3. **Run schema SQL** — copy/paste the schema above into Supabase SQL editor and run
4. **Get API keys** — Project Settings → API → copy "URL" and "anon key"
5. **Paste keys into the portal** — Settings → Cloud Sync → enter URL and anon key
6. **Sign up** in the portal — creates your first user + default profile
7. **Done** — your data now syncs to cloud, accessible from any device after login

I'll write the SQL file you can copy-paste, and walk you through the Supabase UI screens with screenshots when we get to implementation.

### 10.4 Cost projection

- 0–50 MAU: **₹0 / month** (free tier)
- 50–500 MAU: ~$25/month (Pro tier) — only relevant if you let other people use your portal
- Just for you and family: free tier forever

---

## 11. Security Specification

### 11.1 Authentication
- Passwords: never sent to client in plain text. Hashed by Supabase Auth (bcrypt + salt). We never see them.
- Sessions: JWT signed by Supabase. Auto-rotated. Stored in `httpOnly` cookie (not accessible to JavaScript) where possible.
- Token expiry: 24h access token, 7-day refresh (30d with "Remember me").
- Failed login lockout: 5 attempts in 15 min → 15-min cool-down.
- Password reset: magic link to email, 1-hour expiry.

### 11.2 Authorization
- Every API query goes through Supabase Row-Level Security.
- User can ONLY read/write data where the `profile_id` belongs to a profile they own.
- Server-side enforcement — even if the client app is compromised, attacker cannot access other users' data.

### 11.3 Data at rest
- Supabase Postgres is encrypted with AES-256 by default.
- Local browser cache (IndexedDB): when "Remember me" is unchecked, cache cleared on logout. When checked, cache encrypted using Web Crypto API with a key derived from user's session.

### 11.4 Data in transit
- HTTPS only (TLS 1.3). Supabase enforces this.
- No plaintext API calls. Period.

### 11.5 What we DON'T store
- Full bank account numbers (only last 4 digits — enforced at form validation)
- Card numbers (only last 4 digits)
- Card CVV (never, anywhere)
- Online banking passwords / PINs
- Login passwords for any third party
- Aadhaar numbers (don't collect unless absolutely needed; if needed, encrypt at field level)

### 11.6 What we DO store
- Account names, banks, last 4
- Transaction history with amounts
- Insurance/loan details
- Personal names of family members

If breached, this data is sensitive (reveals financial patterns) but does NOT enable direct fraud (no account access, no card numbers).

### 11.7 Audit log
- Every login, profile switch, password change, profile deletion, data export logged.
- Retained for 90 days.
- User can view their own audit log in Settings → Security.

### 11.8 2FA (optional)
- Magic-link 2FA via email (free)
- TOTP (Google Authenticator) — Phase 2

### 11.9 Backup security
- Exports are JSON (unencrypted by default). User encrypts the file themselves if needed.
- Future: option to export as encrypted .json (Web Crypto AES-GCM).

### 11.10 Privacy
- No tracking / analytics by default
- No third-party scripts (Lucide is loaded from unpkg.com or self-hosted)
- No data sold or shared. Ever.

### 11.11 Account deletion
- User can request account deletion any time.
- Soft delete: 7-day grace period during which user can recover.
- Hard delete: all data wiped from Postgres including backups (Supabase honors this).

---

## 12. Validation Rules Master List

(All v2 rules PLUS:)

| New Rule | Applies to |
|---|---|
| Email: valid format, max 100 chars | Auth |
| Password: 8+ chars, 1 letter + 1 number minimum | Auth |
| Profile name: required, max 50 chars, unique per user | Profile |
| Category name: required, max 30 chars, unique within (profile, kind) | Categories |
| Subcategory name: required, max 30 chars, unique within category | Subcategories |
| Cannot delete category in use | Categories |
| Cannot delete profile without typing its name | Profile |
| Transaction status: must be Draft or Settled | Transactions |
| Cannot settle a draft with date > today | Transactions (warning, allowed with confirm) |
| Loan rate change: new rate must be > 0 | Loans |
| Loan tenure change: new tenure must be > already-elapsed months | Loans |

---

## 13. Status of Implementation

| Feature | Status | Phase |
|---|---|---|
| All v2 modules built (local storage) | ✅ Done | v2 |
| AMB/AQB tracking | ✅ Done | v2 |
| Customizable categories | ❌ To build | v3 |
| Lucide icons (replace emojis) | ❌ To build | v3 |
| Professional UI redesign | ❌ To build | v3 |
| Draft/Settled transaction workflow | ❌ To build | v3 |
| Recurring auto-generates drafts | ❌ To build | v3 |
| Projection: remove balance chart | ❌ Simple change | v3 |
| Loan amortization schedule | ❌ To build | v3 |
| Loan edit (rate/tenure/EMI) | ❌ To build | v3 |
| User auth (login/signup) | ❌ To build | v3 |
| Multi-profile (Tally-style) | ❌ To build | v3 |
| Supabase backend + RLS | ❌ To set up | v3 |
| Adaptive web/mobile UI | ❌ To build | v3 |
| Security spec implementation | ❌ To build | v3 |

---

## 14. Phase Roadmap

### Phase 3a — Local-first v3 (Sprint 1)
Build all UI changes against local storage first:
1. Lucide icons everywhere (replace emojis)
2. Professional CSS rewrite (typography, spacing, colors)
3. Customizable categories editor in Settings
4. Draft/Settled transaction workflow
5. Recurring → Draft auto-generation
6. Projection cleanup (remove chart)
7. Loan amortization schedule view
8. Loan edit (rate/tenure/EMI/prepayment recalc)

### Phase 3b — Backend (Sprint 2)
1. Supabase setup (you create account; I provide SQL + config)
2. Auth screens (login, signup, password reset)
3. Multi-profile management
4. Cloud sync layer (replace localStorage with Supabase calls)
5. RLS policies
6. Audit log

### Phase 3c — Mobile-distinct UI (Sprint 3)
1. Separate mobile layout (full-screen modals, bottom nav, swipe gestures)
2. PWA install support
3. Touch optimizations

### Phase 4 (later)
- Reports & Excel export
- Receipt attachments
- 2FA TOTP
- Per-person expense view
- Native mobile app (React Native, if needed)

---

## 15. Open Questions for You

| # | Question | My recommendation |
|---|---|---|
| Q1 | Sprint 1 vs all-at-once? | Sprint 1 (local-first) → you test the new UX → then add backend in Sprint 2 |
| Q2 | Supabase or Firebase? | **Supabase** (Postgres + RLS = perfect for finance) |
| Q3 | Lucide vs another icon library? | **Lucide** — clean, professional, free, MIT-licensed |
| Q4 | Default profile name on signup? | "Personal" (user can rename) |
| Q5 | Draft default: future date → Draft. Past/today → Settled. OK? | Yes |
| Q6 | Recurring auto-draft horizon? | 3 months default, user-configurable |
| Q7 | Settling a draft on a different date than planned — record both planned and actual? | Yes — keep planned date for audit, add settledAt timestamp |
| Q8 | Prepayment default strategy: reduce tenure or reduce EMI? | **Reduce tenure** (saves more interest) — but always ask |
| Q9 | Loan amortization: store schedule or always compute? | **Always compute** from event log — single source of truth |
| Q10 | Per-profile color/icon for visual distinction? | Yes — small accent in header indicates active profile |
| Q11 | Allow profile sharing later (e.g. share with spouse)? | Backlog — needs separate permissions model |
| Q12 | Mobile UI: build as part of v3 or after backend? | Build mobile-adaptive CSS in v3; truly distinct mobile features in Sprint 3 |
| Q13 | Categories: also allow custom icon + color per category? | Yes — small selector in category editor |
| Q14 | Tax flags: hard-coded list or user-editable too? | **User-editable** (in case you need state-specific flags) |
| Q15 | Auto-cleanup stale drafts (older than 90 days)? | Don't auto-delete; just flag with a notification banner |

---

## 16. Glossary (additions)

| Term | Meaning |
|---|---|
| **Draft** | A transaction that is planned but not yet real. Doesn't affect balances. |
| **Settled** | A transaction that actually happened. Affects balances. |
| **RLS (Row-Level Security)** | Database-enforced rule that prevents one user from seeing another user's data |
| **MAU (Monthly Active Users)** | Distinct users in a 30-day period — used for billing tiers |
| **JWT (JSON Web Token)** | Signed token used for stateless auth |
| **Profile (Tally-style)** | A separate dataset under one user account (like "Personal" vs "Business") |
| **Amortization schedule** | Month-by-month breakdown of loan: how much of each EMI is principal vs interest |
| **Foreclosure** | Paying off a loan in full before scheduled end (may have charges) |
| **AMB / AQB** | Average Monthly / Quarterly Balance — bank's metric for minimum balance compliance |
| **PWA (Progressive Web App)** | Web app that can be installed to home screen, works offline, feels like native |
| **bcrypt** | Industry-standard password hashing algorithm |
| **TLS** | Transport Layer Security — encrypts data in transit (HTTPS) |
| **Magic link** | A login link sent via email — clicks it = logged in (no password to remember) |

---

---

## 17. Credit Card Statement View (NEW — addition to Module 5.3)

### 17.1 Where it lives
Inside the **Credit Cards** module, each card gets a new action: **Statement (📄)**. Placed alongside the existing Settle (💵) and Cycle History (📅) buttons.

### 17.2 What it shows

For a chosen billing cycle (default: most recent **closed** cycle, with dropdown to pick any past cycle):

```
┌─────────────────────────────────────────────────────────────┐
│ Statement: HDFC Regalia ••1289                              │
│ Cycle: 05 Apr 2026 – 04 May 2026  ▼ (pick cycle)            │
├─────────────────────────────────────────────────────────────┤
│ STATEMENT SUMMARY                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Previous balance         ₹0                             │ │
│ │ Purchases (+)            ₹42,350                        │ │
│ │ Cash advances (+)        ₹0                             │ │
│ │ Fees & charges (+)       ₹500 (annual fee)              │ │
│ │ Interest (+)             ₹0                             │ │
│ │ Payments (−)             ₹8,500                         │ │
│ │ Credits / refunds (−)    ₹650                           │ │
│ │ ─────────────────────────────────                       │ │
│ │ Statement balance        ₹33,700                        │ │
│ │ Minimum payment due      ₹1,685 (5%)                    │ │
│ │ Payment due date         25 May 2026 (12 days)          │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ REWARDS THIS CYCLE                                          │
│  Points earned: 1,694 · Total balance: 8,420 pts            │
│                                                             │
│ TRANSACTIONS DURING CYCLE                                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Date │ Description │ Category │ Amt │ Status            │ │
│ │ 5 Apr│ Amazon      │ Shopping │1,200│ Settled           │ │
│ │ 7 Apr│ Petrol      │ Transport│2,500│ Settled           │ │
│ │ 10Apr│ Netflix     │ Subscript│  649│ Settled           │ │
│ │ ...                                                     │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ COMPARISON                                                  │
│  vs Last cycle: +12% spending                               │
│  vs 3-month avg: +5% spending                               │
│  Top category: Shopping (₹18,200, 43%)                      │
├─────────────────────────────────────────────────────────────┤
│ [Print statement] [Export to PDF] [Settle this bill]        │
└─────────────────────────────────────────────────────────────┘
```

### 17.3 Statement vs Cycle History

| Cycle History (📅) | Statement (📄) |
|---|---|
| Compact table of last 12 cycles | Deep dive into ONE cycle |
| Just totals per cycle | Full transaction list + summary + rewards + comparison |
| For quick scanning | For reconciling with bank's actual statement |

### 17.4 Data model additions for Statement

Cycle data is computed (not stored), but we add an optional **statement reference** field on cards for when the user receives the actual bank statement:

| Field | Type | Notes |
|---|---|---|
| statement_uploads (table) | | Optional uploads of actual bank statements |
| - id | UUID | |
| - card_id | FK | |
| - cycle_start | date | |
| - cycle_end | date | |
| - statement_balance | number | What the bank says |
| - app_balance | number | What we computed |
| - variance | number | Difference (for reconciliation) |
| - uploaded_file | URL | Optional PDF |
| - notes | text | Reconciliation notes |

This enables **bank reconciliation** — comparing our computed numbers vs bank's official numbers.

### 17.5 Business rules

- R1. Closed cycles (past) are read-only.
- R2. Current cycle statement is "preliminary" — marked as such.
- R3. Settling a cycle from this screen creates a Settlement transaction (same as the existing Settle flow).
- R4. If user uploads bank statement and amounts differ from app → show "Reconciliation needed" badge.

---

## 18. Reports Module (NEW — single-entry style)

**Note:** Per Decision X1, we are NOT doing double-entry accounting. So instead of formal "Balance Sheet" / "Profit & Loss" (which require double-entry to be meaningful), we use honest labels: **Net Worth Statement** and **Income & Expense Report**. The content is similar — just not pretending to be audit-grade accounting.

Reports module sits in the sidebar under **Overview** group, after Dashboard.

### 18.1 Reports menu

```
┌── Reports ──────────────────────────────────────┐
│                                                 │
│  Position & Performance                         │
│  · Net Worth Statement        [As on date]      │
│  · Income & Expense Report    [Period]          │
│  · Cash Flow Report           [Period]          │
│  · Ledger (per-account)       [Period + Acct]   │
│  · Day Book                   [Period]          │
│                                                 │
│  Analytical                                     │
│  · Net Worth Trend            [Period]          │
│  · Category-wise Spending     [Period]          │
│  · Payee / Vendor Analysis    [Period]          │
│  · Monthly Comparison         [Months]          │
│  · Recurring vs One-off       [Period]          │
│  · Tax-tag Summary (80C/80D)  [Period]          │
│                                                 │
│  Schedules                                      │
│  · Loan Amortization          [Loan]            │
│  · Insurance Renewal Calendar [12 months]       │
│  · Investment Performance     [Period]          │
│  · Recurring Templates Schedule [Period]        │
└─────────────────────────────────────────────────┘
```

**Removed from earlier draft (per decisions):**
- ❌ Trial Balance (X6 — no double-entry)
- ❌ Tax Computation / ITR Helper (X5 — no statutory compliance)
- ❌ TDS Summary (X2 — TDS not tracked)
- ❌ Capital Gains Report (deferred — depends on investment buy/sell module which is itself optional)

### 18.2 Report structure (common)

Every report screen:
- **Filters** at top (date range, account, category, etc.)
- **View** mode: Summary / Detailed
- **Compare** mode: vs Previous Period / vs Same Period Last Year / vs Custom
- **Drill-down**: click any number to see underlying transactions
- **Export** button: PDF · Excel · CSV · JSON

### 18.3 Net Worth Statement

**Purpose:** Snapshot of financial position on a specific date. (Not a formal Balance Sheet — see note in 18.1.)

```
              NET WORTH STATEMENT as on 31 May 2026
              ═══════════════════════════════════════
ASSETS                                                 ₹
  Liquid Assets
    Cash in hand                              8,500
    HDFC Salary (Savings)                 1,28,400
    ICICI Savings                            45,200
    PayTM Wallet                              2,100
                                          ─────────
    Total Liquid Assets                   1,84,200

  Deposit Assets
    Tax Saver FD                          1,50,000
                                          ─────────
    Total Deposits                        1,50,000

  Investment Assets (current value)
    Parag Parikh Flexi Cap                1,48,000
    Axis ELSS                                71,500
    EPF                                     4,82,000
    Sovereign Gold Bond                      62,500
                                          ─────────
    Total Investments                     7,64,000

  TOTAL ASSETS                                       10,98,200

LIABILITIES                                            ₹
  Credit Card Outstanding
    HDFC Regalia                             42,000
    HDFC Millennia                           12,000
                                          ─────────
    Total Card Outstanding                   54,000

  Loans Outstanding
    Home Loan                            28,90,000
    Car Loan                              2,40,000
                                          ─────────
    Total Loans                          31,30,000

  TOTAL LIABILITIES                                  31,84,000

NET WORTH (Assets − Liabilities)                   −20,85,800
                                                   ══════════
```

**Notes:**
- Negative net worth here means liabilities > assets (typical when you have a home loan)
- All line items come from existing modules: Accounts, Investments, Cards, Loans
- No Receivables/Payables (per Decision X3, X4)
- This is NOT a double-entry Balance Sheet — it's a sum of module balances. Accurate, but not audit-grade.

### 18.4 Income & Expense Report

**Purpose:** Income vs Expenses for a period. (Not a formal P&L — see note in 18.1.)

```
            INCOME & EXPENSE REPORT for FY 2025-26 (1 Apr 2025 – 31 Mar 2026)
            ═════════════════════════════════════════════════════════════════
INCOME                                              ₹
  Salary                                    9,00,000
  Freelance                                 1,80,000
  Interest on savings                          8,400
  FD interest                                 10,200
  Dividend                                     5,500
  Rental income                                     —
  Refund / Other                              12,500
                                            ─────────
  TOTAL INCOME                              11,16,600

EXPENSES                                              ₹
  Living
    Housing (rent)                          3,00,000
    Utilities                                 32,500
    Groceries                                 84,000
    Food (eating out)                         48,000
                                            ─────────
    Subtotal                                4,64,500
  Transportation                              42,000
  Health                                      28,000
  Entertainment                               24,000
  Insurance Premiums                          65,500
  Investments (SIP, lump-sum)               1,80,000
  EMIs (Home + Car)                         3,60,000
  Subscriptions                               12,000
  Personal / Shopping                         55,000
  Education                                    8,000
  Tax (advance tax)                           45,000
                                            ─────────
  TOTAL EXPENSES                            12,84,000

NET SURPLUS / (DEFICIT)                              (−1,67,400)
                                                    ══════════
```

**Notes:**
- Investments are treated as expenses in cash-flow terms (money out of bank) BUT in the Net Worth Statement they're an asset (you still own the units)
- Income is recorded as the net amount received (no gross/TDS separation per Decision X2)
- Drilldown: click any category → see all txns in that category

### 18.5 Cash Flow Statement

**Purpose:** Where did your money come from and where did it go.

```
            CASH FLOW for May 2026
            ═══════════════════════
OPENING BALANCE (1 May 2026)                  ₹3,25,700

CASH INFLOWS                                          ₹
  Salary received                              75,000
  Freelance receipts                           12,000
  Interest credited                               420
  Refunds                                       1,500
                                              ─────────
  Total Inflows                                88,920

CASH OUTFLOWS                                         ₹
  Operating
    Rent                                     25,000
    Groceries                                 8,400
    Utilities                                 2,400
    Food                                      4,200
    Transport                                 3,200
    Subscriptions                             1,150
                                              ─────────
    Subtotal                                 44,350
  EMIs                                         30,000
  Insurance premiums (paid this month)              —
  Card settlements                             8,500
  Investments (SIPs)                          15,000
  Transfers out (to ICICI)                    20,000
                                              ─────────
  Total Outflows                            1,17,850

NET CASH FLOW                                 (−28,930)

CLOSING BALANCE (31 May 2026)                ₹2,96,770
                                              ═════════
```

**Notes:**
- Transfers in == Transfers out (cancel out across accounts) — they don't change total cash
- For per-account cash flow, run the report per account

### 18.6 ~~Trial Balance~~ — REMOVED

Per Decision X6 (no double-entry, so Trial Balance has no meaning). Not included.

### 18.7 Day Book

**Purpose:** Chronological log of every settled transaction in a period.

Like a transaction list but formatted as accounting entries — sorted strictly by date, no filtering.

### 18.8 Ledger (per-account)

**Purpose:** Show every transaction affecting a single account/category over time, with running balance.

```
        LEDGER: HDFC Salary  (1 Apr 2026 – 31 May 2026)
        ════════════════════════════════════════════════
Date     Particulars            Debit     Credit    Balance
─────────────────────────────────────────────────────────────
01 Apr   Opening balance                            1,18,400
25 Apr   Salary - Acme Corp              75,000     1,93,400
01 May   Home Loan EMI         18,500              1,74,900
05 May   Card Settlement        8,500              1,66,400
07 May   Car Loan EMI          11,500              1,54,900
...
─────────────────────────────────────────────────────────────
31 May   Closing balance                            1,28,400
                                                   ═════════
```

Drilldown: click any line to see the full transaction.

### 18.9 Tax-tag Summary (simple, NOT a tax computation)

**Purpose:** Sum up amounts tagged with each tax flag — for personal awareness only, NOT for ITR filing. (Per Decisions X2, X5 — we don't do TDS handling or statutory compliance.)

```
        TAX-TAG SUMMARY for FY 2025-26
        ═══════════════════════════════
80C — Eligible Investments / Premiums
  EPF contribution                       54,000
  ELSS (Axis Tax Saver) SIP             60,000
  Term Life premium                      18,000
  Tax Saver FD                         1,50,000
                                       ─────────
  Total tagged with 80C                2,82,000

80D — Eligible Health Premiums
  Family Floater Health                  24,000
  Mother Health                          15,000
                                       ─────────
  Total tagged with 80D                  39,000

HRA — Tagged transactions
  Rent payments                        3,00,000

(Other tags: Section 24, 80CCD, LTA, ...)
```

**Notes:**
- This is a **flat sum of tagged transactions** — no caps applied, no calculations, no actual tax computation
- For real ITR filing, share these numbers with your CA — they'll apply the actual deductions
- We do NOT calculate tax liability, taxable income, or refunds (per Decision X5)

### 18.10 Export options for all reports

Every report can be exported to:
- **PDF** (formatted, printable)
- **Excel (.xlsx)** (with formulas where appropriate)
- **CSV** (raw data)
- **JSON** (for backups/programmatic use)
- **Print** (browser print dialog with print stylesheet)

---

## 19. Data Export Module (NEW)

### 19.1 Purpose
Beyond report-specific exports, a centralized **Export & Backup** module for:
- Full data backup (JSON)
- Specific module exports (Excel/CSV)
- Tax-ready bundles (PDF + Excel package)
- Print bundles

### 19.2 Export options

```
┌── Export & Backup ──────────────────────────────┐
│                                                 │
│ FULL BACKUP                                     │
│  [⬇️ Export entire profile as JSON]              │
│  Encrypted: ○ No  ● Yes (with password)          │
│  Includes: all accounts, txns, loans, etc.      │
│                                                 │
│ MODULE EXPORTS                                  │
│  Transactions    [.xlsx] [.csv]  Period filter  │
│  Accounts        [.xlsx] [.csv]                 │
│  Loans           [.xlsx] [.csv] (with schedules)│
│  Investments     [.xlsx] [.csv]                 │
│  Insurance       [.xlsx] [.csv]                 │
│  Cards + Cycles  [.xlsx] [.csv]                 │
│                                                 │
│ TAX BUNDLE (for CA / ITR filing)                │
│  [📦 Generate FY2025-26 Tax Bundle]              │
│  Includes:                                      │
│   · Tax computation PDF                         │
│   · 80C/80D summary PDF                         │
│   · Capital gains report                        │
│   · TDS summary                                 │
│   · Year-end balance sheet PDF                  │
│   · P&L PDF                                     │
│   · Excel with all detailed data                │
│                                                 │
│ STATEMENTS BUNDLE                               │
│  [📦 Card statements for FY]                     │
│  [📦 Bank passbooks for FY]                      │
│  [📦 Loan amortization schedules]                │
│                                                 │
│ SCHEDULED BACKUPS                               │
│  ☑ Auto-export full backup monthly via email    │
│  ☑ Email me a tax-bundle at FY end              │
└─────────────────────────────────────────────────┘
```

### 19.3 Export format conventions
- Excel files use **proper formatting**: bold headers, frozen first row, number formatting (₹ + 2 decimals), conditional formatting for negatives (red)
- PDFs use a professional template with profile name, date generated, page numbers
- CSVs are UTF-8 with BOM (so Excel opens them correctly)
- Filenames: `{ProfileName}_{Module}_{StartDate}_to_{EndDate}.xlsx`

### 19.4 Encrypted backups
- Optional AES-256-GCM encryption using user-supplied password (Web Crypto API)
- Backup file extension `.fpb` (Finance Portal Backup) — to distinguish encrypted from plain JSON
- Restore prompts for password

---

## 20. ~~Receivables / Payables~~ — REMOVED

Per Decisions X3 and X4. If user wants to track an informal loan or pending bill, they'll use a normal Draft transaction with a note.

---

## 21. Final Module List (v5 — locked)

| # | Module | Status |
|---|---|---|
| 5.0 | Auth & Profiles | New (v3) |
| 5.1 | People | Existing |
| 5.2 | Accounts (+ AMB/AQB) | Existing |
| 5.3 | Credit Cards (+ Statement view §17) | Existing + NEW Statement |
| 5.4 | Loans (full amortization + edit) | Existing, REVISED |
| 5.5 | Insurance | Existing |
| 5.6 | Investments | Existing |
| 5.7 | Transactions (Draft/Settled) | Existing, REVISED |
| 5.8 | Recurring (auto-drafts) | Existing, REVISED |
| 5.9 | Projection (simplified) | Existing, SIMPLIFIED |
| 5.10 | Dashboard | Existing |
| 5.11 | Settings (+ Categories editor) | Existing, EXPANDED |
| 5.12 | ~~Receivables~~ | ❌ DECLINED (X3) |
| 5.13 | ~~Payables~~ | ❌ DECLINED (X4) |
| **5.14** | **Reports** (NEW §18) | NEW |
| **5.15** | **Export & Backup** (NEW §19) | NEW |

**Total active modules: 14** (Auth, People, Accounts, Cards, Loans, Insurance, Investments, Transactions, Recurring, Projection, Dashboard, Settings, Reports, Export).

---

## 22. Gap Analysis — What I Think You Missed

This is my honest audit of gaps against accounting standards, business logic, validations, and technical architecture. Color-coded by severity.

🔴 = **Critical** (data integrity or core functionality breaks without it)
🟡 = **Important** (significantly affects user experience or accuracy)
🟢 = **Nice-to-have** (polish or advanced use case)

### 22.1 Accounting / Data Gaps (post-decisions)

| # | Gap | Status | Severity | Description |
|---|---|---|---|---|
| ~~A1~~ | ~~Double-entry bookkeeping~~ | ❌ DECLINED (X1) | — | Not building |
| ~~A2~~ | ~~Chart of Accounts~~ | ❌ DECLINED (X1) | — | Not building |
| ~~A3~~ | ~~Opening Balance Equity~~ | ❌ DECLINED (X1) | — | Not building |
| A4 | **Fiscal Year (FY) support** | ✅ Build | 🟡 | Reports filter by Indian FY (Apr-Mar). Settings: FY start month, default April. |
| ~~A5~~ | ~~Year-end closing entries~~ | ❌ N/A (X1) | — | Only meaningful with double-entry |
| A6 | **Accrual vs Cash basis** | ✅ Already cash | 🟢 | We're cash basis. Optional "accrued interest" display can be added later. |
| A7 | **Capital Gains tracking (buy/sell with cost basis)** | ⏸️ Open | 🟡 | Useful if user wants accurate sell-side gain. Needs Investment buy/sell transactions. Optional. |
| ~~A8~~ | ~~TDS handling~~ | ❌ DECLINED (X2) | — | Not building |
| A9 | **Tax-tag summary report** | ✅ Build (simplified) | 🟡 | Sum of tagged transactions — see §18.9. NOT a real tax computation. |
| A10 | **Currency rounding** | ✅ Build | 🟢 | Setting: 0 or 2 decimals. Display rounds; storage keeps 2. |
| A11 | **Reconciliation flag per transaction** | ⏸️ Open | 🟡 | Useful but not critical. Add `reconciled: boolean`. Defer to Sprint 4+ |
| A12 | **Audit trail (immutable log)** | ✅ Build | 🔴 | Every create/update/delete logged immutably. Critical for multi-user/cloud safety. |
| A13 | **Adjustment / Journal entries** | ⏸️ Open | 🟡 | Generic txn for corrections. Skip for v3 — drafts can serve as adjustments. |
| A14 | **Period locking** | ⏸️ Open | 🟡 | Setting: lock past dates after FY filing. Defer to Sprint 4+ |
| A15 | **Multi-currency / FX** | ⏸️ Backlog | 🟢 | Phase 4+ |

### 22.2 Business Logic Gaps per Module

#### Accounts
| # | Gap | Severity |
|---|---|---|
| B1 | Sweep facility (auto move savings → FD) | 🟢 |
| B2 | Joint account ownership % (for tax) | 🟢 |
| B3 | Interest credit tracking (daily accrual + monthly post) | 🟡 |
| B4 | Account opening cost (some accounts have setup fees) | 🟢 |
| B5 | Bank charges as separate category (currently lumped) | 🟡 |

#### Credit Cards
| # | Gap | Severity |
|---|---|---|
| C1 | **Convert purchase to EMI** (no-cost EMI vs interest-bearing EMI) | 🟡 |
| C2 | **Cash advance** transactions (different interest, no grace period) | 🟡 |
| C3 | **Late payment charges** auto-application when due date missed | 🟡 |
| C4 | **Over-limit charges** | 🟢 |
| C5 | **Reward redemption** (cashback, points, gift voucher, statement credit) | 🟡 |
| C6 | **Foreign currency markup** (3-3.5% typical) on international txns | 🟡 |
| C7 | **Add-on cards** (multiple physical cards under one statement) | 🟢 |
| C8 | **Statement closing date** distinct from bill generation day | 🟢 |
| C9 | **Grace period interest** calculation if partial payment | 🟡 |
| C10 | **Annual fee waiver** automation (track if spend criteria met) | 🟢 |

#### Loans
| # | Gap | Severity |
|---|---|---|
| L1 | **Pre-EMI interest** during construction (home loans, before full disbursement) | 🟡 |
| L2 | **Moratorium period** (education loans — no EMI for first N years) | 🟡 |
| L3 | **Disbursement tranches** (home loan paid in phases) | 🟡 |
| L4 | **Step-up / Step-down EMI** | 🟢 |
| L5 | **Bullet payment** loan (lump sum at end) | 🟢 |
| L6 | **Joint loan** with co-borrower tracking | 🟢 |
| L7 | **Top-up loan** on existing | 🟢 |
| L8 | **Balance transfer** between lenders | 🟢 |
| L9 | **Loan against FD/property/securities** (collateral tracking) | 🟢 |
| L10 | **Income tax benefit** (home loan principal 80C, interest 24b — should auto-classify) | 🟡 |
| L11 | **Insurance premium** bundled with loan (single-premium) | 🟢 |
| L12 | **Loan EMI bounce charges** | 🟢 |

#### Insurance
| # | Gap | Severity |
|---|---|---|
| I1 | **Premium discount / loading** (medical loading for pre-existing) | 🟢 |
| I2 | **No Claim Bonus** for vehicle insurance | 🟡 |
| I3 | **Riders** (additional cover on base policy) | 🟢 |
| I4 | **Sum insured restoration** in health insurance | 🟢 |
| I5 | **Co-pay, deductible** tracking | 🟢 |
| I6 | **Claim history** | 🟡 |
| I7 | **Maturity proceeds** for endowment/ULIP | 🟡 |
| I8 | **Surrender value** tracking | 🟢 |
| I9 | **Policy documents** attachment | 🟡 |
| I10 | **Premium waiver** (some policies waive on disability) | 🟢 |

#### Investments
| # | Gap | Severity |
|---|---|---|
| V1 | **Cost basis methods** (FIFO, LIFO, weighted avg) for stocks/MF | 🔴 |
| V2 | **Buy/Sell transactions** with units × price (currently just aggregated) | 🔴 |
| V3 | **Stock splits, bonus shares** | 🟡 |
| V4 | **Rights issues** | 🟢 |
| V5 | **Dividend received** (separate from interest) — should credit accounts | 🟡 |
| V6 | **Dividend reinvestment** (DRIP) | 🟢 |
| V7 | **Sectoral / Asset allocation** visualization | 🟢 |
| V8 | **Rebalancing alerts** when allocation drifts | 🟢 |
| V9 | **Risk profile** assessment | 🟢 |
| V10 | **Goal mapping** (link investment to a purpose — "Retirement", "Home down payment") | 🟡 |
| V11 | **XIRR / CAGR** calculation for true return | 🟡 |
| V12 | **NAV history** for accurate point-in-time valuation | 🟢 |
| V13 | **Lock-in period** tracking (ELSS = 3 yr, PPF = 15 yr) | 🟡 |

#### Transactions
| # | Gap | Severity |
|---|---|---|
| T1 | **Split transactions** — one purchase across multiple categories (groceries that include personal items) | 🟡 |
| T2 | **Recurring split** (e.g., monthly bills bundled differently each time) | 🟢 |
| T3 | **Attached receipts** (photo or PDF) | 🟡 |
| T4 | **Merchant directory** with frequency stats and auto-suggest | 🟡 |
| T5 | **Refund** as distinct type (currently use Income, but should reduce original expense) | 🟡 |
| T6 | **Round-off** entries (paying ₹501 for ₹500.40 bill) | 🟢 |
| T7 | **Cashback received** (vs income vs reward) | 🟢 |
| T8 | **Discount** received / given | 🟢 |
| T9 | **Bank charges** as auto-category from txn description | 🟢 |
| T10 | **Reverse a settled transaction** (audit-safe) | 🟡 |
| T11 | **Recurring without auto-draft** option (some users may want full manual control) | 🟢 |

#### Cross-cutting
| # | Gap | Status | Severity |
|---|---|---|---|
| ~~CX1~~ | ~~Receivables / Payables~~ | ❌ DECLINED (X3,X4) | — |
| CX2 | **Reminders / Tasks** (non-money: "Renew DL", "Pay bill on 15th") | ⏸️ Backlog | 🟢 |
| CX3 | **Document vault** (PAN, Aadhaar, passport — encrypted) | ⏸️ Backlog | 🟢 |
| CX4 | **Push notifications** (web push API for due-date alerts) | ⏸️ Sprint 5 | 🟡 |
| CX5 | **Email reminders** (configurable cadence) | ⏸️ Backlog | 🟢 |
| CX6 | **Asset register** (car, property, jewelry — non-financial assets) | ⏸️ Backlog | 🟢 |
| CX7 | **Multi-currency** support | ⏸️ Backlog | 🟢 |
| CX8 | **Net worth daily snapshots** for trend chart | ✅ Build | 🟡 |

### 22.3 Rules / Validation Gaps

| # | Rule Missing | Severity |
|---|---|---|
| R1 | Cannot have transaction before account opening date | 🟡 |
| R2 | Cannot have transaction after account close date | 🟡 |
| R3 | Cannot date loan EMI before disbursement date | 🟡 |
| R4 | Holiday/weekend handling for projections (banks process on next working day) | 🟢 |
| R5 | Future-dated **Settled** transaction → should be warning at minimum, currently allowed silently | 🟡 |
| R6 | Maximum transaction amount sanity check (e.g., ₹10 crore in a personal account is probably a typo) | 🟢 |
| R7 | Credit card transaction date must be ≤ statement date for that cycle | 🟡 |
| R8 | Loan tenure change: new tenure must be > already-elapsed months — currently in spec but not enforced | 🟡 |
| R9 | Cannot delete category if used in transactions OR recurring templates | 🟡 |
| R10 | Cannot delete an account with attached recurring templates | 🟡 |
| R11 | Insurance premium auto-flag must match policy type (currently only Health/Life mapped — need vehicle, home, etc.) | 🟢 |
| R12 | EMI > Outstanding shouldn't be possible (last EMI should clear it) | 🟡 |
| R13 | Settling a draft on a different account than planned — should warn (might be unintentional) | 🟢 |
| R14 | Currency symbol affects all displays — currently per-profile, but no validation that historical reports stay consistent | 🟢 |
| R15 | Negative amounts blocked (sign comes from type, amount always positive) | 🟡 |

### 22.4 Technical Architecture Gaps

| # | Gap | Severity | Description |
|---|---|---|---|
| TC1 | **Transaction atomicity** | 🔴 | If app crashes mid-Settle (status updated but balance not yet), data is inconsistent. Need atomic updates. |
| TC2 | **Optimistic locking** for cloud sync | 🔴 | What if same record edited on phone + laptop? Need version numbers + conflict resolution. |
| TC3 | **Soft delete** with grace period | 🟡 | Currently hard delete. No "undo" or recovery. |
| TC4 | **Pagination** for transaction lists | 🟡 | 10k+ transactions will be slow. Need server-side pagination. |
| TC5 | **Virtual scrolling** for long lists | 🟢 | UX improvement for very long ledgers. |
| TC6 | **Memoization** of expensive calcs (amortization schedules, AMB) | 🟡 | Recomputing every render is wasteful. |
| TC7 | **Service Worker** for offline functionality | 🟡 | True PWA needs to work without network. |
| TC8 | **IndexedDB** instead of localStorage (5MB limit) | 🔴 | localStorage caps at 5MB. With many txns + investments + attachments, will exceed. Need IndexedDB. |
| TC9 | **Migration system** for schema changes | 🔴 | Adding new fields needs to handle existing data. |
| TC10 | **Error tracking** (Sentry free tier) | 🟡 | Without this, you have no idea when users hit bugs. |
| TC11 | **Performance monitoring** | 🟢 | What's slow for users on cheap phones? |
| TC12 | **Code organization** (single HTML won't scale) | 🟡 | Beyond ~5000 lines, single file becomes unmaintainable. Need bundler (Vite) + module split. |
| TC13 | **TypeScript** for type safety | 🟡 | JS errors at runtime that TS catches at compile. Saves debugging time. |
| TC14 | **Automated tests** | 🟡 | At minimum, unit tests for calculations (AMB, amortization, EMI). |
| TC15 | **Multi-tab handling** (storage events) | 🟢 | If user opens app in 2 tabs, changes in one should reflect in other. |
| TC16 | **Backup retention** (versioned snapshots) | 🟡 | Single backup file is single point of failure. Should keep N versions. |
| TC17 | **Rate limiting** for cloud (avoid abuse) | 🟢 | Supabase free tier limits — need throttling. |
| TC18 | **Data validation at DB level** | 🟡 | Currently only app validates. DB should have CHECK constraints, foreign keys. (Already in schema, but app-side validation also needed.) |
| TC19 | **Cron / scheduled jobs** (e.g., monthly draft generation) | 🟡 | Currently runs on app open. What if user doesn't open for 6 months? Drafts incomplete. Need server-side cron via Supabase Edge Functions. |
| TC20 | **Webhook / event triggers** for cross-table updates | 🟢 | When transaction settled, auto-update affected reports cache. |

### 22.5 UI / UX Gaps

| # | Gap | Severity |
|---|---|---|
| U1 | **First-time setup wizard** | 🟡 |
| U2 | **Global search** across all modules | 🟡 |
| U3 | **Smart search** ("rent last month", "amazon purchases") | 🟢 |
| U4 | **Bulk operations** (multi-select edit/delete/categorize) | 🟡 |
| U5 | **CSV import** for transactions (from bank statement) | 🟡 |
| U6 | **Keyboard shortcuts** | 🟢 |
| U7 | **Print stylesheets** for reports | 🟡 |
| U8 | **Localization** (Hindi, Gujarati, etc.) | 🟢 |
| U9 | **Help / FAQ** built-in | 🟢 |
| U10 | **Changelog** / what's new | 🟢 |
| U11 | **Quick add** from anywhere (keyboard shortcut + global modal) | 🟢 |
| U12 | **Skeleton loaders** during data fetch | 🟡 |
| U13 | **Offline indicator** when network down | 🟡 |
| U14 | **Onboarding tour** for new users | 🟢 |
| U15 | **Data import from other apps** (Splitwise, Walnut, Mint) | 🟢 |

### 22.6 ~~Compliance / Statutory Gaps (India-specific)~~ — REMOVED

Per Decision X5. The portal is for personal awareness, not statutory compliance. Tax-tag summary in Reports remains for the user's own reference.

---

## 23. My Top 10 Recommendations (Priorities — v5, post-decisions)

Re-ranked after user decisions (X1–X6 removed declined items):

1. **A12 Audit Trail** (immutable log) — Critical for cloud + multi-profile safety
2. **TC8 IndexedDB migration** — localStorage caps at 5MB; will hit limit with realistic usage
3. **§5.14 Reports module** (Net Worth Statement, Income & Expense, Cash Flow, Ledger, Day Book, Analytical reports) — User explicitly wants
4. **§17 Credit Card Statement view** — User requested
5. **§5.15 Export module** + **Encrypted backups** — User requested + security
6. **§5.11 Customizable Categories** in Settings — User requested
7. **§5.7 Draft/Settled transaction workflow** + **§5.8 Recurring auto-drafts** — Major UX requirement
8. **§5.4 Loan amortization + edit (rate/tenure/EMI/prepayment recalc)** — User requested
9. **TC2 Optimistic locking** + **Auth (§5.0)** — Required before cloud sync
10. **§9 Professional UI (Lucide icons, no emojis, design system)** — User requested

Everything else iterates afterward.

---

## 24. Open Questions (v5 — post-decisions)

Items previously declined removed. Renumbered for clarity.

| # | Question | My recommendation |
|---|---|---|
| Q1 | Sprint 1 vs all-at-once? | **Sprint 1 first** (local-first foundation rebuild) → you test the UX → then backend in Sprint 2 |
| Q2 | Backend choice: Supabase or Firebase? | **Supabase** (Postgres + RLS = best fit for finance data) |
| Q3 | Icon library: Lucide vs alternatives? | **Lucide** — clean, professional, free, MIT |
| Q4 | Default profile name on signup? | "Personal" (user can rename anytime) |
| Q5 | Draft default behavior: future date → Draft, past/today → Settled? | Yes |
| Q6 | Recurring auto-draft horizon? | 3 months default, user-configurable in Settings |
| Q7 | Settling a draft on a different date than planned — record both planned and actual? | Yes — keep planned date for audit, add `settledAt` |
| Q8 | Prepayment default strategy: reduce tenure or reduce EMI? | **Reduce tenure** (saves more interest) — but always ask user |
| Q9 | Loan amortization: store schedule or compute from event log? | **Always compute** from event log — single source of truth |
| Q10 | Per-profile color/icon for visual distinction? | Yes — small accent in header indicates active profile |
| Q11 | Allow profile sharing later (e.g., with spouse)? | Backlog — needs separate permissions model |
| Q12 | Mobile UI: build as part of v3 or after backend? | Adaptive CSS in v3; truly distinct mobile features in Sprint 5 |
| Q13 | Categories: allow custom icon + color per category? | Yes — small selector in category editor |
| Q14 | Tax flags: hard-coded list or user-editable? | **User-editable** (in case you need custom flags) |
| Q15 | Auto-cleanup stale drafts (older than 90 days)? | Don't auto-delete; just flag with a notification banner |
| Q16 | Fiscal Year start month? | **April** (Indian default) — user can override in Settings |
| Q17 | Reports: live computation vs caching? | Live for small datasets (<5k txns), cached for big |
| Q18 | Export: client-side vs server-side? | **Client-side** for everything (no Edge Function cost on free tier) |
| Q19 | Goals (we removed) — bring back as just "Investment Purpose" tag? | Yes — simple tag on Investments, not a full module |
| Q20 | Audit log retention — 90 days / 1 year / forever? | **1 year** rolling |
| Q21 | Reminders & Tasks module (non-money: "Renew DL") — build or skip? | **Skip for now**, backlog |
| Q22 | Investment buy/sell with FIFO cost basis (for accurate sell-side tracking)? | **Optional** — defer unless you sell investments often |
| Q23 | Reconciliation flag per transaction? | Defer to Sprint 4 — not urgent |
| Q24 | Period locking (lock past dates after FY end)? | Defer — only matters once you have year-end reports stable |
| Q25 | Net worth daily snapshots for trend chart? | Yes — small cost, big visual win |
| Q26 | Investment "Update value" — manual only or fetch live NAV later? | Manual now; live NAV fetching = Phase 4 |
| Q27 | Currency rounding precision (0 / 2 decimals)? | **2 decimals** stored, **0 in display** by default (cleanest) |

---

## 25. Phase Roadmap (v5 — simplified post-decisions)

### Sprint 1 — Foundation Rebuild (local-first)
- Migrate state from localStorage → **IndexedDB**
- **Audit trail** (immutable log, append-only)
- **Fiscal Year setting** (Apr–Mar default)
- **Customizable Categories & Subcategories** editor in Settings
- **Lucide icons** (replace all emojis)
- **Professional CSS rewrite** (typography, spacing, color tokens, components)
- **Draft / Settled** transaction workflow
- **Recurring auto-drafts** engine

### Sprint 2 — Loans + Cards Depth
- Loan **full amortization schedule** view
- Loan **Edit Rate / Edit Tenure / Edit EMI** with recalc
- Loan **Prepayment with reduce-tenure vs reduce-EMI** choice
- **Credit Card Statement view** (per-cycle detail with summary, rewards, comparison)
- Bank statement reconciliation (compare app balance vs uploaded bank statement)

### Sprint 3 — Reports & Export
- **Reports module**: Net Worth Statement, Income & Expense Report, Cash Flow, Ledger, Day Book
- Analytical reports: Net Worth Trend, Category-wise, Payee Analysis, Monthly Comparison, Tax-tag Summary
- Schedules: Loan Amortization, Insurance Renewal, Investment Performance
- **Export module**: PDF / Excel / CSV / encrypted JSON
- Print stylesheets

### Sprint 4 — Backend (Supabase + Auth)
- Supabase project setup (you create account, I provide schema + walk you through)
- Schema deployment + RLS policies
- Auth screens (login, signup, profile picker, password reset)
- **Multi-profile management** (Tally-style)
- Cloud sync layer (replace IndexedDB calls with Supabase)
- **Optimistic locking** + conflict resolution
- Real-time multi-device sync

### Sprint 5 — Mobile-distinct UI
- True mobile layouts (bottom sheets, swipe-to-delete, FAB)
- PWA install + manifest
- Service Worker (offline functionality)
- Push notifications (web push API)
- Touch-optimized interactions

### Sprint 6 — Iteration & polish
- Investment buy/sell with FIFO cost basis (if you want)
- Split transactions
- Receipt / document attachments
- Bulk import (CSV)
- Reconciliation flag per txn
- Period locking
- Net worth daily snapshots + trend chart

### Backlog (do later if needed)
- Multi-currency
- Reminders & Tasks
- Document vault (encrypted)
- Localization (Hindi etc.)
- 2FA TOTP
- Email reminders
- Asset register (car, jewelry, property)

---

---

## 26. Financial Health Ratios & Formulas (NEW MODULE)

A new dedicated module: **Financial Health** — analyzes your data using established personal finance ratios and gives you a quick read of where you stand vs benchmarks.

Sits in sidebar under **Overview** group: Dashboard → **Financial Health** → Reports.

### 26.1 The full ratio menu

Below are the standard personal finance ratios. Each has: **formula**, **benchmark**, **what it tells you**, and a note on whether we can auto-compute it from existing data.

---

#### A. SOLVENCY RATIOS (can you sustain your debt?)

##### A1. Debt-to-Income Ratio (DTI)
```
DTI = (Total Monthly Debt Payments / Gross Monthly Income) × 100
    = (All EMIs + Min Credit Card Payment) / Monthly Income × 100
```

| Score | Range |
|---|---|
| 🟢 Excellent | < 20% |
| 🟢 Healthy | 20–36% |
| 🟡 Manageable | 36–43% |
| 🔴 Stretched | 43–50% |
| 🔴 Danger | > 50% |

**What it means:** What portion of your income goes to debt servicing. Banks use this to decide if you qualify for new loans. Lower = more borrowing capacity, more breathing room.

**Auto-computable:** ✅ Yes (sum of Loan EMIs + Card minimum payments / Monthly income from settled txns)

---

##### A2. EMI-to-Take-Home Ratio
```
EMI Ratio = Total Monthly EMIs / Monthly Take-home (Net) Income × 100
```

| Score | Range |
|---|---|
| 🟢 Comfortable | < 30% |
| 🟢 Acceptable | 30–40% |
| 🟡 Stretched | 40–50% |
| 🔴 Risky | > 50% |

**What it means:** Indian banks typically won't approve new loans if your existing EMIs exceed 50% of take-home. Stay under 40% for comfortable lifestyle.

**Auto-computable:** ✅ Yes

---

##### A3. Debt-to-Asset Ratio
```
Debt-to-Asset = Total Liabilities / Total Assets × 100
```

| Score | Range |
|---|---|
| 🟢 Excellent | < 30% |
| 🟢 Healthy | 30–50% |
| 🟡 Watch | 50–70% |
| 🔴 Concerning | 70–100% |
| 🔴 Insolvent | > 100% |

**What it means:** How much of your asset value is funded by debt. Lower = more financial cushion. >100% means you owe more than you own (negative net worth).

**Auto-computable:** ✅ Yes

---

##### A4. Solvency Ratio (Net Worth Ratio)
```
Solvency = Net Worth / Total Assets × 100
       = (1 − Debt-to-Asset%) effectively
```

| Score | Range |
|---|---|
| 🟢 Strong | > 50% |
| 🟡 Average | 30–50% |
| 🔴 Weak | < 30% |
| 🔴 Negative | < 0% |

**What it means:** What % of your assets you actually OWN (vs financed). Inverse view of A3.

**Auto-computable:** ✅ Yes

---

##### A5. Debt Service Coverage Ratio (DSCR) — for rental/income generators
```
DSCR = Net Operating Income / Total Debt Service
```

Mainly relevant if you own rental properties. **DSCR > 1.25** is typically required by banks.

**Auto-computable:** Optional — only if user has rental income separately tracked.

---

#### B. LIQUIDITY RATIOS (can you handle an emergency?)

##### B1. Emergency Fund Ratio (Liquidity Ratio)
```
EFR = Liquid Assets / Monthly Essential Expenses
```
Where **Liquid Assets** = Bank Savings + Cash + Wallet (excludes FD/RD, investments)
And **Essential Expenses** = recurring monthly EMIs + Rent + Utilities + Groceries + Insurance + Education (excludes discretionary)

| Score | Range |
|---|---|
| 🔴 Vulnerable | < 1 month |
| 🟡 Below recommended | 1–3 months |
| 🟢 Recommended (single income) | 3–6 months |
| 🟢 Excellent (variable income) | 6–12 months |
| 🟡 Excessive | > 12 months (consider investing extra) |

**What it means:** How many months you can survive without income. If you lose your job, get sick, or face an emergency — this is your runway.

**Auto-computable:** ✅ Yes (we have category-wise expense data + liquid balance per Section 5.2)

---

##### B2. Liquid Net Worth
```
Liquid Net Worth = Liquid Assets − Current Liabilities (credit card outstanding + bills)
```

**What it means:** What you'd actually have if you settled all immediate obligations today.

**Auto-computable:** ✅ Yes

---

##### B3. Cash Reserve Ratio
```
Cash Reserve = (Cash + Bank Savings + Liquid Funds) / Annual Income × 100
```

| Score | Range |
|---|---|
| 🟢 Comfortable | > 15% |
| 🟡 Watch | 5–15% |
| 🔴 Low | < 5% |

**What it means:** Cash buffer relative to your earning. Different from emergency fund — measured against income, not expenses.

**Auto-computable:** ✅ Yes

---

#### C. SAVINGS / GROWTH RATIOS (are you building wealth?)

##### C1. Savings Rate
```
Savings Rate = (Total Income − Total Expenses) / Total Income × 100
```
Period: monthly, quarterly, or annual

| Score | Range |
|---|---|
| 🔴 Insufficient | < 10% |
| 🟡 Basic | 10–20% |
| 🟢 Healthy | 20–30% |
| 🟢 Strong | 30–50% |
| 🟢 FIRE-level | > 50% (Financial Independence Retire Early) |

**What it means:** The single most important ratio for long-term wealth. A high savings rate solves many problems.

**Auto-computable:** ✅ Yes (from settled transactions)

---

##### C2. Investment Rate
```
Investment Rate = Money Invested / Total Income × 100
```
Where Money Invested = SIP + lump-sum investments + EPF + insurance investment portion + tax-saver FDs

| Score | Range |
|---|---|
| 🟢 Aggressive | > 25% |
| 🟢 Healthy | 15–25% |
| 🟡 Basic | 5–15% |
| 🔴 Low | < 5% |

**What it means:** Distinct from savings rate. You can have a high savings rate but if it sits in low-yield bank accounts, you're not building real wealth.

**Auto-computable:** ✅ Yes (transactions with category="Investment")

---

##### C3. Wealth Ratio (Income Replacement)
```
Wealth Ratio = Total Investments / Annual Expenses
```

| Score | Range |
|---|---|
| Starter | < 1× |
| Building | 1–5× |
| Established | 5–10× |
| Independent | 10–20× |
| 🟢 Financially Free | > 25× (4% rule — covers retirement) |

**What it means:** How many years you could live off your investments. 25× is the classic "FI number" — at that point investment returns (~4%) can sustain your lifestyle indefinitely.

**Auto-computable:** ✅ Yes

---

#### D. NET WORTH BENCHMARKS

##### D1. Stanley-Danko Wealth Score (PAW/UAW)
From *The Millionaire Next Door*. Compares your net worth to what someone your age and income "should" have.

```
Expected Net Worth = (Age × Pre-tax Annual Income) / 10
```

Then categorize:
| Category | Definition |
|---|---|
| **UAW** (Under Accumulator of Wealth) | Actual NW < 0.5 × Expected |
| **AAW** (Average Accumulator) | 0.5–2× Expected |
| **PAW** (Prodigious Accumulator) | > 2× Expected |

**What it means:** A rough yardstick — are you ahead of the wealth-building curve for your age and income?

**Auto-computable:** ✅ Yes (we have NW, income; need DOB on "Self" person)

---

##### D2. Net Worth-to-Income Ratio
```
NW/Income = Net Worth / Annual Income
```

Age-based benchmarks (Fidelity-style guidance):

| Age | Target NW / Annual Income |
|---|---|
| 30 | 1× |
| 35 | 2× |
| 40 | 3× |
| 45 | 4× |
| 50 | 6× |
| 55 | 7× |
| 60 | 8× |
| 67 (retirement) | 10× |

**Auto-computable:** ✅ Yes

---

#### E. CREDIT HEALTH

##### E1. Credit Utilization Ratio
```
CUR = Total Card Outstanding / Total Credit Limit × 100
```
(Per card AND aggregate.)

| Score | Range |
|---|---|
| 🟢 Excellent | < 10% |
| 🟢 Good | 10–30% |
| 🟡 Watch | 30–50% |
| 🔴 High | 50–80% |
| 🔴 Maxed | > 80% |

**What it means:** Heavily affects your credit score (CIBIL). Keep below 30% always; below 10% if you're trying to improve credit score before a big loan application.

**Auto-computable:** ✅ Yes (we have card data)

---

##### E2. Card Payment Health
```
Card Payment Health = (Total Card Settled / Total Card Spent) × 100
```
Over last 12 months. Closer to 100% = always paying in full = no interest charges.

| Score | Range |
|---|---|
| 🟢 Always paid | > 95% |
| 🟡 Mostly paid | 80–95% |
| 🔴 Carrying debt | < 80% |

**Auto-computable:** ✅ Yes (Settlement transactions / Expense transactions on cards)

---

#### F. INSURANCE ADEQUACY

##### F1. Life Insurance Adequacy
```
Required Life Cover = (10 to 15) × Annual Income + Outstanding Loans − Liquid Assets
Coverage Ratio = Actual Life Cover / Required Life Cover × 100
```

Rules of thumb:
- **10×** annual income (minimum)
- **15×** if you have young dependents
- Add outstanding loans (so family can pay them off)
- Subtract existing liquid assets (which already provide cushion)

| Score | Range |
|---|---|
| 🟢 Adequate | > 90% |
| 🟡 Underinsured | 50–90% |
| 🔴 Critically underinsured | < 50% |

**Auto-computable:** ✅ Yes (we have life policies, loans, income, liquid assets)

---

##### F2. Health Insurance Adequacy
```
Per-person target: ₹5L minimum, ₹10L recommended, ₹25L for senior parents
Family Floater: Sum insured ≥ 1.5× annual income (rule of thumb)
```

Less formula-driven; we surface for review rather than auto-grade.

**Auto-computable:** Partial (compare actual to thresholds)

---

#### G. INVESTMENT QUALITY

##### G1. Asset Allocation
```
Equity %    = (Equity Investments + Equity MF) / Total Investments × 100
Debt %      = (FD + RD + Debt MF + Bonds + PPF + EPF) / Total Investments × 100
Gold %      = (Physical + SGB + Gold MF) / Total Investments × 100
Real Estate % = (Property value if tracked) / Total Investments × 100
```

##### G2. Rule of 110 (Age-Based Equity Allocation)
```
Recommended Equity % = 110 − Age
```
e.g., Age 35 → recommended ~75% equity
Age 50 → ~60% equity
Age 65 → ~45% equity

| Status | Difference from recommended |
|---|---|
| 🟢 Aligned | ±5% |
| 🟡 Over/underweight | 5–15% |
| 🔴 Significant deviation | > 15% |

**Auto-computable:** ✅ Yes (need age from People + investment types)

---

##### G3. Investment Return (XIRR / CAGR)
```
CAGR (lumpsum) = ((Current Value / Invested) ^ (1/Years)) − 1
XIRR (SIP, irregular) = uses transaction dates and amounts; solved iteratively
```

Compare against:
- Inflation (6% in India typical)
- FD rates (7%)
- Equity benchmark (Nifty 50 = ~12% long term)

| Score for equity investments | Range |
|---|---|
| 🟢 Beating benchmark | > 14% CAGR |
| 🟢 Acceptable | 10–14% |
| 🟡 Underperforming | 6–10% |
| 🔴 Losing to inflation | < 6% |

**Auto-computable:** ✅ Yes if we track buy/sell with dates (need investment cost basis — currently optional per Q22)

---

#### H. HOUSING (if applicable)

##### H1. Housing Expense Ratio (Front-end DTI)
```
HER = Housing Costs / Gross Monthly Income × 100
```
Housing Costs = Rent OR (Home Loan EMI + Property Tax + Maintenance + Home Insurance)

| Score | Range |
|---|---|
| 🟢 Healthy | < 28% |
| 🟡 Watch | 28–35% |
| 🔴 Stretched | > 35% |

**What it means:** US 28/36 rule — housing under 28%, total debt under 36%. Indian standard slightly more lenient (banks allow up to 45%).

**Auto-computable:** ✅ Yes (Housing category from settled txns)

---

#### I. RETIREMENT READINESS

##### I1. Retirement Readiness Ratio
```
Retirement Corpus Needed = Annual Retirement Expenses × 25
                         (or 30× for longer life expectancy)

Readiness % = Current Retirement Corpus / Retirement Corpus Needed × 100
```

Where Retirement Corpus = EPF + PPF + NPS + Retirement-tagged investments
And Annual Retirement Expenses = (Current monthly essential expenses × 12) × inflation adjustment

| Status | Readiness % at current age |
|---|---|
| Behind | < age/65 × 100% |
| On track | = age/65 × 100% (proportional) |
| Ahead | > age/65 × 100% |

**Auto-computable:** Partial (need retirement target + current age)

---

#### J. CASH FLOW QUALITY

##### J1. Discretionary Spending Ratio
```
Discretionary % = (Non-essential Expenses / Total Expenses) × 100
```
Non-essential = Entertainment + Shopping + Travel + Dining out + Subscriptions

| Score | Range |
|---|---|
| 🟢 Disciplined | < 15% |
| 🟢 Balanced | 15–25% |
| 🟡 Lifestyle creep | 25–40% |
| 🔴 Excessive | > 40% |

**Auto-computable:** ✅ Yes (category-based)

---

##### J2. Free Cash Flow
```
Free Cash Flow = Monthly Income − Essential Expenses − EMIs
```

This is money truly available for SIPs, prepayments, or building emergency fund.

**Auto-computable:** ✅ Yes

---

### 26.2 The Financial Health Page (Proposed UI)

```
┌─────────────────────────────────────────────────────────────┐
│ Financial Health                          [Period: FY26 ▼]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│         ┌─────────────────────────────────┐                 │
│         │      OVERALL SCORE              │                 │
│         │         78 / 100                │                 │
│         │      Healthy ✓                  │                 │
│         │  (12 of 16 metrics in green)    │                 │
│         └─────────────────────────────────┘                 │
│                                                             │
│  SOLVENCY                                                   │
│  ┌────────────────────────┐ ┌─────────────────────────┐    │
│  │ Debt-to-Income          │ │ EMI-to-Income           │    │
│  │ ●─────────○──────────   │ │ ●────────────○───────   │    │
│  │   38%   🟡 Manageable   │ │   42%  🟡 Stretched     │    │
│  │ Benchmark: <36%         │ │ Benchmark: <40%         │    │
│  │ Drill-down →            │ │ Drill-down →            │    │
│  └────────────────────────┘ └─────────────────────────┘    │
│                                                             │
│  LIQUIDITY                                                  │
│  ┌────────────────────────┐ ┌─────────────────────────┐    │
│  │ Emergency Fund          │ │ Liquid Net Worth        │    │
│  │ 4.2 months              │ │ ₹1,30,200               │    │
│  │ 🟢 Recommended (3-6)    │ │ 🟢 Positive             │    │
│  └────────────────────────┘ └─────────────────────────┘    │
│                                                             │
│  SAVINGS & GROWTH                                           │
│  ┌────────────────────────┐ ┌─────────────────────────┐    │
│  │ Savings Rate            │ │ Investment Rate         │    │
│  │ 23%   🟢 Healthy        │ │ 18%   🟢 Healthy        │    │
│  └────────────────────────┘ └─────────────────────────┘    │
│                                                             │
│  ... (continue with all sections)                           │
│                                                             │
│  RECOMMENDATIONS                                            │
│  • Reduce EMI burden — consider prepaying Car Loan          │
│  • Increase emergency fund by ₹40k to reach 6-month target  │
│  • Asset allocation: 82% equity vs 75% recommended (age 35) │
│  • Term life cover ₹50L vs recommended ₹1.2Cr (₹70L gap)    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 26.3 Scoring methodology

- Each metric scored Green (1.0) / Yellow (0.5) / Red (0.0)
- Some metrics weighted higher (Savings Rate × 2, Emergency Fund × 1.5)
- Overall score = weighted average × 100
- Grade bands: 80+ Excellent · 65-80 Healthy · 50-65 Watch · <50 Needs Attention

### 26.4 Data inputs required

Most of the above can be auto-computed from existing modules. We need to ADD:

| Data Need | Where |
|---|---|
| Age (from DOB) | People → "Self" entry |
| Essential vs Discretionary classification | Categories → add `essential: boolean` flag |
| Retirement age target | Settings (default 60) |
| Investment "purpose" tag (Retirement / Goal / Tax / Wealth) | Investments — new optional field |

### 26.5 Implementation note

Build this as **Sprint 3 deliverable** alongside Reports — they share the same compute layer (reading settled transactions, accounts, loans, etc.).

### 26.6 What I'm NOT including

I've deliberately left out:
- **Tax efficiency ratio** (would need TDS — declined in X2)
- **Debt service coverage for income-generating assets** (relevant only if rental — niche)
- **Currency hedging ratios** (no multi-currency)
- **Goal funding ratio** (Goals module declined)

---

### 26.7 Computation Audit — Per-Ratio Data Check

I went through every ratio in §26.1 to verify we have the inputs from existing modules. Findings below.

**Legend:** ✅ = computable today · ⚠️ = computable with approximation · ❌ = blocked, needs new field

| Ratio | Inputs Needed | Status | Notes |
|---|---|---|---|
| **A1 Debt-to-Income** | All EMIs + Card min payment / Monthly income | ⚠️ | Loan EMIs ✅. Card min payment: we **dropped the field in v3** — need to either re-add or derive (RBI standard is 5% of outstanding). Income = settled income txns. Note: we use NET income (no TDS per X2). |
| **A2 EMI-to-Take-Home** | Total EMIs / Net income | ✅ | All present |
| **A3 Debt-to-Asset** | Liabilities / Assets | ✅ | Loan outstanding + Card outstanding / (Liquid + Deposits + Investments) |
| **A4 Solvency Ratio** | NW / Assets | ✅ | Derived from A3 |
| **A5 DSCR (rental)** | Rental income / Loan service | ✅ | Income category "Rental" exists; only relevant if user has rental income |
| **B1 Emergency Fund Ratio** | Liquid assets / Monthly **essential** expenses | ❌ | Categories don't have an `essential: boolean` flag. **GAP.** |
| **B2 Liquid Net Worth** | Liquid Assets − Current Liabilities | ✅ | Current liabilities = card outstanding |
| **B3 Cash Reserve Ratio** | Cash + Savings / Annual income × 100 | ✅ | Liquid accounts only |
| **C1 Savings Rate** | (Income − Expenses) / Income | ✅ | From settled txns |
| **C2 Investment Rate** | Money Invested / Income | ⚠️ | Captures transactions with category="Investment" ✅. But misses ULIP/Endowment premium portions ⚠️. Acceptable approximation. |
| **C3 Wealth Ratio** | Investments / Annual Expenses | ✅ | Sum of investment.currentValue + FD/RD balances |
| **D1 Stanley-Danko** | Age × Income / 10 | ❌ | Need DOB on "Self" person. **GAP** if no Self person with DOB. |
| **D2 NW / Annual Income** | NW / Income | ⚠️ | Needs age for benchmark comparison. Same gap as D1. |
| **E1 Credit Utilization** | Card outstanding / Total limit | ✅ | All present |
| **E2 Card Payment Health** | Settlements / Card expenses (12 months) | ✅ | All from settled txns |
| **F1 Life Insurance Adequacy** | Sum of Term Life cover / (10–15× Income + Loans − Liquid) | ✅ | Filter `insurance.type === "Term Life"`. Question: include Endowment/ULIP death benefits? My recommendation: only Term Life is pure cover. |
| **F2 Health Insurance Adequacy** | Sum insured per person / target per person | ⚠️ | Floater + individual interaction is tricky. For each person: max(individual policies they're on, family floater they're on). Approximation acceptable. |
| **G1 Asset Allocation %** | Equity / Debt / Gold / RE split of investments | ❌ | Investment `type` doesn't distinguish Equity vs Debt MF. **GAP** — need `assetClass` field. |
| **G2 Rule of 110** | 110 − Age = recommended equity % | ❌ | Needs age. Same gap as D1. |
| **G3 CAGR / XIRR** | Initial invested + current value + dates | ⚠️ | Lumpsum: CAGR easy ✅. SIP XIRR needs per-installment dates — currently we just have aggregated `invested`. Approximation: assume monthly SIP from start date and compute XIRR numerically. Accurate XIRR requires Q22 (per-SIP transaction tracking). |
| **H1 Housing Expense Ratio** | Housing costs / Gross income | ✅ | Housing category includes rent + home loan EMI + property tax + maintenance |
| **I1 Retirement Readiness** | Retirement corpus / Required corpus | ❌ | Need: (a) retirement age in Settings (b) which investments are retirement-tagged. **GAP** — need investment `purpose` field. |
| **J1 Discretionary Spending %** | Non-essential / Total expenses | ❌ | Same `essential` flag gap as B1 |
| **J2 Free Cash Flow** | Income − Essential expenses − EMIs | ❌ | Same gap |

**Summary:** 14 of 24 ratios fully computable today. 4 work with acceptable approximations. **6 are blocked on missing fields**, but the gaps cluster around just 5 additions.

---

### 26.8 Required Spec Additions (to unblock all ratios)

The 5 additions needed:

#### Addition 1 — `essential: boolean` flag on Categories
**Where:** Categories editor (§5.11)
**Affects:** B1 Emergency Fund Ratio, J1 Discretionary Spending, J2 Free Cash Flow, I1 Retirement Corpus calc
**Default essentials:** EMI · Housing · Utilities · Groceries · Health · Insurance Premium · Education · Tax
**Default non-essentials:** Food (eating out) · Entertainment · Shopping · Travel · Subscription · Personal
**UI:** Checkbox per category in the Categories editor

#### Addition 2 — Re-add `minPayment` on Cards (OR derive)
**Where:** Credit Cards module (§5.3)
**Affects:** A1 DTI
**Two options:**
- **Option A:** Add back `minPayment` as a per-card field (input by user from card statement)
- **Option B:** Derive as 5% of current outstanding (RBI standard for India)
**Recommendation:** Option B (auto-derived). Cleaner UX, accurate enough. Setting in Settings: `cardMinPaymentPct` (default 5%).

#### Addition 3 — Enforce DOB on "Self" Person
**Where:** People module (§5.1)
**Affects:** D1 Stanley-Danko, D2 NW/Income benchmark, G2 Rule of 110, I1 Retirement Readiness
**Approach:** Soft-require DOB when relationship = "Self". App shows a prompt on Financial Health page: "Set your date of birth to unlock age-based metrics" with quick-link to People.
**No hard block** — ratios that need age just show "Set DOB to enable" if missing.

#### Addition 4 — `purpose` tag on Investments
**Where:** Investments module (§5.6)
**Affects:** I1 Retirement Readiness
**Field:** `purpose` enum (optional)
**Values:** Retirement · Emergency · Tax Saving · Specific Goal · Wealth Building · Liquidity · Other
**Default:** Auto-suggest based on type (EPF/PPF/NPS → Retirement; ELSS → Tax Saving)
**UI:** Single dropdown in Investment modal

#### Addition 5 — `assetClass` field on Investments
**Where:** Investments module (§5.6)
**Affects:** G1 Asset Allocation
**Field:** `assetClass` enum (optional but auto-defaulted)
**Values:** Equity · Debt · Hybrid · Gold · Real Estate · Cash · Crypto · Other
**Default mapping from type:**
- Mutual Fund - SIP / Lumpsum → user picks (default Equity)
- Stock / ETF → Equity (Bond ETF user overrides to Debt)
- Gold / SGB → Gold
- EPF / PPF / NPS / Bonds → Debt
- Crypto → Crypto
- Fixed Deposit (in Accounts) → Debt (already implicit)

#### Addition 6 — New Settings entries
**Where:** Settings (§5.11)
**Affects:** I1 Retirement, G3 XIRR benchmark
**New fields:**
- `retirementAge` (number, default 60)
- `inflationRate` (number, default 6.0 — for India)
- `equityBenchmarkReturn` (number, default 12.0 — Nifty 50 long-term)
- `cardMinPaymentPct` (number, default 5.0 — RBI standard)

---

### 26.9 Updated Module Field Changes

**Categories** (§5.11) — add field:
| Field | Type | Default | Notes |
|---|---|---|---|
| essential | boolean | depends on name | Checkbox in editor. Used for emergency fund + free cash flow computations. |

**Investments** (§5.6) — add fields:
| Field | Type | Default | Notes |
|---|---|---|---|
| purpose | enum | auto-suggest | Retirement / Emergency / Tax Saving / Goal / Wealth / Liquidity / Other |
| assetClass | enum | auto-suggest | Equity / Debt / Hybrid / Gold / Real Estate / Cash / Crypto / Other |

**Settings** (§5.11) — add fields:
| Field | Type | Default | Notes |
|---|---|---|---|
| retirementAge | number | 60 | For retirement readiness |
| inflationRate | number | 6.0 | For corpus calcs |
| equityBenchmarkReturn | number | 12.0 | For investment performance comparison |
| cardMinPaymentPct | number | 5.0 | For DTI computation when card has outstanding |

**People** (§5.1) — no schema change; just soft-prompt for DOB on Self person.

**Cards** (§5.3) — no schema change (use derived min payment from `cardMinPaymentPct`).

---

### 26.10 Approximations We're Accepting (document for honesty)

These ratios will work but won't be 100% accurate. Listed for transparency.

| Ratio | Approximation | Why |
|---|---|---|
| C2 Investment Rate | Counts only category="Investment" transactions; ULIP/Endowment investment portion missed | Splitting investment vs protection portion of unit-linked policies is complex; skip for now |
| G3 XIRR (SIPs) | Approximated using monthly contributions from start date | Per-SIP transaction tracking (Q22) would give true XIRR; defer unless requested |
| A1 DTI uses Net (not Gross) income | We don't track TDS (X2) | Indian banks usually look at gross; our number will be slightly different |
| F1 Life Cover Adequacy | Only Term Life counted; Endowment/ULIP death benefit excluded | Term gives pure cover; mixing in investment-style policies distorts the metric |
| F2 Health Insurance | Floater + individual computed per-person but no co-pay/deductible factored | Simple sum-insured comparison; banks/CAs use more nuanced models |
| I1 Retirement | Assumes essential expenses stay constant in real terms | Doesn't model lifestyle inflation separately |
| G1 Asset Allocation | Only invested-type assets; doesn't include real estate, gold jewelry, vehicles | Asset Register (CX6) backlog item |

---

### 26.11 Recommendation: Build Order

1. **First**, add the 5 spec additions above (Categories essential flag, investment purpose/assetClass, settings, soft-DOB prompt). These are tiny — 1-2 day of work.
2. **Then**, build the Financial Health page itself in Sprint 3 alongside Reports.
3. Ratios start outputting accurate values immediately; some (XIRR) improve later if you opt into Q22.

---

## 27. Updated Module List (with Financial Health)

| # | Module | Status |
|---|---|---|
| 5.0–5.11 | (as before) | |
| 5.14 | Reports | NEW |
| 5.15 | Export & Backup | NEW |
| **5.16** | **Financial Health** (§26) | NEW |

**Total active modules: 15**

---

## How we'll use this document

1. **You review this doc end-to-end**, mark anything you want changed
2. **Once approved**, this is the spec we build to
3. **Any new request** → updates this doc first, then code
4. **The HTML implementation always matches** this spec

When you reply, please:
- Confirm or correct Section 1 / Section 0 (Decisions Log)
- Answer the open questions in Section 24
- Tell me if all the ratios in §26 are useful, or which ones to skip
- Tell me which Sprint to start with
