
source("actlib.R")
  source("merge-act-config.R")
  system (paste("scp ",blacklist.file," .",sep=""))

  system (paste("cd ",basedir," && git pull",sep=""))


  print("get list of files")
  f              <- data.frame (realfile=list.files(path=basedir, pattern=".*\\.act",recursive=TRUE,full.names=TRUE),stringsAsFactors = FALSE)

  ## fix umlauts
  f$file         <- tolower(sapply(list.files(path=basedir, pattern=".*\\.act",recursive=TRUE),URLdecode))

  ## fix bilderbuch/mm 
  f$file         <- gsub("_v_bb_","_mm_v_",f$file)
  f$file         <- gsub("_m_bb_","_mm_m_",f$file)
  f$file         <- gsub("_tm_bb_","_mm_tm_",f$file)

  f$ticket       <- gsub(".*/([0-9]*)/.*","\\1",f$file)
  f$kind         <- gsub(".*/([0-9]*)/([^_]*).*","\\2",f$file)

  f$type         <- tolower(gsub(".*/([0-9]*)/([^_]*)_([^_]*).*","\\3",f$file))
  ## f <- subset(f,grepl("/ticket/",file))

  ## unique(f$kind)
  ## table(f$type)

  F <- list()  


  ## Joint_Attention
  ## DuDo_JA_T1_IsLa
  F$ja            <- subset(f, type=="ja")
  F$ja$dipls      <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_.]*).*","\\4",F$ja$file)
  F$ja$whatsthis  <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*).*","\\5",F$ja$file)
  ### !!!!!!!!!!!!!!  KLÄRUNGSBEDARF, whatsthis
##  subset(F$ja,!grepl("/",whatsthis))
  F$ja$group <- with(F$ja,paste(kind,"Joint Attention"))
  F$ja$set   <- with(F$ja,paste(kind,dipls,ticket))

  ## Frustrationstoleranz / Emotionsregulation
  ## DuDo_Fru_V_T1_IsLa
  F$frust            <- subset(f, type=="fru")
  F$frust$person     <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*).*","\\4",F$frust$file)
  F$frust$t          <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*).*","\\5",F$frust$file)
  F$frust$dipls      <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*)_([^_.]*).*","\\6",F$frust$file)
  F$frust$group <- with(F$frust,paste(kind,"Frustrationstoleranz/Emotionsregulation"))
  F$frust$set   <- with(F$frust,paste(kind,person,t,dipls,ticket))

  ## Peer interaction
  ## DuDo_PI_T1_PaBa
  F$peer            <- subset(f, type=="pi")
  F$peer$t          <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*).*","\\4",F$peer$file)
  F$peer$dipls      <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*).*","\\5",F$peer$file)
  F$peer$group <- with(F$peer,paste(kind,type))
  F$peer$set   <- with(F$peer,paste(kind,t,dipls,ticket))

  ## Tagesmutter-Kind-Interaktion
  ## AmBa_TM_T1_IsLa
  F$tm            <- subset(f, type=="tm")
  F$tm$t          <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*).*","\\4",F$tm$file)
  F$tm$dipls      <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*).*","\\5",F$tm$file)
  F$tm$group <- with(F$tm,paste(kind,"Tagesmutter-Kind-Interaktion"))
  F$tm$set   <- with(F$tm,paste(kind,t,dipls,ticket))


  ## MM
  ## DuDo_Fru_T1_IsLa
  F$mm            <- subset(f, type=="mm")
  F$mm$person     <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*).*","\\4",F$mm$file)
  F$mm$t          <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*).*","\\5",F$mm$file)
  F$mm$dipls      <- gsub(".*/([0-9]*)/([^_]*)_([^_]*)_([^_]*)_([^_.]*)_([^_.]*).*","\\6",F$mm$file)
  F$mm$group <- with(F$mm,paste(kind,"Mind Mindedness"))
  F$mm$set   <- with(F$mm,paste(kind,person,t,dipls,ticket))


  ### !!!!!!!!!!!!!!  KLÄRUNGSBEDARF

require(plyr) 
for (n in names(F)) {
  M <- read.tickets.act (F[[n]]$realfile,
                         blacklist.file,
                         excluded.log,
                         error.log)

  infos <- F[[n]][,c("realfile","group","set")]
  names(infos)[[1]] <- "file"
  infos$file <- sapply (infos$file,URLdecode)
  data <- M$merged[,!(colnames(M$merged) %in% c("group","set"))]
  data <- merge(data,infos,by="file",all.x=TRUE)
  data$file <- NULL
  write.act(data,n,paste(n,".act",sep=""))
}

system (paste("scp *.act ",pubdir,sep=""))
system (paste("scp meldung*.txt ",pubdir,sep=""))
