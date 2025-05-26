# 📦 Sistem de Livrare – Analiză Power BI + PostgreSQL

Acest proiect combină o bază de date relațională creată în PostgreSQL cu un dashboard interactiv realizat în Power BI pentru a analiza vânzările, clienții, produsele, comenzile și livrările.

---

## 🗃️ Structura Proiectului

| Fișier               | Descriere                                                                 |
|----------------------|---------------------------------------------------------------------------|
| `Dashboard_Vanzari.pbix` | Dashboard Power BI cu pagini dedicate pentru diferite analize              |
| `delivery_db.sql`        | Script SQL pentru crearea tabelelor bazei de date                         |
| `trigger.sql`            | Script cu triggere SQL pentru automatizări la nivel de bază de date       |
| `index.sql`              | Script pentru creare de indici SQL (optimizare interogări)                |
| `delivery_db.png`        | Diagramă relațională a bazei de date                                      |

---

## 🧱 Structura Bazei de Date (PostgreSQL)

Baza de date include următoarele entități:

- **Clienti** – date despre clienți (nume, email, telefon, zona de livrare etc.)
- **Soferi** – date despre șoferi și zonele acoperite
- **Produse** – produse împărțite pe categorii (alimente, tech, îmbrăcăminte etc.)
- **Comenzi** – comenzile plasate de clienți
- **Comanda_Produse** – legătura dintre comenzi și produsele comandate
- **Trasee_Livrari** – detalii despre livrările efectuate de șoferi (inclusiv distanțe și ore)

---

## 📊 Dashboard Power BI

Dashboardul este împărțit în 5 pagini:

### 1. **Prezentare Generală**
- Total vânzări
- Număr comenzi
- Număr clienți
- Valoare medie per comandă
- Evoluția lunară a vânzărilor

### 2. **Analiza Clienți**
- Top orașe după valoarea totală a comenzilor
- Clienți cu cele mai mari comenzi
- Repartizarea clienților pe zone de livrare

### 3. **Analiza Produse**
- Vânzări per categorie
- Cele mai vândute produse
- Prețuri medii per categorie

### 4. **Evoluția Vânzărilor**
- Vânzări lunare și anuale
- Comparație între ani
- Filtrare pe categorii și orașe

### 5. **Comenzi & Livrări**
- Timp mediu de livrare
- Comenzi pe sofer
- Distanțe parcurse

---

## 🧠 Măsuri DAX principale

```DAX
Total Vanzari = SUM('public comenzi'[total])
Numar Comenzi = COUNTROWS('public comenzi')
Numar Clienti = DISTINCTCOUNT('public comenzi'[client_id])
Valoare Medie Comanda = AVERAGE('public comenzi'[total])
Luna Comanda = FORMAT('public comenzi'[data_comanda], "YYYY-MM")
Vanzari Lunare = SUM('public comenzi'[total])

▶️ Cum rulezi proiectul
1. Creează baza de date rulând delivery_db.sql în PostgreSQL
2. Opțional: adaugă index.sql și trigger.sql pentru optimizare
3. Deschide Dashboard_Vanzari.pbix cu Power BI Desktop
4. Conectează dashboardul la baza ta de date PostgreSQL (folosind localhost, nume BD, user, parolă)
5. Actualizează modelul și folosește dashboardul interactiv

📌 Tehnologii
PostgreSQL – pentru baza de date relațională
Power BI Desktop – pentru BI vizual
DAX – pentru măsuri și metrici
SQL – pentru modelarea bazei de date

## 👤 Autor

Acest proiect a fost realizat ca exercițiu de învățare și dezvoltare a competențelor în lucrul cu baze de date relaționale (PostgreSQL) și cu instrumente de analiză vizuală (Power BI).

- 📌 Autor: *Lăcătuș Eduard*  
- 🎓 Scop: portofoliu personal  
- 📧 Contact: *edylacatus109@gmail.com*  
