# 4. Utilisation des événements

## 1. Qu'est ce que ça veut dire ?

Comme on vient de le voir, il y a des situations où on va avoir besoin d'être sûrs qu'un traitement soit fait, même si
on ne souhaite pas en attendre la fin.

Dans ce genre de situation, on va avoir recours à un système par événements. Lors de son execution, `S1` va déposer un
"jeton" (un événement) dans une queue. Ce jeton sera traité par un consommateur.

```mermaid
---
title: Déclenchement asynchrone par événement
---
graph LR
  S1(S1) --> EventBus[[EventBus]] --> S2
```

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

```mermaid
---
title: Déclenchement asynchrone par événement - Cas d'une erreur
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
    Note right of S2: Erreur lors du<br/>traitement de S2
    S2--)EB: Erreur
    deactivate S2

    Note right of EB: N tentatives

    EB-)S2: Déclencher le traitement
    activate S2
    Note right of S2: Traitement de<br/>S2
    S2--)EB: Résultat
    deactivate S2

    deactivate EB
```

### Pourquoi faire ça ?

L'intéret de ce genre de système est de pouvoir séparer la responsabilité d'executer correctement le traitement de `S2`
du traitement de `S1`.

### Avantages

- Suivant sa configuration, la queue gèrera elle-même les tentatives en cas d'erreur.
- On peut mettre un système d'alerte pour notifier en cas de dépassement du nombre de tentatives

### Inconvénients

- On ne sait pas si le traitement de `S2` s'est bien terminé

Toujours le même inconvénient: `S1` ne sait pas si le traitement de `S2` a eu lieu => impose de se poser les questions autrement.

## 2. Dans notre situation réelle

On reprend notre cas d'usage précédent: l'utilisateur veut, via son application mobile, partager une photo par email
à un ami.

![Share modal](3-asynchrone.png)

[Maquette](https://www.figma.com/file/Wx4WtmrKsUsHAtiedGGZMQ/Asynchrone?node-id=8%3A78&t=rEqGLtgCcFsp1KDf-4)

Photos de [Pixabay](https://pixabay.com)

### Amélioration

On va déclencher `Notifications` via un événement et non plus directement. Ça permettra de déméler un peu le sac de noeuds
fait précédemment.

```mermaid
---
title: Cas réel - Macro vue
---
graph LR
    subgraph SI 1
        direction LR
        PS(Photos) --> US(Users)
        NS(Notifications) --> US
    end
    subgraph SI 2
        direction TB
        US --> CS(Contracts)

    end
    NS --> Emails
    NS --> SMS
```

```mermaid
---
title: Cas réel - Envoi d'email via EventBus
---
sequenceDiagram
    actor AM as Application mobile
    participant PS as Photos
    participant EB as EventBus
    participant NS as Notifications
    participant US as Users
    participant Email as Service tiers Email


    activate EB
    AM-)PS: Confirme l'envoi
    activate PS
    PS--)EB: Envoyer l'évenment<br/>d'envoi d'email
    PS-)AM: Afficher "Email envoyé"<br/>= Promesse d'envoi
    deactivate PS

    EB-)NS: Envoyer l'email
    activate NS
    NS-)US: Récupérer l'adresse<br/>email de l'utilisateur
    activate US
    US--)NS: Adresse email
    deactivate US

    NS-)Email: Envoyer l'email
    activate Email
    Email--)NS: Email envoyé
    deactivate Email

    NS--)EB: Envoi réussi
    deactivate NS
    deactivate EB
```

```mermaid
---
title: Cas réel - Envoi d'email via EventBus - User surchargé
---
sequenceDiagram
    actor AM as Application mobile
    participant PS as Photos
    participant EB as EventBus
    participant NS as Notifications
    participant US as Users 🥵
    participant Email as Service tiers Email


    activate EB
    AM-)PS: Confirme l'envoi
    activate PS
    PS--)EB: Envoyer l'évenment<br/>d'envoi d'email
    PS-)AM: Afficher "Email envoyé"<br/>= Promesse d'envoi
    deactivate PS

    EB-)NS: Envoyer l'email
    activate NS
    NS-xUS: Tenter de récupérer l'adresse<br/>email de l'utilisateur
    NS--)EB: Erreur
    deactivate NS

    Note right of EB: 2ème tentative

    EB-)NS: Envoyer l'email
    activate NS
    NS-)US: Récupérer l'adresse<br/>email de l'utilisateur
    activate US
    US--)NS: Adresse email
    deactivate US

    NS-)Email: Envoyer l'email
    activate Email
    Email--)NS: Email envoyé
    deactivate Email

    NS--)EB: Envoi réussi
    deactivate NS
    deactivate EB
```

#### Qu'est ce que ça change

1. `Photos` n'attend plus la confirmation d'envoi de l'email => On **promet** l'envoi de l'email à notre utilisateur.
2. `Photos` n'a plus besoin de parler à `Notifications` pour **demander** l'envoi de l'email => dépendance de déploiement
   en moins
3. C'est le service `Notifications` qui a la connaissance pour tout ce qui est envoi d'emails. D'ailleurs `Notifications`
   pourrait aussi bien envoyer un SMS qu'un email.
4. Le bus d'événements se charge de resseayer l'envoi en cas d'erreur dans le traitement de `Notifications`

#### Les défauts

- Une queue de traitement, qui déclenche forcément Notifications => la queue doit connaitre Notifications
- Charge de `Notifications` si beaucoup d'envois
