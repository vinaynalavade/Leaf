# Leaf: Complete Product Documentation & iOS Migration Blueprint

Welcome to the definitive engineering documentation and native iOS migration blueprint for **Leaf**, a privacy-first, offline-first personal finance management application.

```
██╗     ███████╗ █████╗ ███████╗
██║     ██╔════╝██╔══██╗██╔════╝
██║     █████╗  ███████║█████╗  
██║     ██╔══╝  ██╔══██║██╔══╝  
███████╗███████╗██║  ██║██║     
╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     
Personal Finance • Clarity • Freedom
```

---

## 1. About This Documentation System

This directory (`shared-docs/`) contains the complete technical specifications, mathematical calculation formulas, database schemas, UI design tokens, user journeys, and architecture blueprints derived from a deep, file-by-file audit of the Leaf Android repository.

It is structured to serve as the **authoritative, implementation-ready blueprint** for developing Leaf natively for Apple iPhone devices using **Swift** and **SwiftUI**.

### Core Product Tenets
- **100% Offline-First**: Zero reliance on proprietary cloud backends. User data lives on the device.
- **Zero Trackers**: No third-party analytics, no advertising SDKs, no behavioral telemetry.
- **Subunit Integer Precision**: All monetary calculations are performed in signed 64-bit integers (`paise` / `cents` / `subunits`). Floating-point arithmetic is strictly forbidden in persistence and ledgers.
- **Continuous Financial Continuity**: Month-to-month opening balances continuously preserve financial continuity without temporal gaps.
- **"Emerald & Obsidian" Design Language**: A luxury fintech visual identity blending deep obsidian dark mode (`#0A0C0F`), warm canvas light mode (`#F4F6F9`), rich emerald accents (`#028166` / `#05B38C`), continuous squircles, and monospaced tabular numerals.

---

## 2. Quick Navigation

| Document Directory | Contents & Key Files |
| :--- | :--- |
| **[Master Index](file:///x:/Leaf/shared-docs/INDEX.md)** | Full document manifest, reading path, and topic directory. |
| **[00. Product Overview](file:///x:/Leaf/shared-docs/00-PRODUCT-OVERVIEW.md)** | Value proposition, target audience, brand identity, and iOS migration scope. |
| **[01. Master Requirements](file:///x:/Leaf/shared-docs/01-MASTER-REQUIREMENTS.md)** | Traceable functional (REQ-F), calculation (REQ-C), security (REQ-S), and database (REQ-D) rules. |
| **[02. Feature Inventory](file:///x:/Leaf/shared-docs/02-FEATURE-INVENTORY.md)** | Complete catalog of all 69 features with source file and test references. |
| **[03. Feature Specifications](file:///x:/Leaf/shared-docs/03-FEATURE-SPECIFICATIONS/)** | 19 deep 25-point engineering specifications for every functional module. |
| **[04. Business Logic](file:///x:/Leaf/shared-docs/04-BUSINESS-LOGIC/)** | Mathematical formulas, rounding rules, input validations, and transaction rules. |
| **[05. Database](file:///x:/Leaf/shared-docs/05-DATABASE/)** | Schema v10 SQL, Room entity mappings, foreign key cascades, migrations 1-10, and Mermaid ERD. |
| **[06. Design System](file:///x:/Leaf/shared-docs/06-DESIGN/)** | Design system philosophy, color tokens, typography scale, component inventory, and screen catalog. |
| **[07. User Flows](file:///x:/Leaf/shared-docs/07-USER-FLOWS/)** | 5-tab navigation hierarchy, 6 user journeys, and visual Mermaid flowcharts. |
| **[08. Technical Architecture](file:///x:/Leaf/shared-docs/08-TECHNICAL-ARCHITECTURE/)** | Android clean architecture, native iOS architecture (SwiftUI + GRDB SQLite), and mapping dictionary. |
| **[09. API & Synchronization](file:///x:/Leaf/shared-docs/09-API-AND-SYNCHRONIZATION/)** | Google Drive v3 REST, iTunes Lookup API, cloud sync protocol, and JSON v2 backup schema. |
| **[10. Quality Assurance](file:///x:/Leaf/shared-docs/10-QUALITY-ASSURANCE/)** | Test strategy, test cases, comprehensive edge cases, Gherkin acceptance criteria, and parity matrix. |
| **[11. Issues & Technical Debt](file:///x:/Leaf/shared-docs/11-ISSUES-AND-TECHNICAL-DEBT/)** | Documented edge-case risks, legacy KharchaFlow naming debt, and modernization guide. |
| **[12. Master iOS Guide](file:///x:/Leaf/shared-docs/12-IOS-IMPLEMENTATION-GUIDE/)** | **The critical guide for the iOS development agent**, 8-phase roadmap, and release checklists. |
| **[Audit Report](file:///x:/Leaf/shared-docs/DOCUMENTATION-AUDIT-REPORT.md)** | Completeness certification validating 100% audit coverage against original instructions. |

---

## 3. Key Mathematical Contracts to Remember
- **Subunit Scale**: ₹1.00 = 100 subunits (paise). $1.00 = 100 cents. ¥1 = 1 subunit.
- **Max Subunit Limit**: $10^{14}$ subunits (₹100 Crore / $1 Trillion).
- **Split Remainder Invariant**: $R = \text{Total} \pmod N$ distributed to first $R$ participants; sum of shares strictly equals total bill.
- **Budget Thresholds**: `< 75%` Green, `75% - 99.9%` Amber, `100%` Warning Amber, `> 100%` Crimson Red.
- **PIN Vault**: Salted SHA-256 with 16-byte cryptographically secure random salt stored in hardware Keychain.

