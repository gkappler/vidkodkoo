
create.tickets <- function (K,D,
                            batch.offset,
                            types=c("Bilderbuch.M",
                              "Joint_Attention",
                              "Frustration.M", "Bilderbuch.V",
                              "Frustration.V",
                              "Bilderbuch.TM", "TM_Video"),
                            relPerBatch=1,kinderPerBatch=15) {
names(K) <- tolower(names(K))
names(D) <- tolower(names(D))
######################################################################
## Initialisiere Diplomandinnen
  D$fullname <- paste(D$vorname, D$nachname)
  D$matrikel
  D$video<-gsub (" /.*","",D$kodiersystem)
  D$kodiersystem<-gsub (".* / ","",D$kodiersystem)
  D$kodiersystem<-as.factor(D$kodiersystem)
  D$name<-as.factor(D$name)
  D$max.batch[is.na(D$max.batch)] <- 10000

  D$time<-rep(0,nrow(D))  #  kumulierte Bearbeitungszeit
  D$rand<-rnorm(nrow(D))  #  Zufallszahl für randomisierte Zuordnung

##  print(D)  
  kodierung <- dlply (D, .(video), function (x) return (unique(x$kodiersystem)))# lapply (unique(D$video), function (x) return (unique(subset(D,video==x)$kodiersystem)))
##  print(kodierung)

######################################################################
  ## Initialisiere Kinderdaten
  K$batch <- (0:(nrow(K)-1) %/% kinderPerBatch)+batch.offset
  K$rand<-rnorm(nrow(K))  #  Zufallszahl für randomisierte Zuordnung

  tickets <- data.frame()
  for (vn in types) { 
    d <- createTickets(K,vn,D,kodierung,
                       relPerBatch=relPerBatch,
                       kinderPerBatch=kinderPerBatch)
    D <- d$studenten
    tickets <- rbind(d$tickets,tickets)
  }
  tickets$max.batch <- sapply (tickets$owner, function (x) D$max.batch[which (D$name==x)])
  tickets <- subset(tickets,batch<=max.batch)
  return (tickets)
}

distributeTasks <- function(T, validStudenten, D=D, cost=1) {
  d<-D$name %in% validStudenten
  for (ti in 1:nrow(T)) {   #getestet: geht recht schnell 1000 mal
    D$rand<-rnorm(nrow(D))

    if (is.na(T[ti,"owner"])) {
      nextD <- order(!d, D$max.batch<T$batch[[ti]], D$time,D$rand)[[1]]
      D[nextD,"time"] <- D[nextD,"time"]+cost
      T[ti,"owner"] <- levels(D$name)[[D[nextD,"name"]]]

    }
  }
  return (list(tickets=T, studenten=D))
}

createTickets <- function (K, videoname, D,kodierung,
                             relPerBatch=1,kinderPerBatch=15) {
    if (is.null (K[[videoname]])) {
      print (paste ("FEHLER: Video mit Namen '",videoname,"' existiert nicht in Videotabelle.", sep=""))
    } else {
      videotype <- gsub ("\\..*","",videoname)
      videocontext <- gsub (".*\\.","",videoname)
                                          #    k <- kodierung[[videotype]][[1]]
      tickets <- data.frame()
      if (!is.null (kodierung[[videotype]])) 
        for (k in kodierung[[videotype]]) {
          studenten <- subset(D, video==videotype & kodiersystem == k)
  
          if (nrow(studenten)==0) break;
  
##          print(K)      
                                          # T contains Tickets for Tasks 
          T <- subset(data.frame(id=1:nrow(K),
                                 kind=K$kind,
                                 gruppe=K$gruppe,
                                 phase=K[[videoname]],
                                 batch=K$batch,
                                 milestone=paste("Batch",sprintf("%02d",K$batch)),
                                 videotype=rep(videotype,nrow(K)),
                                 videocontext=rep(videocontext,nrow(K)),
                                 component=rep(k,nrow(K)),
                                 rand=K$rand),
                      !is.na(phase))
                                          # select and distribute reliability tasks (batchwise from available videos)
          T$rel<-rep(FALSE,nrow(T))
          for (b in unique(T$batch)) {
            T$rel[order((T$batch!=b),
                        T$rand)
                  [1:relPerBatch]]<-TRUE   
          }
  
          Trel <- as.data.frame(expand.grid (T$id[T$rel], studenten$name))
          names(Trel) <- c("id", "owner")
          Ts <- merge (T,Trel, all.x=TRUE, all.y=TRUE)
  
          d <- distributeTasks(Ts,studenten$name,D)
          D <- d$studenten
          tickets <- rbind(d$tickets,tickets)
        }
      return (list(tickets=tickets, studenten=D))
    }
  }

sql.tickets <- function (tickets,no.offset, filename) {
    tickets$nummer <- no.offset+1:nrow(tickets)

    quotestring <- function (x) {
      return (ifelse (is.na(x),"''",paste ("'",x,"'",sep="")))
    }

    tickets$videocontext[as.character(tickets$videocontext)==as.character(tickets$videotype)] <- NA

    tickets$summary <- with(tickets,
                            paste ("Kodierung ", 
                                   gruppe,
                                   " Kind ",
                                   kind, ", ",
                                   videotype, " ",
                                   ifelse (is.na(videocontext),"",levels(videocontext)[videocontext]),
                                   " (",phase,")",
                                   " mit dem System ", component,
                                   sep=""))



    tickets$description <- with(tickets,
                            paste ("Bitte kodieren Sie für ",
                                   gruppe,
                                   " Kind !",
                                   kind,
                                   " das Video ",
                                   videotype, " ",
                                   ifelse (is.na(videocontext),"",levels(videocontext)[videocontext]),
                                   " (",phase,")",
                                   " mit dem System ", component,
                                   " anhand der Beschreibung in ",
                                   "[\"Kodieranleitung ",
                                   component, "\"].

      Informationen zum Kind finden/speichern Sie bitte hier:  [\"Kind ",kind,"\"]",
                                   sep=""))

    tickets$keywords <- with(tickets,
                             paste(kind,ifelse(rel,"reliabilität",""),gruppe))


    tickets$sql <- paste(
                         "INSERT INTO \"ticket\" VALUES(",
                         with(tickets,
                              paste (                          # SQL column
                                     nummer,                   # id
                                     "'INTERACT Kodierung'",   # type,
                                     0,                        # time integer,
                                     0,                        # changetime integer,
                                     quotestring(component),   # component text,
                                     "NULL",                   # severity text,
                                     "'normal'",               # priority text,
                                     quotestring(owner),       # owner text,
                                     "'automat'",              # reporter text,
                                     "''",                       # cc text,
                                     "NULL",                   # version text,
                                     quotestring(milestone),   # milestone text,
                                     "'new'",                  # status text,
                                     "NULL",                   # resolution text,
                                     quotestring(summary),     # summary text,
                                     quotestring(description), # description text,
                                     quotestring(keywords),    # keywords text
                                     sep=", ")),
                         ");\n",
                         sep="")
    cat(tickets$sql,file=filename)
return (tickets)
}
