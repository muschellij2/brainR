\name{write4D.file}
\alias{write4D.file}
\title{Write a 4D scene}
\usage{
  write4D.file(scene = NULL, outfile = "index_4D.html",
    fnames, visible = TRUE, opacity = 1, colors = NULL,
    captions = "", standalone = FALSE, rescale = FALSE,
    index.file = system.file("index_template.html", package = "brainR"),
    toggle = "checkbox")
}
\arguments{
  \item{scene}{- list of 3D triangles (see
  \link[misc3d]{contour3d}).  If a multicolored object is
  to be rendered (multiple contours with one control) - it
  must be in a list}

  \item{outfile}{- html filename that is to be exported}

  \item{fnames}{- filenames for the 3D surfaces in the
  scene - needs to be the same length as scene}

  \item{visible}{- logical vector indicating which
  structures are visible in html file}

  \item{opacity}{- list of alpha values - same length as
  scene; if sub-structures are present, then the each list
  element has length the numer of structures}

  \item{standalone}{- logical - should this be able to be
  rendered offline?}

  \item{rescale}{- rescale the scene? - in beta}

  \item{captions}{- labels for checkboxes on html webpage}

  \item{colors}{- character vector of colors (col2rgb is
  applied)}

  \item{index.file}{- template html file used}

  \item{toggle}{- (experimental) "checkbox" (default) or
  "radio" for radio or checkboxes to switch thing}
}
\value{
  NULL
}
\description{
  This function takes in a scene and writes it out to a
  series of files either with the stl format or obj format
}
\seealso{
  \code{\link{writeOBJ}}, \code{\link{writeSTL}},
  \code{\link{contour3d}}
}

