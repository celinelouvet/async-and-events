# 2. Appels synchrones

## 1. Qu'est ce que ça veut dire ?

Un service `Service 1` appelle un 2ème service `Service 2`. Il va attendre le résultat pour la suite de son traitement.

```mermaid
---
title: Appel synchrone
---
sequenceDiagram
    participant S1 as Service 1
    participant S2 as Service 2

    activate S1
    Note right of S1: Début du traitement<br/>du Service 1
    S1->>S2: Récupérer une info ?
    activate S2
    Note over S1,S2: En attente de Service 2
    S2->>S1: Info
    deactivate S2

    Note right of S1: Suite du traitement<br/>du Service 1
    deactivate S1
```

### Pourquoi faire ça ?

- Quand on a besoin d'avoir la réponse pour poursuivre le traitement.
- Quand on veut être sûr qu'une action s'est bien terminée pour poursuivre le traitement.

### Avantages

- Le résultat obtenu est à jour.
- On a la garantie que le traitement de `Service 2` s'est correctement effectué.

### Inconvénients

- Le traitement de `Service 1` est en pause le temps que `Service 2` réponde.
- Gestion des erreurs si :
  - `Service 2` est down
  - `Service 2` est trop long (timeout)

## 2. Dans notre situation réelle

L'utilisateur veut, via son application mobile, afficher sa liste de photos.

![Photos list](2-synchrone.png)

[Maquette](https://www.figma.com/file/Wx4WtmrKsUsHAtiedGGZMQ/Asynchrone?node-id=4%3A74&t=rEqGLtgCcFsp1KDf-4)

Photos de [Pixabay](https://pixabay.com)

```mermaid
C4Context
  title Cas réel

  Person_Ext(PhotosUser, "Photos App")

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

  Rel(UsersService, UsersDB, "Stores")

  Rel(ContractsService, ConstractsDB, "Stores")

  Rel(PhotosService, UsersService, "Uses")
  Rel(UsersService, ContractsService, "Uses")

  UpdateLayoutConfig($c4ShapeInRow="2", $c4BoundaryInRow="2")
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
    CS->>US: Contrat

    %% fin SI 2

    deactivate CS
    US->>PS: Utilisateur
    deactivate US
    PS->>PS: Lister les photos

    %% fin SI 1
    deactivate PS

    PS->>AM: Photos, utilisateur<br/>et contrat
```

### Les questions qu'on peut se poser

- qu'est ce qui se passe si beaucoup d'utilisateurs récupèrent les données ?
- qu'est ce qui se passe si `Users` est down ou surchargé ?
- qu'est ce qui se passe si `Contracts` est down ou surchargé ?

### Les problèmes possibles

- lenteurs à chaque appel
- Erreur à chaque appel
