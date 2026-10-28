// NOUVEAUX OBJETS DE LA RESSOURCERIE

const nouveauxObjets = [
    // MEUBLES
    { nom: "Table basse en bois", prix: 25, categorie: "meubles", etat: "Bon état", emoji: "🪵", fond: "fond-jaune" },
    { nom: "Fauteuil confortable", prix: 45, categorie: "meubles", etat: "Très bon état", emoji: "🛋️", fond: "fond-vert" },
    { nom: "Bibliothèque en bois", prix: 35, categorie: "meubles", etat: "Bon état", emoji: "📚", fond: "fond-rose" },
    { nom: "Petite commode", prix: 40, categorie: "meubles", etat: "Bon état", emoji: "🗄️", fond: "fond-jaune" },
    { nom: "Tabouret vintage", prix: 12, categorie: "meubles", etat: "Très bon état", emoji: "🪑", fond: "fond-vert" },
    { nom: "Bureau en bois", prix: 55, categorie: "meubles", etat: "Bon état", emoji: "🪑", fond: "fond-rose" },
    { nom: "Étagère murale", prix: 15, categorie: "meubles", etat: "Très bon état", emoji: "🪵", fond: "fond-jaune" },

    // MAISON
    { nom: "Machine à café", prix: 20, categorie: "maison", etat: "Bon état", emoji: "☕", fond: "fond-vert" },
    { nom: "Grille-pain", prix: 10, categorie: "maison", etat: "Bon état", emoji: "🍞", fond: "fond-rose" },
    { nom: "Miroir rond", prix: 18, categorie: "maison", etat: "Très bon état", emoji: "🪞", fond: "fond-jaune" },
    { nom: "Horloge murale", prix: 8, categorie: "maison", etat: "Bon état", emoji: "🕰️", fond: "fond-vert" },
    { nom: "Lot de 6 assiettes", prix: 12, categorie: "maison", etat: "Très bon état", emoji: "🍽️", fond: "fond-rose" },
    { nom: "Vase décoratif", prix: 9, categorie: "maison", etat: "Bon état", emoji: "🏺", fond: "fond-jaune" },
    { nom: "Plante artificielle", prix: 7, categorie: "maison", etat: "Très bon état", emoji: "🪴", fond: "fond-vert" },

    // BRICOLAGE
    { nom: "Perceuse électrique", prix: 30, categorie: "bricolage", etat: "Bon état", emoji: "🛠️", fond: "fond-rose" },
    { nom: "Tournevis professionnels", prix: 12, categorie: "bricolage", etat: "Très bon état", emoji: "🪛", fond: "fond-jaune" },
    { nom: "Scie à main", prix: 8, categorie: "bricolage", etat: "Bon état", emoji: "🪚", fond: "fond-vert" },
    { nom: "Boîte de rangement", prix: 10, categorie: "bricolage", etat: "Bon état", emoji: "🧰", fond: "fond-rose" },
    { nom: "Mètre ruban", prix: 4, categorie: "bricolage", etat: "Très bon état", emoji: "📏", fond: "fond-jaune" },
    { nom: "Marteau de bricolage", prix: 6, categorie: "bricolage", etat: "Bon état", emoji: "🔨", fond: "fond-vert" },

    // TEXTILES
    { nom: "Pull en laine", prix: 9, categorie: "textiles", etat: "Très bon état", emoji: "🧶", fond: "fond-rose" },
    { nom: "Jean bleu", prix: 12, categorie: "textiles", etat: "Bon état", emoji: "👖", fond: "fond-jaune" },
    { nom: "Robe fleurie", prix: 15, categorie: "textiles", etat: "Très bon état", emoji: "👗", fond: "fond-vert" },
    { nom: "Paire de baskets", prix: 18, categorie: "textiles", etat: "Bon état", emoji: "👟", fond: "fond-rose" },
    { nom: "Manteau d'hiver", prix: 25, categorie: "textiles", etat: "Très bon état", emoji: "🧥", fond: "fond-jaune" },
    { nom: "Sac à dos", prix: 10, categorie: "textiles", etat: "Bon état", emoji: "🎒", fond: "fond-vert" },
    { nom: "Écharpe en laine", prix: 5, categorie: "textiles", etat: "Très bon état", emoji: "🧣", fond: "fond-rose" }
];

// AFFICHAGE DES OBJETS

const grilleCatalogue = document.querySelector(".boutique-produits");

if (grilleCatalogue) {

    nouveauxObjets.forEach((objet) => {

        const produit = document.createElement("article");

        produit.className = "produit";
        produit.dataset.categorie = objet.categorie;

        produit.innerHTML = `
            <div class="produit-image ${objet.fond}">
                <span class="produit-emoji">${objet.emoji}</span>
                <span class="disponible">Disponible</span>
            </div>

            <div class="produit-infos">
                <div class="produit-titre">
                    <h3>${objet.nom}</h3>
                    <span class="prix">${objet.prix} €</span>
                </div>

                <p>${objet.categorie} · ${objet.etat}</p>
            </div>
        `;

        grilleCatalogue.appendChild(produit);

    });

}