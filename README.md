# Trinity — La Ressourcerie du Quartier

Site et API pour gérer les dons, les ateliers, les inscriptions et les horaires d’une ressourcerie.

## Structure

- `frontend/` — pages HTML, CSS et JS (ouvrir ce dossier avec Live Server)
- `backend/` — API Express (MySQL, JWT)
- `sql/mysql/` — schéma, données et requêtes pour MySQL (pile utilisée par l’API)
- `sql/supabase/` — scripts Postgres / RLS (ancienne pile, non utilisée par le backend)
- `GTI.md` — brief du projet et répartition des rôles
- `GROOP.md` — membres du groupe

## Lancer le backend

```bash
cd backend
cp .env.example .env   # puis renseigner DB_* et JWT_SECRET
npm install
npm run dev
```

L’API écoute sur `http://localhost:3000`. Le front est prévu via Live Server (`http://127.0.0.1:5500`).

## Initialiser MySQL

```bash
./sql/run_sql.sh --all
```

`--all` n’exécute que `sql/mysql/*.sql`. Le script lit `backend/.env` (ou `.env` à la racine).

```bash
./sql/run_sql.sh sql/mysql/creation.sql
./sql/run_sql.sh creation.sql
```
