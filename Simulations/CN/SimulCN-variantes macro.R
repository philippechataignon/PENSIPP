############################### TRANSITIONS VERS UN SYSTEME DE COMPTES NOTIONNELS ###################
# CN1a : Valorisation des cotisations passees. 
# A partir de la date AnneeDebCN, tous les droits sont calcules dans le nouveau systeme. 
# Hypoth?se de d?part en retraite: m?me ?ge que dans le sc?nario de r?f?rence
# On applique un taux de cotisation fixe, par exemple celui qui equilibre le regime actuel a la date de debut de transition. 

t0  <- Sys.time()

#### Chargement des programmes source ####

# Déclaration du chemin pour les fichiers sources
cheminsource <- "/Users/didier/Desktop/PENSIPP 0.0/"
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
ageliq_     <- matrix(nrow=taille_max,ncol=4)
duree_liq   <- numeric(taille_max)
dar_        <- matrix(nrow=taille_max,ncol=4)
pliq_rg     <- matrix(nrow=taille_max,ncol=4)
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
cibletaux<-numeric(taille_max)




#### Début de la simulation ####

load(file=(paste0(cheminsource,"Simulations/CN/ref.RData")))
#  Rprof(tmp<-tempfile())
for (sc in c(1,2,3,4))

{
  
  # Reinitialisation variables
  source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/DefVarRetr_Destinie.R")) )
  load  ( (paste0(cheminsource,"Modele/Outils/OutilsBio/BiosDestinie2.RData"        )) )  
  setwd ( (paste0(cheminsource,"Simulations/CN"                                    )) )
  
  duree_liq   <- rep(0,taille_max)
  points_cn   <- rep(0,taille_max)
  pension_cn  <- rep(0,taille_max)
  
  #Parametre de liquidation: TRC (cible et seuil)
  for (i in 1:taille_max)
  {
    if (sexe[i]==1){k[i]     <-LogLogist(0.01,1,0.5,1.2) } else {k[i]<-LogLogist(0.01,1,0.5,1.5)}
    delta_k[i] <- 0.01       # Augmentation de 1% par an après 60 ans (cf SimDir)
    beta[i]     <-200        # Seuil: élevé (TRC)  
  }
  cibletaux<-numeric(taille_max)

  
  for (t in 60:160)   # Début boucle temporelle
  {
    print (c(sc,t))
    if (sc>1)
    {
      AnneeDepartCN <- 115
      TauxCotCN[t]                 <- 0.27 #MPENS[1,115]/MSAL[1,115]
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
          for (u in 1:160)   # Variante 1:160
          {
            if (is.element(statut[i,u],codes_act))
            {
              statut[i,u] <- statut[i,u]+100
            }
          }
        }
      }
    }
      
      
    # Liquidations  
    for (i in 1:taille_max)       # Début boucle individuelle
    {
      
      # Liquidation

      if ((t-anaiss[i]>=55) && (ageliq[i]==0))
      {
        if (sc>1 && t>=AnneeDepartCN)
        {
          Leg <- t
          UseLeg(Leg,anaiss[i])
          SimDir(i,t,"exo",ageref)
#           if (t==115 && i==632) 
#           {
#             print (c(sc,t,i,anaiss[i],duree_rg,duree_tot,duree_rg_maj,duree_tot_maj,
#                      sam_rg,dar[i],pension_rg[i],statut[i,anaiss[i]:t]))
#           }
        }
        else
        # Cas ou CN n'ont pas démarré, liquidation taux plein et conservation age
        {
          Leg <- t
          UseLeg(Leg,anaiss[i])
          SimDir(i,t,"TP")
#           if (t==115 && i==632) 
#           {
#             print (c(sc,t,i,anaiss[i],duree_rg,duree_tot,duree_rg_maj,duree_tot_maj,
#                      sam_rg,dar[i],pension_rg[i],statut[i,anaiss[i]:t]))
#           }
        }
        
        if (liq[i]==t)
        {
          points_cn[i]  <- points_cn_pri+points_cn_fp+points_cn_ind
          pension_cn[i] <- pension_cn_pri[i]+pension_cn_fp[i]+pension_cn_ind[i]
          pliq_rg[i,sc] <- pension_rg[i]
          dar_[i,sc]    <- dar[i]
          duree_liq[i]  <- duree_tot
          if (points_cn[i]>0) {conv[i] <- pension_cn[i]/points_cn[i]}
          if (sc==1) {ageref[i] <- t-anaiss[i]}
        }
      } 
      
      else if (ageliq[i]>0)
      { 
        Revalo(i,t,t+1)    
      }
      
    } # Fin de la boucle individuelle 

    ageliq_[,sc] <- liq-anaiss

    actifs     <- (salaire[,t]>0) & (statut[,t]>0)
    retraites  <- (pension>0) & (statut[,t]>0)
    liquidants <- (pension>0) & (liq==t)
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
      ### Correction des salaires s'il y a lieu
      ### NB : on redresse au fur et à mesure l'ensemble des salaires prospectifs, pour minimiser
      ### redressement à chaque date
      if (sc == 3 && t>=112) 
      {
        salaire[,t:160] <- salaire[,t:160]*SALMOY[sc,t-1]*1.01/SALMOY[sc,t]
        PlafondSS[t+1]  <- PlafondSS[t]*1.01
      }
      if (sc == 4 && t>=112) 
      {
        salaire[,t:160] <- salaire[,t:160]*SALMOY[sc,t-1]*1.02/SALMOY[sc,t]
        PlafondSS[t+1]  <- PlafondSS[t]*1.02
      }    
      SALMOY[sc,t]       <- mean (salaire[actifs,t]/Prix[t])    
      MPENS[sc,t]        <- W*sum(pension[retraites])/Prix[t]     
      MSAL[sc,t]         <- W*sum(salaire[actifs,t])/Prix[t] 
      PIBREF[sc,t]       <- MSAL[sc,t]*(PIB[109]/Prix[109])/MSAL[sc,109]
      RATIOPENS[sc,t]    <- MPENS[sc,t]/PIBREF[sc,t]
      TRCMOY[sc,t]       <- mean (TRC[which(liq[]==t)])
      RATIOFIN[sc,t]     <- MPENS[sc,t]/MSAL[sc,t]
      RATIODEM[sc,t]     <- sum  ((t-anaiss>=60) & (statut[,t]>0))/sum((t-anaiss<60) &(statut[,t]>0))
      PENMOY[sc,t]       <- mean (pension[retraites]/Prix[t])
      POINTS_CN[sc,t]    <- mean (points_cn[which( (pension>0)&liq==t)])
      CONV_MOY[sc,t]     <- mean (conv[     which( (pension>0)&liq==t)])      
      PENREL[sc,t]       <- PENMOY[sc,t]/SALMOY[sc,t]
      FLUXLIQ[sc,t]      <- W*sum(liq==t)
      AGELIQ[sc,t]       <- mean ( ageliq[which(liq==t)])
    }  
  } # Fin de de la boucle temporelle
  


} # Fin boucle scenarios



#### Sorties ####
graph_compar(RATIOPENS       ,110,159,"Ratio pension/PIB")
graph_compar(RATIOFIN        ,110,159,"Ratio Financier")
graph_compar(RATIODEM        ,110,159,"Ratio Démographique")
graph_compar(SALMOY          ,110,159,"Salaire moyen")
graph_compar(PENMOY          ,110,159,"Pension moyenne")
graph_compar(PENREL          ,110,159,"Ratio pension/salaire")
graph_compar(FLUXLIQ         ,110,159,"Flux de liquidants");
graph_compar(AGELIQ          ,110,159,"Age moyen de liquidation")
graph_compar(POINTS_CN       , 90,159,"Points CN a la liquidation")
graph_compar(CONV_MOY        ,115,159,"Coeff conv moyen a la liquidation")
graph_compar(DUREE_LIQ       , 90,159,"Dureee tous régimes a la liquidation")
graph_compar(PLIQ_TOT        , 90,159,"Pension totale à la liquidation")
graph_compar(PLIQ_RG         , 90,159,"Pension RG à la liquidation")
graph_compar(PLIQ_AR         , 90,159,"Pension arrco à la liquidation")
graph_compar(PLIQ_AG         , 90,159,"Pension agirc à la liquidation")
graph_compar(PLIQ_FP         , 90,159,"Pension FP à la liquidation")
graph_compar(PLIQ_IN         , 90,159,"Pension independants à la liquidation")
graph_compar(PLIQ_CN         , 90,159,"Pension CN à la liquidation")

plot(pliq_rg[which(liq==116),1],pliq_rg[which(liq==116),2])

save (ageref,file=(paste0(cheminsource,"Simulations/CN/ref.RData")))
