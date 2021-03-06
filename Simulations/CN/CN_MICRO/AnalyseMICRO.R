############################### TRANSITIONS VERS UN SYSTEME DE COMPTES NOTIONNELS ###################
# Valorisation des cotisations passees. 
# A partir de la date AnneeDebCN, tous les droits sont calcules dans le nouveau systeme. 
# Hypothese de depart en retraite: meme age que dans le scenario de reference

# Taux de cotisation 23 % + ANC


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

# Declaration des variable d'outputs

# Variable micro
ageliq_     <- matrix(nrow=taille_max,ncol=4)
pliq_       <-matrix(nrow=taille_max,ncol=4)
pliq_rg     <- matrix(nrow=taille_max,ncol=4)
pliq_fp     <- matrix(nrow=taille_max,ncol=4)
pliq_ar     <- matrix(nrow=taille_max,ncol=4)
pliq_ag     <- matrix(nrow=taille_max,ncol=4)
pliq_in     <- matrix(nrow=taille_max,ncol=4)
points_cn   <- matrix(nrow=taille_max,ncol=4)
pliq_cn     <- matrix(nrow=taille_max,ncol=4)
pension_nc  <- matrix(nrow=taille_max,ncol=4)
dar_        <- matrix(nrow=taille_max,ncol=4)

conv        <-numeric(taille_max)
dureecho    <-numeric(taille_max)
dureefp     <-numeric(taille_max)
dureerg     <-numeric(taille_max)
dureetot    <-numeric(taille_max)
dureetotmaj <-numeric(taille_max)
mc          <-numeric(taille_max) 
mg          <-numeric(taille_max)


ageref      <- numeric(taille_max)
actifs      <- numeric(taille_max)        # Filtre population active
retraites   <- numeric(taille_max)        # Filtre population retraitée
liquidants  <- numeric(taille_max)
gain        <- numeric(taille_max)
actifs      <- numeric(taille_max)        # Filtre population active
retraites   <- numeric(taille_max)        # Filtre population retraitée
liquidants  <- numeric(taille_max)
liquidants_fp <- numeric(taille_max)
liquidants_rg <- numeric(taille_max)
liquidants_in <- numeric(taille_max)
liquidants_po <- numeric(taille_max)


# Variables macro
MSAL        <- matrix(nrow=4,ncol=200)    # Masse salariale par année
MPENS       <- matrix(nrow=4,ncol=200)    # Masse des pensions année
PIBREF      <- matrix(nrow=4,ncol=200)    # PIB annuel 
RATIOPENS   <- matrix(nrow=4,ncol=200)    # Ratio pension/PIB par année
RATIOFIN    <- matrix(nrow=4,ncol=200)    # Ratio masse des pensions/masse des salaires par année
RATIODEM    <- matrix(nrow=4,ncol=200)    # Ratio +60ans/-60ans par année
SALMOY      <- matrix(nrow=4,ncol=200)    # Salaire moyen par année
PENMOY      <- matrix(nrow=4,ncol=200)    # Pension moyenne par année
PENREL      <- matrix(nrow=4,ncol=200)    # Ratio pension salaire
AGELIQ      <- matrix(nrow=4,ncol=160)    # Age de liquidation moyen par année
CONV_MOY    <- matrix(nrow=4,ncol=200)    # Coeff Conv moyen des liquidants par année
FLUXLIQ     <- matrix(nrow=4,ncol=200)    # Effectifs de liquidants

W           <- 2047.501
cibletaux<-numeric(taille_max)




#### Début de la simulation ####

#  Rprof(tmp<-tempfile())
for (sc in c(1,2))
  
{
  
  # Reinitialisation variables
  source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/DefVarRetr_Destinie.R")) )
  load  ( (paste0(cheminsource,"Modele/Outils/OutilsBio/BiosDestinie2.RData"        )) )  
  setwd ( (paste0(cheminsource,"Simulations/CN/CN_MICRO"                                    )) )
  
  plafond<-8 
  
  for (t in 60:160)   # Début boucle temporelle
  {
    print (c(sc,t))
    if (sc>1)
    {
      AnneeDepartCN <- 115
      TauxCotCN[t]                 <- 0.23 #MPENS[1,115]/MSAL[1,115]
      if (t <110) {RendementCN[t]  <- PIB[t]/PIB[t-1]-1} 
      else        {RendementCN[t]  <- log((MSAL[sc,t-1]*Prix[t-1])/(MSAL[sc,t-6]*Prix[t-6]))/5}
      RendementCNPrev[t]           <- RendementCN[t]
      RevaloCN[t+1]                <- Prix[t]/Prix[t-1]
      UseConv(55,70,t)
      #  print (CoeffConv[60:80]) 
    }
    
    if (sc>1 && t==AnneeDepartCN)
    {
      for (i in 1:55000)
      {
        if (ageliq[i]==0)
        {
          statut[i,statut[i,1:160]>1]<- statut[i,statut[i,1:160]>1]+100          
        }
      }
    }
    
    
    
    # Liquidations  
    for (i in 1:55000)       # Début boucle individuelle
    {
      
      # Liquidation
      
      if ((t-t_naiss[i]>=55) && (ageliq[i]==0))
      {
        if (sc>1)
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
          # CN
          
          points_cn[i,sc]    <- points_cn_pri+points_cn_fp+points_cn_ind+points_cn_nc+points_mccn
          pension_nc [i,sc]  <- pension_cn_nc[i]
          
          pliq_cn[i,sc]   <- pension_cn_pri[i]+pension_cn_fp[i]+pension_cn_ind[i]+pension_cn_nc[i]
          pliq_[i,sc]     <- pension[i]
          pliq_rg[i,sc]   <- pension_rg[i]
          pliq_fp[i,sc]   <- pension_fp[i]
          pliq_ar[i,sc]   <- pension_ar[i]
          pliq_ar[i,sc]   <- pension_ag[i]
          pliq_in[i,sc]   <- pension_in[i]
          dar_[i,sc]      <- dar[i]
  
          if (points_cn[i,sc]>0) {conv[i] <- pliq_cn[i,sc]/points_cn[i,sc]}
          if (sc==1) 
          {
            ageref[i]       <- t-t_naiss[i]
            dureecho[i]     <- duree_cho
            dureefp[i]      <- duree_fp
            dureerg[i]      <- duree_rg
            dureetot[i]     <- duree_tot
            dureetotmaj[i]  <- duree_tot_maj
            mc[i]           <- indic_mc[i]
            mg[i]           <- indic_mg[i]
          }
        }
      } 
      
      else if (ageliq[i]>0)
      { 
        Revalo(i,t,t+1)    
      }
      
    } # Fin de la boucle individuelle 
    
    
    if (sc ==1)
    {
      liquidants     <- which(t_liq>=115 & t_liq <= 150)
      liquidants_rg  <- which(t_liq>=115 & t_liq <= 150 & pension_rg>0 & pension_fp==0 & pension_in==0)
      liquidants_fp  <- which(t_liq>=115 & t_liq <= 150 & pension_fp>.75*pension)
      liquidants_in  <- which(t_liq>=115 & t_liq <= 150 & pension_in>.75*pension)
      liquidants_po  <- setdiff(liquidants,union(liquidants_rg,union(liquidants_fp,liquidants_in)))
    }
    
    actifs     <- (salaire[,t]>0) & (statut[,t]>0)
    retraites  <- (pension>0) & (statut[,t]>0)
    liquidants <- (pension>0) & (t_liq==t)
    if (sc >0)
    {
      SALMOY[sc,t]       <- mean (salaire[actifs,t]/Prix[t])  
      MPENS[sc,t]        <- W*sum(pension[retraites])/Prix[t]     
      MSAL[sc,t]         <- W*sum(salaire[actifs,t])/Prix[t] 
      PIBREF[sc,t]       <- MSAL[sc,t]*(PIB[109]/Prix[109])/MSAL[sc,109]
      RATIOPENS[sc,t]    <- MPENS[sc,t]/PIBREF[sc,t]
      RATIOFIN[sc,t]     <- MPENS[sc,t]/MSAL[sc,t]
      RATIODEM[sc,t]     <- sum  ((t-t_naiss>=60) & (statut[,t]>0))/sum((t-t_naiss<60) &(statut[,t]>0))
      PENMOY[sc,t]       <- mean (pension[retraites]/Prix[t])
      CONV_MOY[sc,t]     <- mean (conv[     which( (pension>0)&t_liq==t)])      
      PENREL[sc,t]       <- PENMOY[sc,t]/SALMOY[sc,t]
      FLUXLIQ[sc,t]      <- W*sum(t_liq==t)
      AGELIQ[sc,t]       <- mean ( ageliq[which(t_liq==t)])
    }  
  } # Fin de de la boucle temporelle
  
  
  
} # Fin boucle scenarios



#### Sorties ####

save.image(paste0(cheminsource,"Simulations/CN/CN_MICRO/micro.RData"))
