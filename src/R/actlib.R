
merge.act <- function (data, listname="file", debug=FALSE) { if
  (debug)
  print("appending missing columns to data frames -- slow, no output")

  ## this appends a column "file" to the matrix for later merging of set/group info
  for (file in names(data)) {
     data[[file]] <- cbind(data[[file]],file)
  }
  print("rbinding data frames")  

  return (do.call(rbind.fill.matrix,data))
}
