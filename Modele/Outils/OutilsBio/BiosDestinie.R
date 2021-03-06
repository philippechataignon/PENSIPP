###############  BIOS DESTINIE  ******************

# Extraction des biographie individuelle (liens familiaux, statuts, salaire) de la base de Destinie 2009. 
# Programmes conjoint et statut dans P:\Retraites\Destinie\VersR

cheminsource <- "/Users/simonrabate/Desktop/PENSIPP 0.1/"
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsMS.R"           )) )
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/OutilsPensIPP.R"      )) )
source( (paste0(cheminsource,"Modele/Outils/OutilsRetraite/DefVarRetr_Destinie.R")) )

setwd (  (paste0(cheminsource,"Modele/Parametres/Destinie/Importation des bios"  )) )

# Lecture données d'état initial (NB : le tableau intermédiaire buf est lu sous forme de dataframe 
# et immédiatement converti en type matrix, ce qui est nécessaire pour l'extraction de la 
# sous-matrice des identifiants des enfants)
buf                          <- read.csv2("pop2.csv",header=FALSE)
buf                          <- as.matrix(buf)
n                            <- nrow(buf)
print (c(n," individus lus dans Pop.csv"))
t_naiss[1:n]                 <- buf[,3]
sexe[1:n]                    <- buf[,4]
findet[1:n]                  <- buf[,5] 
pere[1:n]                    <- buf[,6]
mere[1:n]                    <- buf[,7]
n_enf[1:n]                   <- buf[,8]
enf[1:n,1:nb_enf_max]        <- buf[1:n,9:(8+nb_enf_max)]
age[which(statut[,t_deb]>0)] <- t_deb-t_naiss[which(statut[,t_deb]>0)]+1
trim_naiss                   <- runif(1:taille_max)
trim_act                     <- runif(1:taille_max)-0.5
moisnaiss                    <- round (trim_naiss*11)

#Taux de prime: 
buf                          <- read.csv2("tauxprime.csv",header=FALSE)
buf                          <- as.matrix(buf)
buf[which(buf[,]=="")]<-NA
buf                          <- buf[apply(buf, 1, function(y) !all(is.na(y))),]
n                           <- nrow(buf)
print (c(n," individus lus dans tauxprime.csv"))
tauxprime[1:n]               <- as.numeric(buf[1:n,2])


# Lecture carrières et biographies matrimoniales
buf                          <- read.csv2("biosta2.csv",header=FALSE)
buf                          <- as.matrix(buf)
n                            <- nrow(buf)
print (c(n," individus lus dans BioSta.csv"))
statut[1:n,1:160]        <- buf[1:n,2:161]
# Deux types de MV (ie 0 dans BioEmp): 
# - en début de vie pour certains individus (=1 pour PENSIPP): BIZARRE
# - à la mort pour tous les individus (=-3 pour PENSIPP)
# Decede à la mort (pas -1 avant)
for (t in 1:160)
{
  list1 <- which(is.na(statut[,t]))
  list2 <- which(statut[,(t-1)]!=-1)
  list <- intersect(list1,list2)
  statut[list,t]<- -3
}  
# Statut a 0 pour les migrants
statut[is.na(statut)]<- 0

buf                          <- read.csv2("biosal2.csv",header=FALSE)
buf                          <- as.matrix(buf)
buf                          <- buf[apply(buf, 1, function(y) !all(is.na(y))),]
n                            <- nrow(buf)

print (c(n," individus lus dans BioSal.csv"))
salaire[1:n,1:160]        <- buf[1:n,2:161]
# =0 quands plus de statut
salaire[is.na(salaire)]<- 0


buf                        <- read.csv2("biomat2.csv",header=FALSE)
buf                        <- as.matrix(buf)
n                          <- nrow(buf)
print (c(n," individus lus dans BioMat4.csv"))
conjoint[1:n,1:160]      <- buf[1:n,2:161]



### Periodes de chomage indemnise
salrefchom <- matrix (0     ,nrow=taille_max,ncol=t_fin     )
chomind    <- matrix (0     ,nrow=taille_max,ncol=t_fin     )


for (t in 1:160)
{  
  for (i in 1:taille_max)
  {  
    if ( (statut[i,t]== chomeur) && ((statut[i,(t-1)]==cadre) ||((statut[i,(t-2)]==cadre)&&(chomind[i,(t-1)]==1) ) ) )          
    { 
      chomind[i,t] <- 1
      #  #On prend comme assiete le dernier salaire percu avant chomage
      liste <- which(statut[i,1:(t-1)]==cadre)
      salrefchom[i,t]  <- salaire[i,liste[length(liste)]]
    }
    
    if ((statut[i,t]== chomeur) && ((statut[i,(t-1)]==non_cadre) ||((statut[i,(t-2)]==non_cadre) && (chomind[i,(t-1)]==1) ) ) )          
    { 
      chomind[i,t] <- 1
      #  #On prend comme assiete le dernier salaire percu avant chomage
      liste <- which(statut[i,1:(t-1)]==cadre)
      salrefchom[i,t]  <- max(0,salaire[i,liste[length(liste)]])
    }
  }  
}

# Variables sauvegard?es

save (taille_max,t_naiss,sexe,findet,pere,mere,conjoint,enf,n_enf,statut,salaire,age,trim_naiss,trim_act,tauxprime,k,chomind,salrefchom,file=(paste0(cheminsource,"Modele/Outils/OutilsBio/BiosDestinie2.RData")))
