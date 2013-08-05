
read.act <- function (filename,
                        errorfile="fehler.txt",
debug=FALSE ) {
    getatindex <- function (x,c) {
      return (ifelse(length(x)<c,"",x[[c]]));
    }
    ## generic reading
    cat (paste ("reading", filename,"\n"))
    con <- file(filename, "r", blocking = FALSE,encoding="iso8859-1")
      lines <- readLines(con) # empty
    close(con)

    if (debug) cat (paste("reading done \n"))

    if (length(grep(".*<BR>COLUMN.*",lines[[1]])>0)) {
      ## get column names from line 2
      h <- strsplit(lines[[2]],"\t")[[1]]

      ## data  
      data <- strsplit(lines[3:length(lines)],"\t")
      data <- lapply(data, function (x) return (x[1:max(which(x!=""))]))
      if (debug) cat ("splitting done\n")

      linetype <- sapply(data,function (x) {return (x[[1]]);})
      group <- data.frame(from=which(sapply(data,function (x) {return (x[[1]]);})=="S"))
      if (length(group$from)>1) {
        group$to <- c(group$from[2:length(group$from)]-1,length(data))
      } else {
        group$to <- c(length(data))
      }
      group$names <- sapply(data[group$from],function (x) getatindex(x,5))


      set <- data.frame(from=which(sapply(data,function (x) {return (x[[1]]);})=="T"))
      if (length(set$from)>1) {
        set$to <- c(set$from[2:length(set$from)]-1,length(data))
      } else {
        set$to <- c(length(data))
      }
      set$names <- sapply(data[set$from],function (x) getatindex(x,5))

      if (debug) cat ("set/group parsing done\n")

      splits <- sapply(data,function (x) {return (length(x));})
      maxcol <- max(splits)

      data <- lapply(data,function (x) {
        if (length(x)<maxcol) {
          x <- c(x, rep("",maxcol-length(x)))
        }
        return (x);
      })

      s <- as.data.frame(t(sapply(data, function(x) x)),stringsAsFactors=FALSE)

      names(s) <- h[1:ncol(s)]
      s$set <- c(rep("",set[1,"from"]-1),with(set,rep(names,to-from+1)))
      s$group <- c(rep("",group[1,"from"]-1),with(group,rep(names,to-from+1)))
      result <- as.matrix(subset(s,Type=="E"))
      if (nrow(result)>0) return (result) else return ("file contains no data")
    } else {
errormsg <- paste("invalid: ",filename,"\n",lines[[1]])
      cat (errormsg)
      cat (errormsg, file=errorfile,append=TRUE)
      cat("\n")
      return (errormsg)
    }
  }

merge.act <- function (data, listname="file", debug=FALSE) { 

    if (debug)
        cat("appending missing columns to data frames -- slow, no output\n")

    ## this appends a column "file" to the matrix for later merging of set/group info
    for (file in names(data)) {
        fdata <- data[[file]]
        print (paste (file,class(fdata)))
        if (class(fdata)=="matrix") {
            if (nrow(fdata)>0) data[[file]] <- cbind(fdata,file) else {
                cat(paste("removing empty data file",file, fdata,"\n"))
                data[[file]] <- NULL
            }
        } else {
            cat(paste("removing invalid data file",file, fdata,"\n"))
            data[[file]] <- NULL
        }
    }
    cat("rbinding data frames\n")  

    return (do.call(rbind.fill.matrix,data))
}

write.act <- function (d, system, filename,
                         warningfile="warnings.txt",
                         errorfile="errors.txt"
                         ) {
#    d$group <- as.factor(d$group)
#    d$set <- as.factor(d$set)
  filename=file(filename, "w",encoding="iso8859-1")
    system.cols <- c(
                     "Type",
                     "Entry",
                     "Exit",
                     "Memo")
                                          #
                                          # cat header
    colstart <- 10
    columns <- setdiff(names(d),c(system.cols,"set",
                                  "group"))

    cat(paste("SYSTEM: ",system,"<BR>",sep=""),
        paste("<BR>COLUMN:",columns,sep=""),
        "<BR>DEFINE: FPS, 25<BR>\n",
        sep="",file=filename)
    cat(c(system.cols,columns),sep="\t",file=filename,append=TRUE)
  #  cat("\n",file=filename,append=TRUE)


    d <- d[order(d$group,d$set,d$Entry),]

    for (g in unique (d$group)) {
      cat (paste("writing group",g,"\n"))
                                          # create group
      cat ("\nS\t00:00:00:00\t00:00:00:00\t\t",g, "\n",sep="",file=filename,append=TRUE)
                                          #
      sub <- subset(d,group==g)
      for (s in unique(sub$set)) {
                                          #      create set
        ss <- subset(sub,set==s)
        ss <- ss[,c(system.cols,setdiff(names(ss),c(system.cols,"set","group")))]
                                          #     print(head(ss))  

        cat ("\nT\t00:00:00:00\t00:00:00:00\t\t",
             s, "\n",
             sep="",file=filename,append=TRUE)
        cat (paste("   writing ",g,s,"\n"))
                                          #      print entries

        cat(
            paste(
                  apply(ss,1,
                        function(x) {x[is.na(x)] <- ""; return (paste(gsub("\\\"|[^a-zA-ZäöüßÖÄÜ ,.-\\/\\(\\)\\:0-9]","",x),collapse="\t"))}),

                  collapse="\n"),
            file=filename,append=TRUE)
      }
    }
  }

  write.multifile.act <- function (d, system, filename,
                                   warningfile="warnings.txt",
                                   errorfile="errors.txt",
                                   files=10
                         ) {
    groups <- sort(unique(d$group))
    ng <- length(groups)
    file <- sort(1:ng%%files)
    for (g in 1:files) {
      g <- groups[file==(g-1)]
      ming <- g[[1]]
      maxg <- g[[length(g)]]
      write.act (subset(d, group %in% g),
                 system,
                 paste(paste(filename,ming,maxg,sep="-"),".act",sep=""),
                 warningfile=warningfile,
                 errorfile=errorfile);

    }
  }

  write.multifile.set.act <- function (d, system, filename,
                                   warningfile="warnings.txt",
                                   errorfile="errors.txt",
                                   files=10
                         ) {
    sets <- sort(unique(d$set))
    ng <- length(sets)
    file <- sort(1:ng%%files)
    for (g in 1:files) {
      g <- sets[file==(g-1)]
      ming <- g[[1]]
      maxg <- g[[length(g)]]
      write.act (subset(d, set %in% g),
                 system,
                 paste(paste(filename,ming,maxg,sep="-"),".act",sep=""),
                 warningfile=warningfile,
                 errorfile=errorfile);

    }
  }

exclude.blacklisted <- function (f, filename, ## blacklist file
                                 enc="iso8859-1",
                                 part.regexp=".*/([0-9]*/.*)$") {
  cat (paste ("reading", filename,"\n"))
  con <- file(filename, "r",
              blocking = FALSE,
              encoding=enc)
  lines <- tolower(readLines(con))
  close(con)
  return  (f[!(tolower(gsub (part.regexp,
                     "\\1",
                     sapply(f,URLdecode)))
               %in% lines)])
}

## TODO rename (no tickets)
read.tickets.act <- function(f.full,
                             blacklist.file,
                             excluded.log,
                             error.log, 
                             exclude=function(f) exclude.blacklisted(f,filename=blacklist.file)) {
  f <- exclude(f.full)

  cat(paste(setdiff(f.full,f)," (blacklist)\n"),file=excluded.log)

  dlist <- sapply (f,read.act)
  names(dlist) <- sapply(names(dlist),URLdecode)

  ## Get all column names of all files, also in a list:
  colnames <- lapply (dlist, function (x) colnames(x))
  names (colnames) <- names (dlist)


  ## Determine the intersection of columns common to all spss files:
  ## start with column names of first file
  common <- colnames[[1]]

  for (n in names(colnames)) common <- intersect (common, colnames[[n]])

  return (list (merged=merge.act(dlist),
                ## column names that were in all files
                common=common,
                ## Determine column names that are in this file but not in all others
                unique=lapply (colnames, function (x) setdiff (x, common))))
}

append.tickets.2.sets <- function(d) {
  sets <- aggregate (d$ticket,
                     by=list(d$group,d$set),
                     function (x) paste("#",
                                        unique(x),
                                        sep="",
                                        collapse=" "))
  names(sets) <- c("group","set","tickets")
  d <- merge(d,sets)  

  d$set <- paste (d$set, d$tickets)
  d$tickets <- NULL
  return(d)
}
