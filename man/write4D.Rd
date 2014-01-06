\name{write4D}
\alias{write4D}
\title{Wrapper to write a 4D scene}
\usage{
write4D(scene, outfile, fnames = NULL, captions = NULL, writefiles = TRUE,
  ...)
}
\arguments{
  \item{scene}{list of 3D triangles (see \link{contour3d}).
  If a multicolored object is to be rendered (multiple
  contours with one control) - it must be in a list}

  \item{outfile}{html filename that is to be exported}

  \item{fnames}{filenames for the 3D surfaces in the scene
  - needs to be the same length as scene}

  \item{captions}{labels for checkboxes on html webpage}

  \item{writefiles}{(experimental) simply run the code to
  create the html and not write the .obj or .stl files}

  \item{...}{other options to be passed to
  \link{write4D.file}}
}
\description{
This function takes in a scene and writes it out to a
series of files either with the stl format or obj format
(see \link{writeOBJ} and \link{writeSTL})
}
\examples{
\dontrun{
template <- readNIfTI(system.file("MNI152_T1_1mm_brain.nii.gz", package="brainR")
, reorient=FALSE)
dtemp <- dim(template)
### 4500 - value that empirically value that presented a brain with gyri
### lower values result in a smoother surface
brain <- contour3d(template, x=1:dtemp[1], y=1:dtemp[2],
z=1:dtemp[3], level = 4500, alpha = 0.8, draw = FALSE)

### Example data courtesy of Daniel Reich
### Each visit is a binary mask of lesions in the brain
imgs <- paste("Visit_", 1:5, ".nii.gz", sep="")
files <- sapply(imgs, system.file, package='brainR')
scene <- list(brain)
## loop through images and thresh
nimgs <- length(imgs)
cols <- rainbow(nimgs)
for (iimg in 1:nimgs) {
mask <- readNIfTI(files[iimg], reorient=FALSE)
if (length(dim(mask)) > 3) mask <- mask[,,,1]
### use 0.99 for level of mask - binary
  activation <- contour3d(mask, level = c(0.99), alpha = 1,
  add = TRUE, color=cols[iimg], draw=FALSE)
## add these triangles to the list
scene <- c(scene, list(activation))
}
## make output image names from image names
fnames <- c("brain.stl", gsub(".nii.gz", ".stl", imgs, fixed=TRUE))
outfile <-  "index_4D_stl.html"
write4D(scene=scene, fnames=fnames, outfile=outfile, standalone=TRUE, rescale=TRUE)
# browseURL(outfile)
}
}

