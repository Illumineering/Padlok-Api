//
//  FrequentlyAskedQuestions.swift
//  
//
//  Created by Thomas Durand on 19/09/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Vapor

struct FrequentlyAskedQuestion: Content, Equatable {
    // TODO: Better language modelization for categories?
    struct Category: Content, Equatable {
        let name: String
        let icon: String
    }

    let category: Category
    let question: String
    let answer: String
}

extension FrequentlyAskedQuestion.Category {
    // English
    static let gettingStarted = Self(name: "Getting started", icon: "lightbulb")
    static let notifications = Self(name: "Notifications", icon: "bell")
    static let sharing = Self(name: "Sharing", icon: "person.2")
    static let privacy = Self(name: "Privacy", icon: "hand.raised")
    static let premium = Self(name: "Premium", icon: "star")

    // French
    static let commencer = Self(name: "Commencer", icon: "lightbulb")
    static let partage = Self(name: "Partage", icon: "person.2")
    static let confidentialite = Self(name: "Confidentialité", icon: "hand.raised")
}

extension Array where Element == FrequentlyAskedQuestion {
    static func adapted(for language: Language) -> [FrequentlyAskedQuestion] {
        switch language {
        case .english:
            return [
                .init(
                    category: .gettingStarted,
                    question: "How to add an address to Padlok?",
                    answer: "Start by tapping the + button on the main screen. You can then either tap an address in the search field, or select an address from one of your contacts."
                ),
                .init(
                    category: .gettingStarted,
                    question: "Why doesn’t my address have any code associated?",
                    answer: "Padlok takes data privacy very seriously. For that reason, it only knows about the code your provide. It’ll never use a shared database ; or feed an external database with your code. Your data is yours, and stay yours."
                ),
                .init(
                    category: .notifications,
                    question: "How to enable notifications?",
                    answer: "After you’ve added your first address, enable the switch labeled “Show info when I’m near”. When applicable, you must allow the application to localize you, and to send you notification."
                ),
                .init(
                    category: .notifications,
                    question: "When do notification trigger themselves?",
                    answer: "Notifications will trigger when the application considers itseft close enough to the address. To improve accuracy, make sure to set the localisation permission to “Always”."
                ),
                .init(
                    category: .notifications,
                    question: "I wasn’t notified when I expected I would, what happened?",
                    answer: "Notifications rely on the iOS geofencing that will wake the application when you enter a pre-defined area around the address. Padlok does not know where you are at every moment, and is just awaken by the system. Sometime the system won’t awake Padlok. Because the localization accuracy is not enough, or because low power mode is enabled ; or even when background refresh is disabled. Make sure that no warning message is shown below the notification switch. If so, notification might not work properly."
                ),
                .init(
                    category: .sharing,
                    question: "Can I share some address information to someone that does not have Padlok installed?",
                    answer: "Sure! Sharing using a link works for everyone that have an internet connection and a navigator up to date. On iOS, an AppClip will open a native experience and suggest the application for installation so they can make the shared code their own."
                ),
                .init(
                    category: .sharing,
                    question: "A code have changed, can I update the link I’ve already shared?",
                    answer: "Of course! The application will suggest it for you. You’ll have two choices for updating the link: Updating it, making the new codes available without updating the link, or recreate it, so that old link become unavailable. The second option is better if you don’t want anyone that have the link to access the updated information."
                ),
                .init(
                    category: .privacy,
                    question: "What data is collected by Padlok?",
                    answer: "Padlok asks you for you location. But the location is only used on your device and is never send to the outside world. The only data Padlok collects are anonymized, and are all for purchases managements and statistics; or for analytics and performance monitoring. Padlok does not gather any personal data, any address or any address info."
                ),
                .init(
                    category: .privacy,
                    question: "Where is my data stored and is it accessible by others?",
                    answer: "Your application data is stored on device, and in iCloud if enabled on device. Only your devices connected to the same iCloud account can access this data. Nobody else."
                ),
                .init(
                    category: .privacy,
                    question: "How is stored the data I shared with a link?",
                    answer: "Not in an exploitable way. When you generate a share link, your data is encrypted *on your device*, and then sent to my servers in France. The encryption key is in the url. Without the url, there is no way to actually access the data. I cannot access your data, and nobody should. When opening the link, either the application, or the website will decrypt the data sent by my server *on your device*. Therefore, this is a end-to-end encryption mecanism."
                ),
                .init(
                    category: .premium,
                    question: "What happens after my subscription ends?",
                    answer: "After you subscription ends, you will lose the premium features that are attached. If you have more than three addresses created, you will only be able to consult the three closest; so you won’t loose any data. And you’ll be free to delete any addresses you want."
                ),
                .init(
                    category: .premium,
                    question: "Can I upgrade to lifetime premium before my subscription ends?",
                    answer: "Yes, you can! First you’ll need to cancel your subscription renewall, then a button “Upgrade to lifetime” will be available in the about screen with a lower price."
                ),
            ]
        case .french:
            return [
                .init(
                    category: .commencer,
                    question: "Comment ajouter une adresse à Padlok ?",
                    answer: "Commencez par tapper le bouton + sur l’écran principal. Vous pouvez ensuite soit trouver une adresse avec le champ de recherche, ou sélectionnez une adresse depuis l’un de vos contacts."
                ),
                .init(
                    category: .commencer,
                    question: "Pourquoi mon adresse n’a aucun code associé ?",
                    answer: "Padlok prend la confidentialité des données très au sérieux. Pour cette raison, l’app ne connait que les codes que vous entrez. Elle n’utilisera jamais une base de donnée partagée, ni n’alimentera une telle base avec vos données. Vos données sont les votres, et le resteront."
                ),
                .init(
                    category: .notifications,
                    question: "Comment activer les notifications ?",
                    answer: "Après avoir ajouté au moins une adresse, activez le bouton labelisé “Me prévenir à proximité”. Le cas échéant, vous devez autoriser l’application à vous localiser, et à vous envoyer des notifications."
                ),
                .init(
                    category: .notifications,
                    question: "Quand les notifications sont-elle envoyées ?",
                    answer: "Les notifications vont être envoyées lorsque l’application détectera que vous êtes suffisament près de l’adresse associée. Pour améliorer la précision, passez l’autorisation de l’application à vous localiser sur “Toujours”."
                ),
                .init(
                    category: .notifications,
                    question: "Je n’ai pas été notifié alors que j’aurai dû. Que s’est-il passé ?",
                    answer: "Les notification utilisent le géorepérage d’iOS ; qui réveillera l’application lorsque vous entrez dans une zone pré-définie autour de l’adresse. Padlok ne connait pas votre position à chaque instant, elle se contente d’attendre que le système la réveille, ce qui peut ne pas arriver, généralement parce que la précision de la localisation n’est pas suffisante, ou que le mode “Économie d’énergie” est activé ; ou encore que les actualisations en arrière plan ne sont pas actives. Assurez-vous de ne pas avoir de message d’alerte sous le bouton d’activation des notifications. Si c’est le cas, il est probable que les notifications ne fonctionnent pas correctement."
                ),
                .init(
                    category: .partage,
                    question: "Puis-je partager les informations d’une adresse à quelqu’un qui n’a pas installé Padlok ?",
                    answer: "Bien sûr ! Le partage utilise un lien qui fonctionne pour n’importe qui avec une connexion internet, et un navigateur à jour. Sur iOS, un “Extrait d’app” s’ouvrira avec une expérience native qui suggèrera l’installation de l’application complète pour enregistrer les codes sur leur appareil."
                ),
                .init(
                    category: .partage,
                    question: "Un code a changé, puis-je mettre à jour un lien déjà partagé ?",
                    answer: "Oui ! L’application va vous le proposer. Vous aurez alors deux choix pour modifier le lien : le mettre à jour, rendant les nouveaux codes disponibles sans modifier le lien ; ou de le re-générer de façon à ce que l’ancien lien devienne inutilisable. La seconde option est adaptée si vous ne souhaitez pas que les personnes à qui vous avez envoyé le lien puissent accéder aux nouvelles informations."
                ),
                .init(
                    category: .confidentialite,
                    question: "Quelles sont les données collectées par Padlok ?",
                    answer: "Padlok vous demande l’authorisation de vous géolocaliser. Mais cette localisation n’est utilisée que par l'application sur votre appareil, et n’est jamais envoyée au monde extérieur. Les seule données que Padlok récupère sont anonymisées, et sont soit dans un but de gestion et analyse des achats, ou pour assurer la qualité de l'application et de ses performances. Padlok n’organise pas la récolte de données personnelles, de vos adresses, ou de vos informations associées."
                ),
                .init(
                    category: .confidentialite,
                    question: "Où mes données sont-elles stockées, et sont-elles accessibles par quiquonque ?",
                    answer: "Les données de l’application sont stockées sur votre appareil, et dans iCloud si ce dernier est activé. Seuls vos appareils connectés au même compte iCloud peuvent accéder à ces informations. Personne d’autre."
                ),
                .init(
                    category: .confidentialite,
                    question: "Comment sont stockées les données partagées par un lien ?",
                    answer: "Pas d’une façon exploitable. Lorsque vous générez un lien de partage, vos données sont chiffrées *sur votre appareil*, et ensuite envoyées sur mes serveurs en France. La clé de chiffrement est inclue dans l’url. Sans cette url, il est impossible d’accéder à vos données. Je ne peux pas accéder à vos données, et personne d’autre ne le pourrait. Lorsqu’un lien est ouvert, soit l’application, ou le site va déchiffrer les données renvoyées par mon serveur *sur votre appareil*. Par conséquent, il s’agit d’un chiffrement bout en bout."
                ),
                .init(
                    category: .premium,
                    question: "Que se passe-t-il lorsque mon abonnement prend fin ?",
                    answer: "À la fin de votre abonnement, vous perdrez tous les avantages Premium qui y sont attachés. Si vous avez plus de trois adresses, vous ne pourrez consulter que les trois plus proches ; vous ne perdez donc aucune de vos données. Vous serez toujours libre de supprimer n’importe quelle adresse."
                ),
                .init(
                    category: .premium,
                    question: "Puis-je passer à un abonnement à vie avant la fin de mon abonnement annuel ?",
                    answer: "Oui ! Tout d’abord, vous devrez annuler le renouvellement de votre abonnement, ensuite, un bouton “Conserver à vie” sera disponible sur l’écran à propos à tarif réduit."
                ),
            ]
        }
    }
}
