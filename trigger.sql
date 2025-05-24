CREATE TRIGGER trg_actualizeaza_total
AFTER INSERT OR UPDATE OR DELETE ON Comanda_Produse
FOR EACH ROW
EXECUTE FUNCTION trigger_actualizeaza_total();

CREATE TRIGGER trg_verifica_produse
AFTER DELETE ON Comanda_Produse
FOR EACH ROW
EXECUTE FUNCTION verifica_produse_comanda();

CREATE TRIGGER trg_verifica_timp_livrare
BEFORE INSERT OR UPDATE ON Trasee_Livrari
FOR EACH ROW
EXECUTE FUNCTION verifica_timp_livrare();

