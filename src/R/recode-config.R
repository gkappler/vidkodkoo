
forceOverwrite <- FALSE
  cleanUp  <- FALSE  ## NOTE: cleanup is broken after change to archiving process, kept for reference
  compress <- TRUE

  regexp.restrict <- ".*"  
  regexp.prio <- ".*tagesmutter.videos.*(jowö|lebl|tiva|bjlö|alwi|emke|luüb|mave|roro|sopr|lucl|lebl|bilö|alwi|luüb|emke|jowö|tiva|mave|sopr|lucl).*"
#  regexp.Teil <- "_Teil ?[1-9]"
  regexp.teil <- "_Teil[1-9]"
  regexp.videos <- "(MPG|mpg|MOD|mod|mts|MTS)$"

  dir.input <- "/data/Videos/unkomprimiert"
  dir.output <- "/data/Videos/komprimiert"
  ext.output <- "xvid.avi"

  dir.tmp <- "/data/Videos/tmp/"
  command.file <- "~/recode_videos.sh"  


  dir.archive <- "/data/Videos/Archiv/"
