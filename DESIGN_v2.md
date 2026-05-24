# Finance Portal v2 — Design Specification

> **Status:** Design proposal — awaiting approval before build.
> **Goal:** Advanced personal finance management with multi-account flows, credit-card billing cycles, cash-flow projection, and rich loan/insurance tracking.

---

## 1. What changes vs v1

| Area | v1 | v2 |
|------|----|----|
| Transactions | Income / Expense | **4 types**: Income, Expense, Settlement, Internal Transfer |
| Accounts | Standalone records | Linked to every transaction; balance auto-updates |
| Credit Cards | Limit + used | Full billing cycle: bill gen, due date, statement, settlement |
| Budget | Monthly spending limit | **Renamed "Projection"** — forward cash-flow forecast |
| Goals | Present | **Removed** |
| Loans | Basic balance/EMI | Types, EMI payment from account, foreclosure, close |
| Insurance | Basic premium | Insured person, tenure, cover, full policy details |
| **NEW: Recurring Templates** | — | Define salary, EMI, rent once → feeds Projection |
| **NEW: People** | — | Track family members for insurance / shared expenses |

---

## 2. Module Designs

### 2.1 Bank Accounts (expanded)

**Account types:** Savings · Current · Salary · Fixed Deposit · Recurring Deposit · Wallet · Cash · NRE/NRO · Demat (cash) · Other

**Fields:**
- Account name (display label, e.g. "HDFC Salary")
- Bank / Provider
- Account number — **last 4 digits only**
- IFSC / Branch (optional)
- Type
- Joint holder name (optional)
- Nominee (optional)
- Opening date (optional)
- Current balance — auto-updated by transactions, manual override allowed
- Interest rate
- Minimum balance requirement (alert if below)
- For FD/RD: maturity date, maturity amount, interest payout (cumulative/monthly/quarterly)
- Linked debit card last 4 (optional)
- Statement cycle day (e.g. 1st of month)
- Status: Active / Closed / Dormant
- Notes

**Features:**
- Account-wise passbook view (all transactions from/to this account)
- Auto-balance from transactions (no more manual updates needed unless you want to reconcile)
- Low-balance alert if drops near minimum balance
- FD/RD maturity countdown
- Closed accounts hidden from dropdowns but preserved for history

---

### 2.2 Credit Cards (full billing cycle)

**Fields:**
- Card name + bank
- Card network (Visa / Mastercard / Rupay / Amex / Diners)
- Last 4 digits
- Credit limit
- Available limit (auto-computed: limit − outstanding)
- **Bill generation day** (e.g. 5th of month)
- **Due day** (e.g. 25th of month)
- Annual fee + fee waiver criteria
- Interest rate (for revolving credit)
- Reward type (cashback / points / miles) + rate
- Linked account for auto-debit (optional)
- Status: Active / Blocked / Closed

**Per-cycle tracking (NEW):**
- Each billing cycle is a record: cycle start → cycle end → bill amount → due date → paid amount → status (Unbilled / Billed / Partial / Settled / Overdue)
- Statement upload (optional notes/reference)
- **Settlement transaction** marks the bill as paid (links to source account)
- **Minimum due** tracked per cycle
- Late payment / interest charges captured as expenses

**Features:**
- Dashboard widget: "₹X due on Y date" per card
- Auto-create unbilled cycle on bill gen day
- Convert outstanding to EMI option (creates a mini-loan)
- Card utilization gauge per card and overall
- Cycle history view (last 12 cycles)

---

### 2.3 Transactions (4 types)

**Type 1 — Income**
- Fields: date, amount, category (Salary/Freelance/Interest/Dividend/Rental/Refund/Gift/Other), **to account**, source/payer (optional), notes
- Increases the destination account balance

**Type 2 — Expense**
- Fields: date, amount, category, subcategory (optional), **from account/card**, payee/merchant (optional), notes, receipt attachment (optional later)
- Decreases the source account balance OR adds to card outstanding

**Type 3 — Settlement (credit card payment)**
- Fields: date, amount, **from account → to card**, cycle reference (auto), notes
- Decreases account balance, decreases card outstanding
- Marks the card cycle as paid (full / partial)
- Does NOT count as an expense (it's already counted when you swiped the card)

**Type 4 — Internal Transfer**
- Fields: date, amount, **from account → to account** (or Cash), transfer mode (NEFT/IMPS/UPI/Cheque/Cash withdrawal), reference number, notes
- Decreases source, increases destination
- Does NOT count as income/expense — just moves money

**Filters & views:**
- By type, account, card, category, payee, date range
- Search by note/reference
- Bulk delete / bulk edit
- Quick add: "+" floating button → choose type → form

---

### 2.4 Loans (advanced)

**Loan types:** Home · Car · Personal · Education · Gold · Business · Mortgage · Credit Card EMI · Other

**Fields:**
- Loan name + lender
- Type
- Loan account number (last 4)
- Sanctioned principal
- Disbursement date
- Tenure (months)
- Interest rate + type (Fixed / Floating)
- EMI amount
- EMI date (day of month)
- **EMI paid from** — linked account
- Current outstanding
- Total paid (auto)
- Principal paid vs interest paid breakdown (computed)
- Prepayments history (list of {date, amount, account})
- Processing fee, insurance, other charges
- Status: Active · Foreclosed · Closed · Restructured

**Features:**
- EMI auto-debit creates a transaction on EMI date from linked account
- **Prepayment / Part-payment** flow: enter amount + account → reduces principal, recalculates EMI/tenure
- **Foreclosure flow**: shows current outstanding + foreclosure charges → records full settlement → marks loan Closed
- **Close loan** when balance reaches 0
- Edit loan: change EMI, rate, tenure (for floating rate changes)
- EMI schedule view (amortization table)
- Closed loans archived, viewable in history

---

### 2.5 Insurance (expanded)

**Insurance types:** Health · Term Life · Endowment · ULIP · Vehicle (Car/Bike) · Home · Travel · Personal Accident · Critical Illness · Other

**Fields:**
- Policy name
- Insurer (HDFC ERGO, LIC, etc.)
- Policy number (last 4 or masked)
- Type
- **Insured person(s)** — pick from People list (Self / Spouse / Child / Parent / Other). Multiple allowed for floater policies
- **Cover / Sum insured**
- Premium amount
- Premium frequency (Yearly / Half-yearly / Quarterly / Monthly / Single)
- **Tenure**: start date + end date
- Renewal date (next premium due)
- Premium paid from — linked account
- Nominee
- Agent name + contact (optional)
- Document upload reference (optional)
- Status: Active · Lapsed · Matured · Surrendered

**Features:**
- Renewal countdown badges (30 / 14 / 7 day warnings)
- Annual premium summary per family member
- Total cover per category (health, life)
- Premium payment auto-creates expense + reduces account balance

---

### 2.6 Projection (replaces Budget) — **the centerpiece**

A forward-looking cash flow forecast — day by day, account by account.

**How it works:**

1. **Recurring Templates** define your repeating money movements:
   - Salary: ₹75,000 → HDFC Salary, every 25th
   - Home Loan EMI: ₹18,500 ← HDFC Salary, every 1st
   - DTH Bill: ₹800 ← HDFC Salary, every 10th
   - Rent: ₹25,000 ← ICICI Savings, every 1st
   - Netflix: ₹649 ← HDFC Card, every 15th
   - Health Insurance: ₹24,000 ← HDFC Salary, every 12th of August

2. **One-off planned items** added manually:
   - "Wedding gift ₹15,000 on 30 May from ICICI"
   - "Goa trip ₹40,000 on 15 June from HDFC Salary"

3. **The Projection view** shows the merged timeline:

| Date | Description | Category | From Account | Amount | Account Balance After | All-Account Total |
|---|---|---|---|---|---|---|
| Today | (Starting balance) | — | HDFC Salary | — | ₹1,28,400 | ₹3,25,700 |
| 25 May | Salary | Income | → HDFC Salary | +75,000 | ₹2,03,400 | ₹4,00,700 |
| 30 May | Wedding gift | Personal | ← ICICI Savings | −15,000 | ICICI ₹30,200 | ₹3,85,700 |
| 1 Jun | Rent | Housing | ← ICICI Savings | −25,000 | ICICI ₹5,200 ⚠️ | ₹3,60,700 |
| 1 Jun | Home Loan EMI | EMI | ← HDFC Salary | −18,500 | HDFC ₹1,84,900 | ₹3,42,200 |
| 5 Jun | HDFC Card Bill | Card Settlement | ← HDFC Salary | −12,400 | HDFC ₹1,72,500 | ₹3,29,800 |
| 15 Jun | Goa trip | Travel | ← HDFC Salary | −40,000 | HDFC ₹1,32,500 | ₹2,89,800 |

**Outputs:**
- **Per-account projected balance** at any future date
- **Low balance warnings** (⚠️) when any account drops below minimum balance
- **Expected balance at end of projection period** (30 / 60 / 90 / 180 days)
- **Calendar view** alternative — see what hits which day
- **Stress test** — add a hypothetical expense and see impact
- **Variance** — once a planned item is actually executed, link it to the actual transaction; see planned vs actual

**Categories with projections:**
- Each recurring template carries a category
- Projection page can filter by category (e.g. "show only EMI projections")

---

### 2.7 People (NEW — supports Insurance and shared expenses)

Simple list of family members / dependents:
- Name, relationship (Self / Spouse / Father / Mother / Son / Daughter / Other), date of birth (for age-based insurance reminders)

Used by Insurance ("whose policy"), optionally by Transactions (tag who incurred the expense).

---

## 3. Dashboard v2

**Top row (4 stat cards):**
1. **Net Worth** — Bank + FD/RD + Investments − Loans − Card outstanding
2. **Liquid Balance** — Bank + Wallet + Cash (excluding deposits)
3. **This Month** — Income − Expense (with % savings rate)
4. **Upcoming 7 days** — Total outflow projected (EMIs, bills, premiums)

**Middle:**
- **Alerts strip** — Card due in N days, EMI on D, Insurance renewal on R, account near min balance, FD maturing
- **Account chips** — small card per account showing live balance
- **Projection mini-chart** — line chart of total liquid balance over next 60 days

**Bottom:**
- Spending by category (this month)
- Income vs Expense trend (6 months)
- Recent transactions

---

## 4. Data Model (high level)

```
people[]:       {id, name, relationship, dob}
accounts[]:     {id, name, bank, type, last4, balance, ifsc, minBalance, openingDate, jointHolder, nominee, interestRate, maturityDate, maturityAmount, status, notes}
cards[]:        {id, name, bank, network, last4, limit, billDay, dueDay, annualFee, interestRate, rewardType, rewardRate, autoDebitAccountId, status, notes}
cardCycles[]:   {id, cardId, startDate, endDate, billAmount, minDue, dueDate, paidAmount, status, notes}
loans[]:        {id, name, lender, type, last4, sanctionedAmount, disbursementDate, tenureMonths, interestRate, rateType, emi, emiDay, paidFromAccountId, outstanding, prepayments[], processingFee, status, notes}
insurance[]:    {id, name, insurer, type, policyLast4, insuredPersonIds[], cover, premium, frequency, startDate, endDate, renewalDate, paidFromAccountId, nominee, agent, status, notes}
transactions[]: {id, date, type:'income'|'expense'|'settlement'|'transfer', amount, category, fromAccountId, toAccountId, cardId, cycleId, personId, mode, reference, payee, note}
recurring[]:    {id, label, type, amount, category, fromAccountId, toAccountId, frequency, dayOfMonth, startDate, endDate, active}
projectionItems[]: {id, date, label, category, amount, accountId, type, sourceRecurringId | null, completedTxnId | null}
settings:       {currency, theme, projectionDays, defaultAccount}
```

---

## 5. New ideas I'd like to propose (you decide)

| Idea | What it adds | My recommendation |
|---|---|---|
| **A. Recurring Templates** | The engine that powers Projection. Define salary/EMI/rent/subscriptions once. | **Strongly recommend** — without this, Projection means manually entering every future item |
| **B. People module** | "Whose insurance" needs People. Also enables family-expense tagging. | **Recommend** — required by your insurance spec |
| **C. Investments module** | Track SIPs, mutual funds, stocks, gold, EPF, PPF separate from bank accounts. Live net worth includes investments. | **Recommend** — without it Net Worth is incomplete. Can be added later if you want. |
| **D. Receipts & attachments** | Attach photo/PDF of bills, statements, policy docs. | Useful but adds complexity. Could defer to v2.1. |
| **E. Tax tracker** | Flag transactions as 80C / 80D / HRA / TDS / GST. Year-end summary for ITR. | Useful if you file your own taxes. Optional. |
| **F. Reports & Export** | Monthly/yearly P&L, category drilldown, export to Excel/PDF. | **Recommend** — basic monthly report at minimum |
| **G. Reminders & Notifications** | In-app notification bell showing bills due, EMI dates, renewals. | **Recommend** — natural extension of the alerts you already wanted |
| **H. Multi-user / family share** | Two people share the same data (cloud only). | Skip for now. Add when you do cloud sync. |
| **I. Subcategories** | Food → Groceries / Restaurants / Tiffin | Light addition, useful. |
| **J. Per-account passbook view** | Tap an account → see all its transactions like a bank passbook | **Recommend** — clean UX win, low effort |

---

## 6. Open questions for you

1. **Investments module (idea C)?** Yes / No / Later
2. **Recurring Templates (idea A)?** Yes (needed for Projection to work well) / No (you'll add projection items manually)
3. **People module (idea B)?** Yes / No (if no, insurance "whose" becomes a free-text field)
4. **Tax tracker (idea E)?** Yes / No / Later
5. **Reports & Excel export (idea F)?** Yes / No / Later
6. **Reminders bell (idea G)?** Yes / No / Later
7. **Subcategories (idea I)?** Yes / No (keep flat)
8. **Cloud storage?** Still local-first with backup? Or move to Firebase/Supabase as part of v2?
9. **Currency** — stay with ₹ default, or multi-currency?

---

## 7. Build approach (when you approve)

Given the complexity, I'd build in **3 phases**:

**Phase 1 (core rebuild)** — Accounts, Cards (with cycles), Transactions (4 types), Loans (with EMI flow), Insurance (with People), Projection (with Recurring Templates), Dashboard v2.

**Phase 2 (depth)** — Reports & export, Reminders, Tax tracker, Subcategories, Passbook view.

**Phase 3 (cloud)** — Firebase/Supabase sync so it works across your phone + laptop.

Each phase is delivered as a complete working app. You can stop after any phase.

---

**Tell me your answers to Section 6, edit anything in this doc you want changed, and I'll build Phase 1.**
