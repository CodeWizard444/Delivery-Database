-- Index pe email (căutări frecvente după email)
CREATE INDEX idx_clienti_email ON Clienti(email);

-- Index pe oraș + zonă de livrare (optimizare BI sau filtre în livrări)
CREATE INDEX idx_clienti_oras_zona ON Clienti(oras, zona_livrare);

-- Index pe zona acoperită (căutări pentru alocare traseu)
CREATE INDEX idx_soferi_zona ON Soferi(zona_acoperita);

-- Index pe vehicul (dacă vrei să filtrezi rapid după tip)
CREATE INDEX idx_soferi_vehicul ON Soferi(vehicul);

-- Index pe categorie (rapoarte BI pe tipuri de produse)
CREATE INDEX idx_produse_categorie ON Produse(categorie);

-- Index pe preț (pentru filtrare rapidă în aplicație)
CREATE INDEX idx_produse_pret ON Produse(pret);

-- Index pe client_id (pentru a găsi comenzile unui client)
CREATE INDEX idx_comenzi_client ON Comenzi(client_id);

-- Index pe status (pentru filtrare: plasata, in procesare etc.)
CREATE INDEX idx_comenzi_status ON Comenzi(status);

-- Index inversat: produs_id (vezi în ce comenzi a fost un produs)
CREATE INDEX idx_comanda_produse_produs ON Comanda_Produse(produs_id);

-- Index pe cantitate (dacă vrei rapoarte pe cele mai comandate produse)
CREATE INDEX idx_comanda_produse_cantitate ON Comanda_Produse(cantitate);

-- Index pe sofer_id (găsire rapidă a traseelor unui șofer)
CREATE INDEX idx_trasee_sofer ON Trasee_Livrari(sofer_id);

-- Index pe comanda_id (pentru a lega comenzile de trasee)
CREATE INDEX idx_trasee_comanda ON Trasee_Livrari(comanda_id);
