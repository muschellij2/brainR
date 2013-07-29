\name{writeWebGL_split}
\alias{writeWebGL_split}
\title{Write WebGL with split triangles}
\usage{
  writeWebGL_split(ids = rgl.ids()$id, writeIt = TRUE,
    verb = TRUE, ...)
}
\arguments{
  \item{ids}{- rgl ids (see \link[rgl]{rgl.ids})}

  \item{writeIt}{- (logical) write the file out}

  \item{verb}{- verbose output}

  \item{...}{- further arguments passed to
  \link[rgl]{writeWebGL}}
}
\value{
  if writeIt is TRUE, then returns the value from
  \link[rgl]{writeWebGL}. Otherwise, returns the split
  triangles from the rgl objects
}
\description{
  Adapted \link[rgl]{writeWebGL} function that splits the
  triangles into 65535 vertices
}

