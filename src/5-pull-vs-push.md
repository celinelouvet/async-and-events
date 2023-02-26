# 5. Publisher / Subscriber

## 1. Qu'est ce que ça veut dire ?

Pour pouvoir traiter ces événements, on peut s'appuyer sur le modèle publisher / subscriber. Les consommateurs (subscribers)
vont s'inscrire auprès du bus d'événements comme étant prêts à consommer les événements d'un certain topic.

On va souvent se retrouver dans 3 situations:

1. Un publisher et plusieurs subscribers
2. Plusieurs publishers et un subscriber
3. Plusieurs publishers et plusieurs subscribers

```mermaid
---
title: Un publisher et plusieurs subscribers
---
graph LR
  P(Publisher) -- publish on<br/>specific-topic --> EventBus[[EventBus]]
  EventBus  -- consumes<br/>specific-topic --> S1(Subscriber 1)
  EventBus  -- consumes<br/>specific-topic --> S2(Subscriber 2)
  EventBus  -- consumes<br/>specific-topic --> S3(Subscriber 3)
```

```mermaid
---
title: Plusieurs publishers et un subscriber
---
graph LR
  P1(Publisher 1) -- publish on<br/>specific-topic --> EventBus[[EventBus]]
  P2(Publisher 2) -- publish on<br/>specific-topic --> EventBus
  P3(Publisher 3) -- publish on<br/>specific-topic --> EventBus
  EventBus  -- consumes<br/>specific-topic --> S(Subscriber)
```

```mermaid
---
title: Plusieurs publishers et plusieurs subscribers
---
graph LR
  P1(Publisher 1) -- publish on<br/>specific-topic --> EventBus[[EventBus]]
  P2(Publisher 2) -- publish on<br/>specific-topic --> EventBus
  P3(Publisher 3) -- publish on<br/>specific-topic --> EventBus

  EventBus  -- consumes<br/>specific-topic --> S1(Subscriber 1)
  EventBus  -- consumes<br/>specific-topic --> S2(Subscriber 2)
  EventBus  -- consumes<br/>specific-topic --> S3(Subscriber 3)
```

Si on reprend le schéma précédent, avec le principe de publisher / subscriber, `S1` n'a pas besoin de savoir que `S2` sera
celui qui va exécuter le traitement. Il a juste l'assurance que quelqu'un le fera.

```mermaid
---
title: Déclenchement asynchrone par événement
---
sequenceDiagram
    participant S1
    participant EB as EventBus
    participant S2

    activate EB
    activate S1
    Note right of S1: Début du traitement<br/>de S1
    S1-)EB: Envoyer l'événement
    Note right of S1: Suite du traitement<br/>de S1
    deactivate S1

    EB-)S2: Déclencher le traitement
    activate S2
    Note right of S2: Traitement<br/>de S2
    S2--)EB: Résultat du traitement
    deactivate S2
    deactivate EB
```

### Qu'est ce que ça implique ?

Suivant la configuration choisie, les consommateurs vont consommer différemment les événements:

- le push: le consommateur sera déclenché automatiquement par le bus dès qu'un évenement est disponible.
- le pull: le consommateur viendra régulièrement vérifier **si un événement est disponible**

Certaines plateformes fournissent aussi le `batch-pull`. Le consommateur viendra régulièrement vérifier **si un lot
d'événements est disponible**

Pour choisir la méthode, il faut répondre à plusieurs questions:

1. est-ce que je peux traiter plusieurs événements en parallèle ?
2. quelle la fréquence de cet événement ?

```mermaid
---
title: Méthode à employer
---
stateDiagram-v2
  state "plusieurs événements<br/>en parallèle ?" as can_parallel
  state if_parallels <<choice>>
  state "Push" as push

  state "plusieurs événements<br/> en même temps" as can_batch
  state if_batch <<choice>>
  state "Pull" as pull
  state "Batch-pull" as batch_pull

  [*] --> can_parallel
  can_parallel --> if_parallels
  if_parallels --> push : Oui
  if_parallels --> can_batch: Non
  can_batch --> if_batch
  if_batch --> pull: Non
  if_batch --> batch_pull: Oui
```

Si la réponse à la 1ère question est oui, alors on peut envisager de faire du `push`. L'avantage principal étant que le
consommateur sera notifié par l'event bus. Il n'y a rien à prévoir en plus.

Si non, alors on n'a pas d'autre choix que de faire du `pull`. Ca permettra au service consommateur de traiter les événements
à son propre rythme. Par contre, il faudra mettre en place un système manuel pour vérifier si un événement est disponible.

Si on en a la possibilité et qu'on souhaiter grouper les événements, on peut utiliser la méthode du `batch-pull`.

## 2. Dans notre situation réelle

On reprend notre cas d'usage du début: l'utilisateur veut, via son application mobile, afficher sa liste de photos.

![Photos list](2-synchrone.png)

[Maquette](https://www.figma.com/file/Wx4WtmrKsUsHAtiedGGZMQ/Asynchrone?node-id=4%3A74&t=rEqGLtgCcFsp1KDf-4)

Photos de [Pixabay](https://pixabay.com)

On avait mis en place un système de cache coté `Photos` pour limiter les appels vers `Users` et `Contracts` à chaque
affichage de la liste. Mais ce cache demandait une maintenance automatique de celui-ci.

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

    Note over US,OS: Un appel par service qui en a besoin

    US-)PS: Sauvegarder le contrat<br/>et ses options
    activate PS
    PS-)US: Copie effectuée
    deactivate PS

    US-)OS: Sauvegarder le contrat<br/>et ses options
    activate OS
    OS-)US: Copie effectuée
    deactivate OS

    US-)BO: Contrat créé
    deactivate US
```

### Amélioration

Au lieu d'appeler directement chacun des services, `Users` va maintenant publier un événement, événement qui sera consommé
par qui en a besoin.

```mermaid
---
title: Cas réel - Création du contrat
---
sequenceDiagram
    actor BO as Application Back-Office

    participant US as Users
    participant CS as Contracts
    participant EB as EventBus
    participant PS as Photos
    participant OS as Other service


    BO-)US: Créer le contrat ?
    activate US

    US-)CS: Créer le contrat<br/>et ses options
    activate CS
    CS-)US: Contrat créé
    deactivate CS

    US--)EB: Publier sur le topic "contracts-creation"
    Note over US,EB: Les informations du contrat<br/>sont présentes dans l'événement
    US-)BO: Contrat créé
    deactivate US

    par chaque subscriber consomme l'événement
      EB-)PS: Sauvegarder le contrat<br/>et ses options
      activate PS
      PS--)EB: Copie effectuée
      deactivate PS
    and
      EB-)OS: Sauvegarder le contrat<br/>et ses options
      activate OS
      OS--)EB: Copie effectuée
      deactivate OS
    end

```

#### Qu'est ce que ça change

`Users` n'a qu'un seul événement à envoyer. De plus, il n'a pas besoin de se préoccuper de qui le consommera. L'eventBus
se chargera lui-même de gérer la consommation par les différents subscribers.

#### Les défauts
