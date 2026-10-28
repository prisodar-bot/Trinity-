-- ===== 1) Création automatique de la ligne "utilisateurs" à chaque inscription =====
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    INSERT INTO utilisateurs (id, nom, prenom, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nom', 'À renseigner'),
        COALESCE(NEW.raw_user_meta_data->>'prenom', 'À renseigner'),
        NEW.email
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ===== 2) Fonctions utilitaires =====
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
    SELECT EXISTS (SELECT 1 FROM utilisateurs WHERE id = auth.uid() AND role = 'admin');
$$;

CREATE OR REPLACE FUNCTION public.mon_role()
RETURNS role_utilisateur LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
    SELECT role FROM utilisateurs WHERE id = auth.uid();
$$;

-- ===== 3) Activer la RLS partout =====
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE dons ENABLE ROW LEVEL SECURITY;
ALTER TABLE ateliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE inscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE permanences ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations_permanence ENABLE ROW LEVEL SECURITY;
ALTER TABLE criteres_don ENABLE ROW LEVEL SECURITY;
ALTER TABLE horaires ENABLE ROW LEVEL SECURITY;

-- ===== 4) utilisateurs =====
CREATE POLICY "voir son profil ou admin" ON utilisateurs FOR SELECT
USING (id = auth.uid() OR public.is_admin());

CREATE POLICY "modifier son profil sans changer le role" ON utilisateurs FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid() AND role = public.mon_role());

CREATE POLICY "admin gere les utilisateurs" ON utilisateurs FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 5) dons =====
CREATE POLICY "voir ses dons" ON dons FOR SELECT
USING (utilisateur_id = auth.uid());

CREATE POLICY "proposer un don" ON dons FOR INSERT
WITH CHECK (utilisateur_id = auth.uid());

CREATE POLICY "admin gere les dons" ON dons FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 6) ateliers (lecture publique) =====
CREATE POLICY "tout le monde voit les ateliers" ON ateliers FOR SELECT
USING (true);

CREATE POLICY "admin gere les ateliers" ON ateliers FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 7) inscriptions (visiteurs autorisés à s'inscrire) =====
CREATE POLICY "s'inscrire a un atelier" ON inscriptions FOR INSERT
WITH CHECK (true);

CREATE POLICY "admin gere les inscriptions" ON inscriptions FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 8) permanences =====
CREATE POLICY "voir les permanences" ON permanences FOR SELECT
USING (true);

CREATE POLICY "admin gere les permanences" ON permanences FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 9) reservations_permanence =====
CREATE POLICY "voir ses reservations" ON reservations_permanence FOR SELECT
USING (utilisateur_id = auth.uid());

CREATE POLICY "reserver une place" ON reservations_permanence FOR INSERT
WITH CHECK (utilisateur_id = auth.uid());

CREATE POLICY "annuler sa reservation" ON reservations_permanence FOR DELETE
USING (utilisateur_id = auth.uid());

CREATE POLICY "admin gere les reservations" ON reservations_permanence FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 10) criteres_don et horaires (lecture publique) =====
CREATE POLICY "voir les criteres" ON criteres_don FOR SELECT USING (true);
CREATE POLICY "admin gere les criteres" ON criteres_don FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "voir les horaires" ON horaires FOR SELECT USING (true);
CREATE POLICY "admin gere les horaires" ON horaires FOR ALL
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ===== 11) Places restantes visibles par tout le monde (sans exposer les inscrits) =====
CREATE OR REPLACE VIEW ateliers_places AS
SELECT a.id, a.titre, a.description, a.date_atelier, a.lieu, a.capacite,
       COUNT(i.id) AS inscrits,
       a.capacite - COUNT(i.id) AS places_restantes
FROM ateliers a
LEFT JOIN inscriptions i ON i.atelier_id = a.id
GROUP BY a.id;

GRANT SELECT ON ateliers_places TO anon, authenticated;

-- ===== 12) Désinscription via le token =====
CREATE OR REPLACE FUNCTION public.desinscrire(p_token text)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
    DELETE FROM inscriptions WHERE token = p_token;
$$;

GRANT EXECUTE ON FUNCTION public.desinscrire(text) TO anon, authenticated;