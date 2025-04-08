B- Création des Tablespaces et Utilisateur
2. Création des Tablespaces
sql
Copy
-- Pour Oracle
CREATE TABLESPACE SQL3_TBS
DATAFILE 'sql3_tbs.dbf' SIZE 100M AUTOEXTEND ON;

CREATE TEMPORARY TABLESPACE SQL3_TempTBS
TEMPFILE 'sql3_temptbs.dbf' SIZE 50M AUTOEXTEND ON;


-- 3. Création de l'Utilisateur
CREATE USER SQL3 IDENTIFIED BY votre_mot_de_passe
DEFAULT TABLESPACE SQL3_TBS
TEMPORARY TABLESPACE SQL3_TempTBS
QUOTA UNLIMITED ON SQL3_TBS;


-- 4. Attribution des Privilèges
GRANT ALL PRIVILEGES TO SQL3;


-- C- Langage de Définition de Données

-- 5. Création des Types Objets
-- Types Énumérés (Oracle)
CREATE TYPE type_sol_type AS ENUM ('argileux', 'sableux', 'limoneux', 'calcaire', 'humifère', 'tourbeux');
-- Répéter pour autres énumérations (type_mission_type, etc.).


-- Types Objets :

-- Oracle Syntaxe
CREATE TYPE Exploitation AS OBJECT (
    id_exploitation NUMBER,
    nom_exploitation VARCHAR2(100),
    surface_exploitation NUMBER,
    region VARCHAR2(50),
    nbr_parcelles NUMBER,
    -- Méthodes
    MEMBER FUNCTION surface_totale RETURN NUMBER
);
/

CREATE TYPE Parcelle AS OBJECT (
    id_parcelle NUMBER,
    nom_parcelle VARCHAR2(100),
    surface_parcelle NUMBER,
    type_sol type_sol_type,
    -- Références
    ref_exploitation REF Exploitation,
    -- Méthodes
    MEMBER FUNCTION cultures_campagne(p_campagne REF CampagneAgricole) RETURN CultureList,
    MEMBER FUNCTION maladies_graves RETURN MaladieList
);
/

-- Répéter pour tous les types (Culture, CampagneAgricole, etc.).

-- 6. Définition des Méthodes
-- Exemple pour surface_totale :

CREATE TYPE BODY Exploitation AS
    MEMBER FUNCTION surface_totale RETURN NUMBER IS
        total NUMBER := 0;
    BEGIN
        SELECT SUM(p.surface_parcelle) INTO total
        FROM Parcelle p
        WHERE p.ref_exploitation = SELF;
        RETURN total;
    END;
END;
/


-- Exemple pour cultures_campagne :

CREATE TYPE BODY Parcelle AS
    MEMBER FUNCTION cultures_campagne(p_campagne REF CampagneAgricole) RETURN CultureList IS
        cultures CultureList := CultureList();
    BEGIN
        SELECT Culture(...) BULK COLLECT INTO cultures
        FROM Semis s
        WHERE s.ref_parcelle = SELF AND s.ref_campagne = p_campagne;
        RETURN cultures;
    END;
END;
/


-- 7. Création des Tables

CREATE TABLE ExploitationTab OF Exploitation (
    id_exploitation PRIMARY KEY
);

CREATE TABLE ParcelleTab OF Parcelle (
    id_parcelle PRIMARY KEY,
    ref_exploitation SCOPE IS ExploitationTab
);


-- Répéter pour toutes les tables.
-- D- Langage de Manipulation de Données
-- 8. Remplissage des Tables
Adaptez le script SQL fourni en utilisant des constructeurs d’objets. Exemple :

INSERT INTO ExploitationTab VALUES (
    Exploitation(1, 'Ferme A', 500.0, 'Loire', 10)
);

INSERT INTO ParcelleTab VALUES (
    Parcelle(1, 'Parcelle 1', 50.0, 'argileux', 
    (SELECT REF(e) FROM ExploitationTab e WHERE e.id_exploitation = 1))
);

-- E- Langage d’Interrogation de Données
-- 9. Lister les Exploitations et Parcelles

SELECT e.nom_exploitation, p.nom_parcelle
FROM ExploitationTab e, TABLE(e.parcelles) p;

-- 10. Taux de Maladies par Parcelle/Campagne

SELECT p.id_parcelle, c.annee, 
       COUNT(d.id_detection) / (SELECT COUNT(*) FROM DetectionMaladie) * 100 AS taux
FROM DetectionMaladie d, ParcelleTab p, CampagneAgricoleTab c
WHERE d.ref_parcelle = REF(p) AND d.ref_campagne = REF(c)
GROUP BY p.id_parcelle, c.annee;


-- 11. Missions de Traitement

SELECT m.id_mission, m.date_mission
FROM MissionDroneTab m
WHERE m.type_mission = 'traitement';

-- 12. Historique des Cultures
SELECT e.nom_exploitation, p.nom_parcelle, c.nom_culture, ca.annee
FROM ExploitationTab e, TABLE(e.parcelles) p, TABLE(p.semis) s, CultureTab c, CampagneAgricoleTab ca
WHERE s.ref_culture = REF(c) AND s.ref_campagne = REF(ca);


-- 13. Drones Disponibles pour Surveillance

SELECT d.id_drone, d.modele
FROM DroneTab d
WHERE d.statut_drone = 'Disponible' AND d.type_drone = 'surveillance';
-- 14. Année avec le Plus de Maladies

SELECT c.annee, COUNT(*) AS nb_maladies
FROM DetectionMaladieTab d, CampagneAgricoleTab c
WHERE d.ref_campagne = REF(c)
GROUP BY c.annee
ORDER BY nb_maladies DESC
FETCH FIRST 1 ROW ONLY;



-- Remarques Finales
-- Adaptez la syntaxe selon votre SGBD (Oracle/PostgreSQL).

-- Utilisez des REF pour les associations entre objets.

-- Testez chaque méthode et requête avec des données réelles.

-- Besoin de précisions sur une partie en particulier ?