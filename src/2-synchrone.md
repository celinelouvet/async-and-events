# 2. Appels synchrones

## 1. Qu'est ce que ça veut dire ?

Un service `S1` appelle un 2ème service `S2`. Il va attendre le résultat pour la suite de son traitement.

```mermaid
---
title: Appel synchrone
---
sequenceDiagram
    participant S1
    participant S2

    activate S1
    Note right of S1: Début du traitement<br/>de S1
    S1-)S2: Récupérer une info ?
    activate S2
    Note over S1,S2: En attente de S2
    S2-)S1: Info
    deactivate S2

    Note right of S1: Suite du traitement<br/>de S1
    deactivate S1
```

### Pourquoi faire ça ?

- Quand on a besoin d'avoir la réponse pour poursuivre le traitement.
- Quand on veut être sûr qu'une action s'est bien terminée pour poursuivre le traitement.

### Avantages

- Le résultat obtenu est à jour.
- On a la garantie que le traitement de `S2` s'est correctement effectué.

### Inconvénients

- Le traitement de `S1` est en pause le temps que `S2` réponde.
- Gestion des erreurs si :
  - `S2` est down
  - `S2` est trop long (timeout)

## 2. Dans notre situation réelle

L'utilisateur veut, via son application mobile, afficher sa liste de photos.

![Photos list](2-synchrone.png)

[Maquette](https://www.figma.com/file/Wx4WtmrKsUsHAtiedGGZMQ/Asynchrone?node-id=4%3A74&t=rEqGLtgCcFsp1KDf-4)

Photos de [Pixabay](https://pixabay.com)

```mermaid
C4Context
  title Cas réel

  Person_Ext(PhotosUser, "Photos App")
  Person(BackOfficeUser, "Back-Office App")
  Person(ContractsUser, "Support App")

  Enterprise_Boundary(si1, "Filiale 1") {
    System_Boundary(PhotosSystem, "Photos") {
      Container(PhotosService, "Photos service")
      ContainerDb(PhotosDB, "Photos DB")
    }

    System_Boundary(UsersSystem, "Users") {
      Container(UsersService, "Users service")
      ContainerDb(UsersDB, "Users DB")
    }
  }

  Enterprise_Boundary(si2, "Filiale 2") {

    System_Boundary(ContractsSystem, "Contracts") {
      Container(ContractsService, "Contracts service")
      ContainerDb(ConstractsDB, "Contracts DB")
    }
  }

  Rel(PhotosUser, PhotosService, "Uses")
  Rel(PhotosService, PhotosDB, "Stores")

  Rel(BackOfficeUser, UsersService, "Uses")
  Rel(UsersService, UsersDB, "Stores")

  Rel(ContractsUser, ContractsService, "Uses")
  Rel(ContractsService, ConstractsDB, "Stores")

  Rel(PhotosService, UsersService, "Uses")
  Rel(UsersService, ContractsService, "Uses")

  UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="2")
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


    AM-)PS: Récupérer les photos,<br/>l'utilisateur et son contrat ?

    activate PS

    %% début SI 1 + titre

    PS-)US: Récupérer les infos<br/>de l'utilisateur ?
    activate US
    US-)CS: Récupérer le contrat et<br/> ses options ?

    activate CS
    %% début SI 2 + titre
    CS-)US: Contrat

    %% fin SI 2

    deactivate CS
    US-)PS: Utilisateur
    deactivate US
    PS-)PS: Lister les photos

    %% fin SI 1

    PS-)AM: Photos, utilisateur<br/>et contrat
    deactivate PS
```

### Les questions qu'on peut se poser

1. qu'est ce qui se passe si beaucoup d'utilisateurs récupèrent les données ?
2. qu'est ce qui se passe si `Users` est down ou surchargé ?
3. qu'est ce qui se passe si `Contracts` est down ou surchargé ?

### Les problèmes possibles

1. on aura des lenteurs à chaque appel car on se retrouve à appeler toute une chaîne de services.
2. on risque une erreur à chaque appel de cette chaîne
3. le déploiement d'évolutions sera potentiellement complexe car chaque service dépend du suivant

### Amélioration

Actuellement, on a 2 contraintes:

1. `Contracts` est la source des informations de contrat et des options souscrites.
2. `Users` est le point d'accès à `Contracts`.
3. `Photos` a besoin de ces informations.

Donc, on va commencer par déplacer le problème:

1. `Contracts` va rester la source des informations de contrat et des options souscrites.
2. `Users` va rester le point d'accès à `Contracts`.
3. `Photos` va conserver une copie de ces informations, copie qui sera rafraichie à chaque changement.

Pour résoudre ça, on va créer un process automatique, à base de webhooks. Il sera appelé à la création du contrat et à
chaque modification de celui-ci ou d'une option.

```mermaid
---
title: Cas réel - Création du contrat
---
sequenceDiagram
    actor BO as Application Back-Office

    participant US as Users
    participant CS as Contracts
    participant PS as Photos


    BO-)US: Créer le contrat ?
    activate US

    US-)CS: Créer le contrat<br/>et ses options
    activate CS
    CS-)US: Contrat créé
    deactivate CS

    US-)PS: Sauvegarder le contrat<br/>et ses options
    activate PS
    PS-)US: Copie effectuée
    deactivate PS


    US-)BO: Contrat créé
    deactivate US
```

#### Qu'est ce que ça change

Ça va permettre de limiter les appels entre `Photos` et `Users`. Par contre, qui dit mise en cache, dit cache à maintenir
coté `Photos`.

```mermaid
---
title: Cas réel - Appel au service Photos
---
sequenceDiagram
    actor AM as Application mobile
    participant PS as Photos


    AM-)PS: Récupérer les photos,<br/>l'utilisateur et son contrat ?

    activate PS
    PS-)PS: Récupérer les infos<br/>de l'utilisateur
    PS-)PS: Lister les photos
    PS-)AM: Photos, utilisateur<br/>et contrat
    deactivate PS
```

#### Les défauts

Si chacun des services appelant `Users` veut garder une copie du contrat, c'est autant de services
à appeler à la création ou au changement.

```mermaid
---
title: Cas réel - Création du contrat
---
sequenceDiagram
    actor BO as Application Back-Office

    participant US as Users
    participant CS as Contracts
    participant PS as Photos
    participant OS as Other service


    BO-)US: Créer le contrat ?
    activate US

    US-)CS: Créer le contrat<br/>et ses options
    activate CS
    CS-)US: Contrat créé
    deactivate CS

    US-)PS: Sauvegarder le contrat<br/>et ses options
    activate PS
    PS-)US: Copie effectuée
    deactivate PS

    Note right of US: Un appel par service<br/>qui en a besoin

    US-)OS: Sauvegarder le contrat<br/>et ses options
    activate OS
    OS-)US: Copie effectuée
    deactivate OS

    US-)BO: Contrat créé
    deactivate US
```
