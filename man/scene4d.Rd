\name{scene4d}
\alias{scene4d}
\title{Wrapper to write a 4D scene}
\usage{
scene4d(files, fnames = NULL, outfile = "index_4D_stl.html",
  levels = NULL, alpha = NULL, color = "white", useTemp = FALSE,
  MNITemp = c("1mm", "2mm"), objtype = "stl", ...)
}
\arguments{
  \item{files}{(character) vector of filenames (first being
  a brain file if useTemp=FALSE)}

  \item{fnames}{(character) filenames for the 3D surfaces
  in the scene - needs to be the same length as files}

  \item{outfile}{(character) html filename}

  \item{levels}{(numeric/list) levels to make
  contours/surfaces for each file. Either a numeric vector
  may be passed, one level for each file.  Or a list of
  numeric vectors of multiple levels for each file. Will be
  coerced to a list.}

  \item{alpha}{(numeric/list) alpha opacities for each
  contours/surface for each file. Will be coerced to list
  similarly as levels}

  \item{color}{(character/list) colors for each
  contours/surface for each file. Will be coerced to list
  similarly as levels}

  \item{useTemp}{(logical) whether to use template from
  brainR as the brain figure}

  \item{MNITemp}{(character) if (useTemp = TRUE) either
  "1mm" or "2mm" denoting the resolution of the template
  used}

  \item{objtype}{(character) object type to write the files
  to.  Either "stl", "obj", or "ply" to write.}

  \item{...}{other options to be passed to \link{write4D}}
}
\description{
This function takes in filenames, levels, and creates an
output html file, with 4D elements.  The html is based on
XTK (https://github.com/xtk/X#readme)
}
\examples{
### Faster - 8mm resampled but very coarse
imgs <- paste("Visit_", 1:5, "_8mm.nii.gz", sep="")
 files <- sapply(imgs, system.file, package='brainR')
scene4d(files, levels=rep(0.99, length(files)), color= rep("blue", length(files)), useTemp=TRUE,
MNITemp = "8mm", alpha = rep(1, length(files)), rescale=TRUE  )
\dontrun{
imgs <- paste("Visit_", 1:5, ".nii.gz", sep="")
 files <- sapply(imgs, system.file, package='brainR')
scene4d(files, levels=rep(0.99, length(files)), color= rep("blue", length(files)), useTemp=TRUE,
MNITemp = "1mm", alpha = rep(1, length(files)), rescale=TRUE  )
}
}

