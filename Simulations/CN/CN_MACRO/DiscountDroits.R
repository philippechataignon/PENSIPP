############################### TRANSITIONS VERS UN SYSTEME DE COMPTES NOTIONNELS ###################
# Equilibrage du régime à court terme (disparition de la bosse)
# A partir de la date AnneeDebCN, tous les droits sont calcules dans le nouveau systeme. 
# Hypothese de depart en retraite: meme age que dans le scenario de reference
# Taux de cotisation 23 % + ANC
# Gestion de la bosse de début de période. 
# Réduction des pensions : 90% des droits acquis seulement. 

t0  <- Sys.time()

#### Chargement des programmes source ####
rm(list = ls())
# Déclaration du chemin pour les fichiers sources
cheminsource <- "/Users/simonrabate/Desktop/PENSIPP 0.1/"
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsMS.R"           )) )
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsPensIPP.R"      )) )
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsLeg.R"          )) )
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsRetr.R"         )) )
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsCN.R"           )) )

graph_compar <- function (serie,t1,t2,titre)
{
  plot   (seq(1900+t1,1900+t2,by=1),serie[1,t1:t2],xlab="Annee", ylab=titre,
          ylim=c(min(serie[,t1:t2],na.rm=TRUE),max(serie[,t1:t2],na.rm=TRUE)),lwd=2,col="orange",type="l")
  points (seq(1900+t1,1900+t2,by=1),serie[2,t1:t2],lwd=3,type="l")
  points (seq(1900+t1,1900+t2,by=1),serie[3,t1:t2],lwd=1,type="l")
  points (seq(1900+t1,1900+t2,by=1),serie[4,t1:t2],lwd=2,type="l")
}

# Declaration des variable d'outputs
TRC         <- numeric(taille_max)        # Taux de remplacemnt cible des liquidants
ageliq_     <- matrix(nrow=taille_max,ncol=3)
duree_liq   <- numeric(taille_max)
dar_        <- matrix(nrow=taille_max,ncol=3)
pliq_rg     <- matrix(nrow=taille_max,ncol=3)
pliq_     <- matrix(nrow=taille_max,ncol=3)
points_cn   <- numeric(taille_max)
pension_cn  <- numeric(taille_max)
conv        <- numeric(taille_max)
ageref      <- numeric(taille_max)
actifs      <- numeric(taille_max)        # Filtre population active
retraites   <- numeric(taille_max)        # Filtre population retraitée
liquidants  <- numeric(taille_max)
MSAL        <- matrix(nrow=4,ncol=200)    # Masse salariale par année
MPENS       <- matrix(nrow=4,ncol=200)    # Masse des pensions année
PIBREF      <- matrix(nrow=4,ncol=200)    # PIB annuel 
RATIOPENS   <- matrix(nrow=4,ncol=200)    # Ratio pension/PIB par année
RATIOFIN    <- matrix(nrow=4,ncol=200)    # Ratio masse des pensions/masse des salaires par année
RATIODEM    <- matrix(nrow=4,ncol=200)    # Ratio +60ans/-60ans par année
SALMOY      <- matrix(nrow=4,ncol=200)    # Salaire moyen par année
PENMOY      <- matrix(nrow=4,ncol=200)    # Pension moyenne par année
DUREE_LIQ   <- matrix(nrow=4,ncol=200)    # Duree totale a la liquidation
PLIQ_TOT    <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants par année
PLIQ_RG     <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants RG 
PLIQ_AR     <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants ARRCO par année
PLIQ_AG     <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants AGIRC par année
PLIQ_FP     <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants FP par année
PLIQ_IN     <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants indep par année
PLIQ_CN     <- matrix(nrow=4,ncol=200)    # Pension moyenne liquidants CN
POINTS_CN   <- matrix(nrow=4,ncol=200)    # Points CN moyens des liquidants par année
CONV_MOY    <- matrix(nrow=4,ncol=200)    # Coeff Conv moyen des liquidants par année
PENREL      <- matrix(nrow=4,ncol=200)    # Ratio pension/salaire
TRCMOY      <- matrix(nrow=4,ncol=200)    # Taux de remplacement cible des liquidants par année
FLUXLIQ     <- matrix(nrow=4,ncol=200)    # Effectifs de liquidants
AGELIQ      <- matrix(nrow=4,ncol=160)    # Age de liquidation moyen par année


W           <- 2047.501


#### Début de la simulation ####


for (sc in c(2,3))
  
{
  
  # Reinitialisation variables
  source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/DefVarRetr_Destinie.R")) )
  load  ( (paste0(cheminsource,"Modele/Outils/OutilsBio/BiosDestinie2.RData"        )) )  
  setwd ( (paste0(cheminsource,"Simulations/CN"                                    )) )
  
  duree_liq   <- rep(0,taille_max)
  points_cn   <- rep(0,taille_max)
  pension_cn  <- rep(0,taille_max)
  
  if (sc==3) {UseOptCN(c("discount","nomccn","nobonifcn","nomdacn","noavpfcn","noassimilcn"))}
  if (sc==2) {UseOptCN(c("nomccn","nobonifcn","nomdacn","noavpfcn","noassimilcn"))}
  plafond<-8
  
  for (t in 60:160)   # Début boucle temporelle
  {
    print (c(sc,t))
    if (sc>1)
    {
      AnneeDepartCN <- 115
      TauxCotCN[t]                 <- 0.27
      if (t <110) {RendementCN[t]  <- PIB[t]/PIB[t-1]-1} 
      else        {RendementCN[t]  <- log((MSAL[sc,t-1]*Prix[t-1])/(MSAL[sc,t-6]*Prix[t-6]))/5}
      RendementCNPrev[t]           <- RendementCN[t]
      RevaloCN[t+1]                <- Prix[t]/Prix[t-1]
      UseConv(55,70,t)
      #  print (CoeffConv[60:80])   
    }
    

    
    if (sc>1 && t==AnneeDepartCN)
    {
      for (i in 1:taille_max)
      {
        if (ageliq[i]==0)
        {
          statut[i,statut[i,1:160]>1]<- statut[i,statut[i,1:160]>1]+100          
        }
      }
    }
    
    
    
    # Liquidations  
    for (i in 1:taille_max)       # Début boucle individuelle
    {
      
      # Liquidation
      
      if ((t-t_naiss[i]>=55) && (ageliq[i]==0))
      {
        if (sc>1 && t>=AnneeDepartCN)
        {
          Leg <- t
          UseLeg(Leg,t_naiss[i])
          SimDir(i,t,"exo",ageref)
        }
        else
          # Cas ou CN n'ont pas démarré, liquidation taux plein et conservation age
        {
          Leg <- t
          UseLeg(Leg,t_naiss[i])
          SimDir(i,t,"TP")
        }
        
        if (t_liq[i]==t)
        {
          points_cn[i]  <- points_cn_pri+points_cn_fp+points_cn_ind
          pension_cn[i] <- pension_cn_pri[i]+pension_cn_fp[i]+pension_cn_ind[i]
          pliq_rg[i,sc] <- pension_rg[i]
          pliq_[i,sc] <- pension[i]
          dar_[i,sc]    <- dar[i]
          duree_liq[i]  <- duree_tot
          if (points_cn[i]>0) {conv[i] <- pension_cn[i]/points_cn[i]}
          if (sc==1) {ageref[i] <- t-t_naiss[i]}
        }
      } 
      
      else if (ageliq[i]>0)
      { 
        Revalo(i,t,t+1)    
      }
      
    } # Fin de la boucle individuelle 
    
    ageliq_[,sc] <- t_liq-t_naiss
    
    actifs     <- (salaire[,t]>0) & (statut[,t]>0)
    retraites  <- (pension>0) & (statut[,t]>0)
    liquidants <- (pension>0) & (t_liq==t)
    if (sc >0)
    {
      DUREE_LIQ[sc,t] <- mean(duree_liq[liquidants])
      PLIQ_TOT[sc,t]  <- mean(pension[liquidants])
      PLIQ_RG[sc,t]   <- mean(pension_rg[liquidants])     
      PLIQ_AR[sc,t]   <- mean(pension_ar[liquidants])
      PLIQ_AG[sc,t]   <- mean(pension_ag[liquidants])
      PLIQ_FP[sc,t]   <- mean(pension_fp[liquidants])
      PLIQ_IN[sc,t]   <- mean(pension_in[liquidants])
      PLIQ_CN[sc,t]   <- mean(pension_cn[liquidants])
      SALMOY[sc,t]    <- mean (salaire[actifs,t]/Prix[t])
      MPENS[sc,t]        <- W*sum(pension[retraites])/Prix[t]     
      MSAL[sc,t]         <- W*sum(salaire[actifs,t])/Prix[t] 
      PIBREF[sc,t]       <- MSAL[sc,t]*(PIB[109]/Prix[109])/MSAL[sc,109]
      RATIOPENS[sc,t]    <- MPENS[sc,t]/PIBREF[sc,t]
      TRCMOY[sc,t]       <- mean (TRC[which(t_liq[]==t)])
      RATIOFIN[sc,t]     <- MPENS[sc,t]/MSAL[sc,t]
      RATIODEM[sc,t]     <- sum  ((t-t_naiss>=60) & (statut[,t]>0))/sum((t-t_naiss<60) &(statut[,t]>0))
      PENMOY[sc,t]       <- mean (pension[retraites]/Prix[t])
      POINTS_CN[sc,t]    <- mean (points_cn[which( (pension>0)&t_liq==t)])
      CONV_MOY[sc,t]     <- mean (conv[     which( (pension>0)&t_liq==t)])      
      PENREL[sc,t]       <- PENMOY[sc,t]/SALMOY[sc,t]
      FLUXLIQ[sc,t]      <- W*sum(t_liq==t)
      AGELIQ[sc,t]       <- mean ( ageliq[which(t_liq==t)])
    }  
  } # Fin de de la boucle temporelle
  
  
  
} # Fin boucle scenarios



save.image(paste0(cheminsource,"Simulations/CN/CNeq2.RData"))



#### Sorties ####

load(paste0(cheminsource,"Simulations/CN/CN_MACRO/CNeq2.RData"))
RATIOPENSM   <- matrix(nrow=4,ncol=200) 
RATIOFINM   <- matrix(nrow=4,ncol=200) 
for (t in 110:159){RATIOPENSM[,t]<-(RATIOPENS[,(t-1)]+RATIOPENS[,(t)]+RATIOPENS[,(t+1)])/3}
for (t in 110:159){RATIOFINM[,t]<-(RATIOFIN[,(t-1)]+RATIOPENS[,(t)]+RATIOPENS[,(t+1)])/3}
par(mar=c(6.1, 3.1, 4.1, 2.1))
par(xpd=TRUE)
plot   (seq(2010,2059,by=1),RATIOPENS[1,110:159],xlab="Annee", ylab="ratio retraite/PIB",ylim=c(0.10,0.15),col="grey0",lwd=4,type="l")
points (seq(2010,2059,by=1),RATIOPENS[2,110:159],lwd=4,col="grey80",type="l")
points (seq(2010,2059,by=1),RATIOPENS[3,110:159],lwd=4,col="grey40",type="l")
title("Graphe 6 : Evolution du ratio retraites/PIB \n", cex.main = 0.9)
legend.text <- c("Scénario de référénce","CN","CN réduction droits acquis")
legend("bottom",inset=c(-0.2,-0.55),cex=0.8,legend.text, fill=c("grey0","grey80","grey40"))

par(mar=c(6.1, 3.1, 4.1, 2.1))
par(xpd=TRUE)
plot   (seq(2010,2059,by=1),RATIOFIN[1,110:159],xlab="Annee", ylab="ratio retraite/PIB",ylim=c(0.23,0.28),col="grey0",lwd=4,type="l")
points (seq(2010,2059,by=1),RATIOFIN[2,110:159],lwd=4,col="grey80",type="l")
points (seq(2010,2059,by=1),RATIOFIN[3,110:159],lwd=4,col="grey40",type="l")
title("Graphe 6b : Evolution du ratio retraites/salaires \n(taux 27%, no ANC)", cex.main = 0.9)
legend.text <- c("Scénario de référénce","CN","CN réduction droits acquis")
legend("bottom",inset=c(-0.2,-0.55),cex=0.8,legend.text, fill=c("grey0","grey80","grey40"))

load(paste0(cheminsource,"Simulations/CN/CN_MACRO/CNeq.RData"))
RATIOPENSM   <- matrix(nrow=4,ncol=200) 
RATIOFINM   <- matrix(nrow=4,ncol=200) 
for (t in 110:159){RATIOPENSM[,t]<-(RATIOPENS[,(t-1)]+RATIOPENS[,(t)]+RATIOPENS[,(t+1)])/3}
for (t in 110:159){RATIOFINM[,t]<-(RATIOFIN[,(t-1)]+RATIOPENS[,(t)]+RATIOPENS[,(t+1)])/3}
par(mar=c(6.1, 3.1, 4.1, 2.1))
par(xpd=TRUE)
plot   (seq(2010,2059,by=1),RATIOPENS[1,110:159],xlab="Annee", ylab="ratio retraite/PIB",ylim=c(0.10,0.15),col="grey0",lwd=4,type="l")
points (seq(2010,2059,by=1),RATIOPENS[2,110:159],lwd=4,col="grey80",type="l")
points (seq(2010,2059,by=1),RATIOPENS[3,110:159],lwd=4,col="grey40",type="l")
title("Graphe 6 : Evolution du ratio retraites/PIB \n(taux 25.8%, no ANC)", cex.main = 0.9)
legend.text <- c("Scénario de référénce","CN","CN réduction droits acquis")
legend("bottom",inset=c(-0.2,-0.55),cex=0.8,legend.text, fill=c("grey0","grey80","grey40"))

par(mar=c(6.1, 3.1, 4.1, 2.1))
par(xpd=TRUE)
plot   (seq(2010,2059,by=1),RATIOFIN[1,110:159],xlab="Annee", ylab="ratio retraite/PIB",ylim=c(0.20,0.28),col="grey0",lwd=4,type="l")
points (seq(2010,2059,by=1),RATIOFIN[2,110:159],lwd=4,col="grey80",type="l")
points (seq(2010,2059,by=1),RATIOFIN[3,110:159],lwd=4,col="grey40",type="l")
title("Graphe 6a : Evolution du ratio retraites/salaires \n(taux 23%, ANC)", cex.main = 0.9)
legend.text <- c("Scénario de référénce","CN","CN réduction droits acquis")
legend("bottom",inset=c(-0.2,-0.55),cex=0.8,legend.text, fill=c("grey0","grey80","grey40"))

