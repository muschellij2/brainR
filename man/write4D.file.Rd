\name{write4D.file}
\alias{write4D.file}
\title{Write a 4D scene}
\usage{
  write4D.file(scene = NULL, outfile = "index_4D.html",
    fnames, visible = FALSE, opacity = 1, colors = NULL,
    captions = "", standalone = FALSE, rescale = TRUE,
    index.file = system.file("index_template.html", package = "brainGL"))
}
\arguments{
  \item{scene}{- list of 3D triangles (see
  \link[misc3d]{contour3d}).  If a multicolored object is
  to be rendered (multiple contours with one control) - it
  must be in a list}

  \item{outfile}{- html filename that is to be exported}

  \item{fnames}{- filenames for the 3D surfaces in the
  scene - needs to be the same length as scene}

  \item{captions}{- labels for checkboxes on html webpage}

  \item{...}{- other options to be passed to
  \link{write4D.file}}
}
\value{
  NULL
}
\description{
  This function takes in a scene and writes it out to a
  series of files either with the stl format or obj format
  (see \link[misc3d]{writeOBJ} and \link[misc3d]{writeSTL})
}

