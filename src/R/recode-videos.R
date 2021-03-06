require(utils)
  source("recode-config.R")
  ## get all video files in the directory 
  all <- list.files (dir.input,
                     pattern=regexp.videos,
                     full.names = TRUE,
                     recursive=TRUE)
##cat ("These Files were found: ")
##cat (paste(all,collapse="\n"))
all2 <- gsub ("[^A-Za-z0-9.-_ ]","_",all)
cat ("\n\nFILENAME ERROR: THESE FILES CANNOT BE PROCESSED: ")
cat (paste(all[all!=all2],collapse="\n"))
all <- all[all==all2]
cat ("\n\nThese Files WILL be processed: ")
cat (paste(all,collapse="\n"))
  
  teil <- subset(all,grepl(regexp.restrict,tolower(all)))
  teil <- c(subset(teil,grepl(regexp.prio,tolower(teil))), subset(teil,!grepl(regexp.prio,tolower(teil))))
  
  ## determine file that holds all merged parts (if there are several files per video)
  merged <- gsub("[^.]*$","", ## without extension
                 gsub(regexp.teil,"",teil))  ## without part information
  
  ## determine tmp file name
  tmp <- gsub("\\/.*\\/",dir.tmp,merged)
  tmp <- paste(tmp,ext.output,sep="")
  
  
  ## set target path for compressed videos
  ziel <- gsub(dir.input,dir.output,merged)
  ## set extension
  ziel <- paste(ziel,ext.output,sep="")
  zieldir <- gsub("/[^/]*$","",ziel)
  
  
  arch <- gsub(dir.input,dir.archive,teil)
  ## determine archive file name and path
  
  ############################################
  ## Start shell script output
  ############################################
  cat.command.file <- function (s) {
      cat (s,
           file=command.file,
           append=TRUE)
  }
  cat ("#!/bin/bash\n",
       file=command.file)
  cat ("#!/bin/bash\n",
       file="cleanup.sh")
  
                                          # delete files with size 0 (these result most often when disk is full)
  cat.command.file("find /data/Videos/ -size 0 -exec rm {} \\;\n")
  cat.command.file("# create directories \n\n")
  
  cat.command.file("# create all target directories\n")
  for (zdir in unique(zieldir)) {
      cat.command.file(paste ("if [[ ! -f \"",zdir,"\" ]]; then\n",sep=""))
      cat.command.file(paste ("    mkdirhier \"",zdir,"\"\n",sep=""))
      cat.command.file(paste ("fi\n",sep=""))
  }
  cat.command.file("# create all archive directories\n")
  for (zdir in unique(gsub("/[^/]*$","",arch))) {
      cat.command.file(paste ("if [[ ! -f \"",zdir,"\" ]]; then\n",sep=""))
      cat.command.file(paste ("    mkdirhier \"",zdir,"\"\n",sep=""))
      cat.command.file(paste ("fi\n",sep=""))
  }
  
  cat.command.file("# preparation of files:  each file is 1st merged (if there are several parts) and 2nd compressed.\n\n")
  
  
  compcommand <- list(dv=paste0 ("-vtag xvid -vcodec libxvid -b 10000k ",    # xvid video codec
                          "-mbd rd -flags +mv4+aic -trellis 2 -cmp 2 -subcmp 2 -g 300 "),
                      avi=paste0 ("-vtag xvid -vcodec mpeg4 -b 10000k "),    # xvid video codec
                      wmv=paste0 ("-vtag xvid -vcodec mpeg4 -b 2000k "),        # xvid video codec
                      mts=paste0 ("-deinterlace -vtag xvid -vcodec libxvid -b 5000k -s 1920x1080 -aspect 16:9 ",    # xvid video codec 
                          "-mbd rd -flags +mv4+aic -trellis 2 -cmp 2 -subcmp 2 -g 300 "))
  
  ##          compcommand[["mts"]] <- compcommand[["dv"]];
  
  for (n in unique(merged)) {
      mergeddv <- NULL
      filesansext <- gsub ("^.*/","",n)
      z <- ziel[merged==n][[1]] 
      t <- teil[merged==n]
      a <- arch[merged==n]
      ext <- gsub ("^.*\\.","",t[[1]])
      tmpf <- tmp[merged==n][[1]]
      
  
  
      ##    t <- gsub("(MOD|mod|mpg|MPG|mts|MTS)","avi",t)
      
      ## Debugging
      ##    print (t)
      ##    print (n)
      ##    print (z)
      
      if (forceOverwrite) cat.command.file(paste ("rm \"",z,"\"\n",sep="")) ## delete output, necessary with archiving system
      
      if (compress)
          tryCatch ({
              compcommon <- paste("-r 25 ",                                       # 25 frames per second
                                  "-acodec libmp3lame -ac 2 -ar 48000 -ab 128k ", # mp3 audio compression
                                  "-threads 3 ",  # multi-cpu compression
                                  "-y ",                                          # force overwrite
                                  "\"", tmpf,"\" ",                               # output
                                  "> \"log/",filesansext,".out\" ",                     # logging
                                  "2> \"log/",filesansext,".err\"\n", sep="")
  
              cat.command.file(paste ("if [[ ! -f \"",z,"\" ]]; then\n",sep=""))
              if (length(t)>1) { # there are several parts
                  mergeddv <- gsub ("\\.[^.]*$",".dv",tmpf)
                  cat.command.file(paste ("rm -f \"",mergeddv,"\"\n",sep=""))
                  
                  cat.command.file(paste ("  echo \"merging ",paste(t,sep="",collapse=" "), "into",mergeddv,"\"\n"))
                  for (teilf in t) {
                      cat.command.file(paste ("ffmpeg -i \"",teilf,"\"",
                                              "  -target pal-dv -r 25 - ",
                                              " >> \"",mergeddv,"\"  2>/dev/null \n",sep=""))
                  }
                  ## cat.command.file(paste ("  mv \"", tmpf,"\" \"",n,"\"\n", sep=""))cat.command.file("  -target pal-dv -r 25 - ")
                  ## cat.command.file(paste ("inf=\"",mergeddv,"\";\n",sep=""))
                  infile <- mergeddv
              } else {
                  infile <- t[[1]]
              }
              
              
              
              if (!(tolower(ext) %in% names(compcommand))) {
                  compcommand[[tolower(ext)]] <- paste0("-vtag xvid -vcodec libxvid -b 3000k ", #
                                                        "-r 25 ", #
                                                        "-mbd rd -flags +mv4+aic -trellis 2 -cmp 2 -subcmp 2 -g 300 ")
              }
              
              
              print (paste0("ext '",ext,"' in ",compcommand))
              cat.command.file(paste ("  echo \"recoding $inf into ",z,"...\"\n"))
              cat.command.file(paste0("  ffmpeg ",
                          "-i \"",infile,"\" ",                       # input filename
                          compcommand[[tolower(ext)]],compcommon))
              cat.command.file(paste ("  echo \"   ...recoded $inf into ",z,". \"\n"))
              
              cat.command.file(paste ("if [[ -f \"",tmpf,"\" ]]; then\n",sep=""))
              ## move the tmp file to the target folder
              cat.command.file(paste ("  mv \"", tmpf,"\" \"",z,"\"\n", sep=""))
              
              if (length(t)>1) { # there are several parts
                  ## delete dv file
                  cat.command.file(paste ("  rm \"", mergeddv,"\" \n", sep=""))
              }
              
              cat.command.file(paste ("  mv \"", t,"\" \"",a,"\" \n", sep="",collapse="\n"))
              
              cat.command.file("fi\n\n")
              
              
              cat.command.file("fi\n\n")
          }, error=function (e) {
              cat (paste0("failed to process ",z," because ",e))
          })
      
      if (cleanUp) { ## NOTE: this is broken after change to archiving process, kept for reference
          cat.command.file(paste ("if [[ -f \"",z,"\" ]]; then\n",sep=""))
          
          ## check whether original file can be deleted
          ## this is the case if the target file now exists and has the desired duration:
          cat.command.file(paste ("durz=`ffmpeg -i \"",z,"\" 2>&1 | grep Duration | sed 's/\\..*$//g' | sed 's/.*: //g'`;\n",sep=""))
          if (length(t)==1)   # there are several parts
              cat.command.file(paste ("duro=`ffmpeg -i \"",n,"\" 2>&1 | grep Duration | sed 's/\\..*$//g' | sed 's/.*: //g'`;\n",sep=""))
          else
              cat.command.file(paste ("duro=`ffmpeg -i \"",mergeddv,"\" 2>&1 | grep Duration | sed 's/\\..*$//g' | sed 's/.*: //g'`;\n",sep=""))
          
          cat.command.file(paste ("if [[ \"$durz\" == \"$duro\" ]]; then\n",sep=""))
          cat.command.file(paste ("  echo \"# '",n,"' can be deleted because its duration $duro is the same as in '",z,"' ($durz) \" >> cleanup.sh \n",sep=""))
          cat.command.file(paste ("  echo \"# rm -f \\\"",n,"\\\"\" >> cleanup.sh \n",sep=""))
          ## delete files compressed in old format from target dir
          cat.command.file(paste ("  echo \"rm -f \\\"",gsub("xvid","msmpeg2",z),"\\\"\" >> cleanup.sh \n",sep=""))
          cat.command.file(paste ("else\n",sep=""))
          cat.command.file(paste ("  echo \"# '",n,"' can NOT be deleted because its duration $duro differs from $durz for '",z,"'\"  >> cleanup.sh \n",sep=""))
          cat.command.file(paste ("fi\n",sep=""))
          cat.command.file("fi\n\n")
      }
  }
  cat.command.file("find /data/Videos/ -size 0 -exec rm {} \\;\n")
  
  system (paste ("chmod +x ",command.file))
  if (run.compression) system (command.file)
