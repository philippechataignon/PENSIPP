À propos de ce fork
===================

Cette version est un fork du [dépôt PENSIPP d'Antoine
Abozio](https://github.com/abozio/PENSIPP). La principale différence est
que tous les fichiers RData et les fichiers csv situés sous
/Modele/Parametres/Destinie/Importation des bios ont été supprimés, *y
compris de l'historique*, pour ramener le dépôt à une taille raisonnable
(35M au lieu de 1,2G). 

Les fichiers ont été enlevés en utilisant la [méthode
suivante](https://chataignon.com/git_rm.html). En conséquence la branche
``master`` de ce dépôt est divergente dès le premier commit du dépôt
d'origine.

Le projet [pensms](https://github.com/philippechataignon/pensms) est une
réécriture *from scratch* qui s'inspire de certains principes de
PENSIPP.  L'objectif est de reprendre l'implémentation sous R, car de
nombreuses optimisations sont possibles. PENSIPP fait un usage important
des boucles ``for`` dont on sait qu'elles sont peu performantes en R.

L'objectif de [pensms](https://github.com/philippechataignon/pensms) est
de reprendre les travaux existants en *vectorisant* les fonctions
concernant les individus, ce qui permet des gains très importants en
performance. On s'autorise une boucle temporelle car il y a en général
seulement quelques dizaines de périodes dans le modèle mais pas de
boucle individuelle car on veut pouvoir gérer plusieurs centaines de
milliers, voire millions d'individus.

PENSIPP - micro-simulation dynamique du système de retraite français
====================================================================

Enjeux : L’objectif du projet PENSIPP est de développer un modèle de
micro-simulation dynamique du système de retraite français afin de
pouvoir simuler l’impact de réformes passées ou potentielles du système.

Présentation du projet : PENSIPP est un modèle de micro-simulation dont
l’objectif principal est la projection des retraites sur le long terme.
A partir d’informations détaillées sur les trajectoires individuelles
(démographiques et professionnelles) issues d’un appariement statistique
entre les données de l’Echantillon interrégime des cotisants (EIC) et de
l’enquête Patrimoine, PENSIPP calcule les droits à la retraites à âge
donné d’après la législation du système de retraite français. PENSIPP
permet à la fois de décrire les différents mécanismes du système de
retraite actuel et d’expliciter leurs effets de long terme, mais
également de simuler et évaluer ex ante des réformes possibles du
système de retraite.

Partenaires: le modèle PENSIPP est développé dans le cadre d’un
partenariat scientifique entre l’IPP et la division « Redistribution et
politiques sociales » de l’Insee qui a développé le modèle de
micro-simulation Destinie, dont s’inspire en partie PENSIPP.

PENSIPP – dynamic micro-simulation model of the French pension system
=====================================================================

Motivation: The aim of the PENSIPP project is to develop a dynamic
micro-simulation model of the French pension system allowing to model
long term effects of actual or potential reforms of the pension system.

Project: PENSIPP is a dynamic micro-simulation model which rest on long
panel administrative data on earnings from the Echantillon interregime
des cotisants (EIC) matched with survey data from enquête Patrimoine
(i.e. French Wealth survey). The model simulates all pension rights at
all possible ages and can project earnings and pension in the long term.
PENSIPP allows analysing the impact of current features of the French
pension system while also simulating possible reforms that might be
contemplated.

Partners: PENSIPP is being developed within a scientific partnership
between the IPP and the French statistical office Insee, which has
developed the model Destinie from which PENSIPP is partly inspired.
