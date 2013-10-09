#' Wrapper to write a 4D scene
#'
#' This function takes in a scene and writes it out to a series of files
#' either with the stl format or obj format (see \link{writeOBJ} and 
#' \link{writeSTL})
#'
#' @param scene list of 3D triangles (see \link{contour3d}).  If a multicolored
#' object is to be rendered (multiple contours with one control) - it must be in a 
#' list
#' @param outfile html filename that is to be exported
#' @param fnames filenames for the 3D surfaces in the scene - needs to 
#' be the same length as scene
#' @param captions labels for checkboxes on html webpage
#' @param ... other options to be passed to \link{write4D.file}
#' @export
#' @examples
#' template <- readNIfTI(system.file("MNI152_T1_1mm_brain.nii.gz", package="brainR")
#' , reorient=FALSE) 
#' dtemp <- dim(template)
#' ### 4500 - value that empirically value that presented a brain with gyri
#' ### lower values result in a smoother surface
#' brain <- contour3d(template, x=1:dtemp[1], y=1:dtemp[2], 
#' z=1:dtemp[3], level = 4500, alpha = 0.8, draw = FALSE)
#' 
#' ### Example data courtesy of Daniel Reich 
#' ### Each visit is a binary mask of lesions in the brain
#' imgs <- paste("Visit_", 1:5, ".nii.gz", sep="") 
#' files <- sapply(imgs, system.file, package='brainR')
#' scene <- list(brain)
#' ## loop through images and thresh
#' nimgs <- length(imgs)
#' cols <- rainbow(nimgs)
#' for (iimg in 1:nimgs) {
#' mask <- readNIfTI(files[iimg], reorient=FALSE)
#' if (length(dim(mask)) > 3) mask <- mask[,,,1] 
#' ### use 0.99 for level of mask - binary
#'   activation <- contour3d(mask, level = c(0.99), alpha = 1, 
#'   add = TRUE, color=cols[iimg], draw=FALSE)  
#' ## add these triangles to the list
#' scene <- c(scene, list(activation))
#' }
#' ## make output image names from image names
#' fnames <- c("brain.stl", gsub(".nii.gz", ".stl", imgs, fixed=TRUE))
#' outfile <-  "index_4D_stl.html"
#' write4D(scene=scene, fnames=fnames, outfile=outfile, standalone=TRUE)
#' browseURL(outfile)
#' @return NULL

write4D <- function(scene, outfile, fnames=NULL, 
                    captions=NULL, writefiles=TRUE, ...){
  
  #   if (is.null(fnames) & is.null(format)){
  #     warning("No Format or filenames specified - using STL and making names")
  #     format <- "STL"
  #   }
  
  
  nrois <- length(scene)
  nfiles <- length(fnames)
  stopifnot(nfiles == nrois)
  
  ## figure out what function to use
  formats <- sapply(strsplit(fnames, split="\\."), function(x) x[length(x)])
  formats <- toupper(formats)
  if (!all(formats %in% c("PLY", "STL", "OBJ"))){
    stop("Formats are not PLY,OBJ, or STL!")
  }
  
  roi_names <- names(scene)
  if (is.null(roi_names)) {
    tmp <- tolower(fnames)
    tmp <- gsub(".ply", "", tmp, fixed=TRUE)
    tmp <- gsub(".stl", "", tmp, fixed=TRUE)
    tmp <- gsub(".obj", "", tmp, fixed=TRUE)
    #     roi_names <- paste0("ROI", 1:nrois)
    roi_names <- tmp
  }
  stopifnot(all(!is.na(roi_names)))
  
  if (is.null(captions)) captions <- roi_names
  
  lfnames <- opacity <- colors <-NULL
  iroi <- 1
  classes <- sapply(scene, class)
  outdir <- dirname(outfile)
  
  
  write_output <- function(outdir, fname, fmt){
    filename <- file.path(outdir, fname)
    fcn <- paste0("write", fmt)
    do.call(fcn, list(con=filename))
  }
  
  getBase <- function(x, ind=1){
    sapply(strsplit(x, split="\\."), function(xx) paste(xx[1:(length(xx)-ind)], collapse=".", sep=""))
  }  
  
  for (iroi in 1:nrois) {
    #     tryCatch(rgl.close())
    pars <- par3d()
    wrect <- pars$windowRect   
    irgl <- scene[[iroi]]
    fname <- fnames[iroi]
    fmt <- formats[iroi]    
    if (class(irgl) == "Triangles3D"){
      if (writefiles) {
        drawScene.rgl(irgl)
        obj.colors <- irgl$color
        obj.opac <- irgl$alpha
        lfname <- fname
        write_output(outdir, fname, fmt)
      }
    }
    if (class(irgl) == "list"){
      obj.colors <- sapply(irgl, function(x) x$color)
      obj.opac <- sapply(irgl, function(x) x$alpha)
      
      stub <- getBase(fname, 1)
      nsubrois <- length(irgl)
      ### making the numbering zero-padded
      getfmt <- floor(log(nsubrois, 10)) + 1
      nums <- sapply(1:nsubrois, sprintf, fmt=paste0("%0", getfmt, ".0f"))
      lfname <- paste0(stub, "_", nums, ".", tolower(fmt))
      for (isroi in 1:nsubrois){
        if (writefiles) {
          iirgl <- irgl[[isroi]]
          drawScene.rgl(iirgl)
          sfname <- paste0(stub, "_", nums[isroi], ".", tolower(fmt))
          write_output(outdir, sfname, fmt )
        }
      }
    } ## end list
    stopifnot(class(irgl) %in% c("list", "Triangles3D"))
    opacity <- c(opacity, list(obj.opac))
    colors <- c(colors, list(obj.colors))
    lfnames <- c(lfnames, list(lfname))
    #     eval(parse(text=paste0("write", fmt, "(filename)")))
  } # end loop over rois
  
  if (class(scene[[1]]) == "Triangles3D") vscale <- max(scene[[1]]$v1)
  if (class(scene[[1]]) == "list") vscale <- max(scene[[1]][[1]]$v1)
  
  fnames <- lfnames
  
  write4D.file(outfile=outfile, fnames=lfnames, captions=captions, 
               colors=colors, opacity=opacity, scene=scene, ...)
  return(invisible(NULL))  
}
