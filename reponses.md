# Réponses — TD3 (application web 3-tiers)

## Question 1 — Pourquoi une NAT Gateway par AZ plutôt qu'une seule ?

Une NAT Gateway vit dans **une seule AZ**. Si on n'en déployait qu'une (dans l'AZ-a) et
que l'**AZ-a tombe**, les sous-réseaux privés de l'**AZ-b** — qui routeraient leur
`0.0.0.0/0` vers cette NAT — perdraient **toute sortie Internet** (plus de mises à jour, plus
d'appels sortants). On casserait la haute disponibilité. **Une NAT par AZ** rend chaque AZ
**autonome** : la panne d'une AZ n'affecte pas la sortie Internet de l'autre.

## Question 2 — Un attaquant ayant compromis le tier web peut-il joindre RDS ?

**Non.** `SG-rds` n'autorise en entrée (5432) **que** la source `SG-app`. Le tier web est
dans `SG-web`, **pas** dans `SG-app` → ses paquets vers RDS sont **refusés**. Pour atteindre
la base, l'attaquant devrait d'abord **pivoter** jusqu'à une instance du tier app (la seule
couche autorisée). C'est le **moindre privilège** en chaîne : chaque couche ne parle qu'à
la suivante.

## Question 3 — `publicly_accessible = false` ET subnet privé : pourquoi les deux ?

Ils protègent à **deux niveaux différents** (défense en profondeur) :
- `publicly_accessible = false` → RDS ne reçoit **ni IP ni nom DNS publics** : aucun point
  d'entrée public n'est créé.
- **Subnet privé** → même avec une IP, il n'existe **aucune route depuis Internet** (pas
  d'Internet Gateway sur ce subnet) : la base est **injoignable de l'extérieur**.

L'un sans l'autre est fragile : une base `publicly_accessible = true` placée par erreur dans
un subnet « public » deviendrait exposée. Combiner les deux garantit qu'aucune erreur de
configuration isolée n'expose la base.

> *Note : dans ce TD on réutilise le RDS partagé `td-ipssi-rds-v2`, qui est lui
> `publicly_accessible = true` (pour faciliter l'accès `psql` en cours). La réponse ci-dessus
> reste la bonne pratique de production ; le RDS de cours déroge volontairement à cette
> règle pour des raisons pédagogiques.*

## Question 4 — Pourquoi le health check ne doit-il pas interroger RDS ?

Si `/health` interrogeait la base, **une panne ou une lenteur de RDS** ferait échouer le
health check sur **toutes** les instances du tier app en même temps. L'ALB les jugerait
toutes `unhealthy` et les **retirerait toutes** de la rotation → l'application entière tombe,
alors que le problème vient de la base (pas des instances). Un `/health` **léger** (qui ne
touche pas RDS) mesure la santé **de l'instance/application elle-même**, ce qui est le rôle
du health check.

## Question 5 — Chemin complet d'une inscription (aller / retour)

**Aller :**
1. Navigateur → **DNS de l'ALB public**
2. **ALB public** (listener HTTP:80) → **Target Group « web »** → **EC2 web** (Flask)
3. EC2 web fait un `POST /api/signup` vers le **DNS de l'ALB interne**
4. **ALB interne** (listener:80) → **Target Group « app »** → **EC2 app** (API Flask)
5. EC2 app ouvre une connexion **PostgreSQL 5432** vers le **endpoint RDS** → `INSERT`

**Retour :**
6. **RDS** confirme l'écriture → **EC2 app** renvoie un JSON `201`
7. → **ALB interne** → **EC2 web** construit la page de confirmation
8. → **ALB public** → **navigateur**

Chaque flèche traverse aussi le **Security Group** de la couche cible, qui n'autorise que la
couche précédente.
