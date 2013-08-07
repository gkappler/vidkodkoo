  forceOverwrite <- TRUE
  compress <- TRUE
  run.compression <- TRUE
  
  regexp.restrict <- ".*"  
  regexp.prio <- ".*tagesmutter.videos.*(jowö|lebl|tiva|bjlö|alwi|emke|luüb|mave|roro|sopr|lucl|lebl|bilö|alwi|luüb|emke|jowö|tiva|mave|sopr|lucl).*"
  ##  regexp.teil <- "_Teil ?[1-9]"
  regexp.teil <- "_Teil[1-9]"
  regexp.videos <- "(MPG|mpg|MOD|mod|mts|MTS|AVI|avi|WMV|wmv)$"
  
  dir.input <- "/dataNAS/Videos_INBOX"
  dir.output <- "/dataNAS/Videos_KOMPRIMIERT"
  ext.output <- "xvid.avi"
  
  dir.tmp <- "/data/Videos/tmp/"
  command.file <- "~/recode_videos.sh"  
  
  
  dir.archive <- "/dataNAS/Videos_ARCHIV/"
  
  
  cleanUp  <- FALSE  ## NOTE: cleanup is broken after change to
                     ## archiving process, kept for reference
