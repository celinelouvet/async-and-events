# Asynchrone / Events

## Cas existant d'une application de gestion des photos

A affiner:

* Posts ou Photos ?

***A enrichir en fonction de la suite***

* `SI 1`:
* `SI 2`:
  * appartient à une autre filiale du groupe.
  * source de la donnée des contrats.

```mermaid
---
title: Cas réel - Macro vue
---
graph LR
    subgraph SI 1
        subgraph Photos
            direction TB
            PS(Photos) --> PSDB[(Photos DB)]
            PSA{{Photos App}} --> PS
        end
        subgraph Users
            direction TB
            US(Users) --> USDB[(Users DB)]
            USA{{Back Office App}} --> US
        end
    end
    subgraph SI2
        subgraph Contracts
            direction TB
            CS(Contracts) --> CSDB[(Contracts DB)]
            CSA{{Support App}} --> CS
        end
    end

    Photos --> Users --> Contracts
```

```mermaid
---
title: Cas réel - Appel au service Photos
---
sequenceDiagram
    actor AM as Application mobile
    participant PS as Photos
    participant US as Users
    participant CS as Contracts

    
    AM->>PS: Récupérer les photos,<br/>l'utilisateur et son contrat ?
    
    activate PS

    %% début SI 1 + titre

    PS->>US: Récupérer les infos<br/>de l'utilisateur ?
    activate US
    US->>CS: Récupérer le contrat et<br/> ses options ?
    
    activate CS
    %% début SI 2 + titre
    CS-->>US: Contrat

    %% fin SI 2

    deactivate CS
    US-->>PS: Utilisateur
    deactivate US
    PS->>PS: Lister les photos

    %% fin SI 1
    deactivate PS
    
    PS-->>AM: Photos, utilisateur<br/>et contrat
```

Les problèmes:

* lenteurs à chaque appel
* qu'est ce qui se passe si `Users` ou `Contracts` est down ou surchargé ?
* qu'est ce qui se passe si beaucoup d'utilisateurs récupèrent les données ?

## 1. Expliquer synchrone vs asynchrone

### 1. Appels synchrones ?

Un service `PostsService` appelle un 2ème service `UsersService`. Il va attendre le résultat pour la suite de son traitement.

#### Pourquoi faire ça ?

Ca peut être nécessaire de faire ainsi si on a besoin d'une info pour la suite du traitement.

#### Avantages

* Le résultat obtenu est à jour

#### Inconvénients

* Le traitement de `PostsService` est interrompu le temps que `UsersService` réponde
* Gestion des erreurs si :
  * `UsersService` est down
  * `UsersService` est trop long (timeout)

```mermaid
---
title: Appel synchrone
---
sequenceDiagram
    participant PS as PostsService
    participant US as UsersService

    activate PS
    Note right of PS: Début du traitement
    PS->>US: Récupérer les infos de l'utilisateur ?
    activate US
    Note right of PS: En attente de UsersService
    US-->>PS: Infos de l'utilisateur
    deactivate US

    Note right of PS: Suite du traitement
    deactivate PS
```

### 2. Appels asynchrones ?

Un service `PostsService` déclenche un traitement sur un 2ème service `UsersService`. Il ne va pas attendre le résultat
pour la suite de son traitement.

#### Pourquoi faire ça ?

#### Avantages

* Pas de temps d'attente pour `PostsService`

#### Inconvénients

* Le traitement de `PostsService` est interrompu le temps que `UsersService` réponde
* Si `UsersService` est down, le traitement de `PostsService` va finir en erreur
* Si `UsersService` est trop long, le traitement de `PostsService` va finir en erreur (timeout)

```mermaid
---
title: Asynchronous call
---
sequenceDiagram
    participant PS as PostsService
    participant US as UsersService

    activate PS
    Note right of PS: Début du traitement...
    PS--)US: Récupérer les infos de l'utilisateur ?
    activate US
    Note right of PS: En attente de UsersService
    US-->>PS: Infos de l'utilisateur
    deactivate US

    Note right of PS: Suite du traitement...
    deactivate PS
```

## 2. Comment faire de l’asynchrone

### 1. Appeler sans attendre la réponse

#### Pourquoi faire ça ?

#### Avantages

#### Inconvénients

### 2. Utilisation d'événement

#### Pourquoi faire ça ?

#### Avantages

#### Inconvénients

## 3. Différence pull / push

### 1. Pull event ?

#### Pourquoi faire ça ?

#### Avantages

#### Inconvénients

### 2. Push event ?

#### Pourquoi faire ça ?

#### Avantages

#### Inconvénients

## 4. Utilité des FaaS

### Pourquoi faire ça ?

### Avantages

### Inconvénients
