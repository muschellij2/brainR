#' Write a 4D scene
#'
#' This function takes in a scene and writes it out to a series of files
#' either with the stl format or obj format 
#'
#' 
#' @param scene - list of 3D triangles (see \link[misc3d]{contour3d}).  If a multicolored
#' object is to be rendered (multiple contours with one control) - it must be in a 
#' list
#' @param outfile - html filename that is to be exported
#' @param fnames - filenames for the 3D surfaces in the scene - needs to 
#' be the same length as scene
#' @param visible - logical vector indicating which structures are visible in 
#' html file
#' @param opacity - list of alpha values - same length as scene; if sub-structures
#' are present, then the each list element has length the number of structures 
#' @param standalone - logical - should this be able to be rendered offline?
#' @param rescale - rescale the scene? - in beta
#' @param captions - labels for checkboxes on html webpage
#' @param colors - character vector of colors (col2rgb is applied)
#' @param index.file - template html file used
#' @param toggle - (experimental) "checkbox" (default) or "radio" for radio or checkboxes to switch thing 
#' @param xtkgui - (experimental) Logical to use xtkgui for objects
#' @export
#' @import rgl
#' @import oro.nifti
#' @import misc3d
#' @seealso \code{\link[rgl]{writeOBJ}}, \code{\link[rgl]{writeSTL}}, 
#' \code{\link[misc3d]{contour3d}}
#' @return NULL
#' @examples 
#'
#' template <- readNIfTI(system.file("MNI152_T1_8mm_brain.nii.gz", package="brainR")
#' , reorient=FALSE)
#' dtemp <- dim(template)
#' ### 4500 - value that empirically value that presented a brain with gyri
#' ### lower values result in a smoother surface
#' brain <- contour3d(template, x=1:dtemp[1], y=1:dtemp[2],
#' z=1:dtemp[3], level = 4500, alpha = 0.8, draw = FALSE)
#'
#' ### Example data courtesy of Daniel Reich
#' ### Each visit is a binary mask of lesions in the brain
#' imgs <- paste("Visit_", 1:5, "_8mm.nii.gz", sep="")
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
#' fnames = file.path(tempdir(), fnames)
#' outfile <-  file.path(tempdir(), "index.html")
#' write4D.file(
#' scene=scene, fnames=fnames, 
#' visible = FALSE,
#' outfile=outfile, standalone=TRUE, rescale=TRUE)
#' 
#' 
#' 
#' unlink(outfile)
#' unlink(fnames)
write4D.file <- function(
  scene=NULL, outfile="index_4D.html", fnames, 
  visible=TRUE, 
  opacity = 1, 
  colors = NULL,
  captions = "",
  standalone=FALSE,
  rescale=FALSE,
  index.file=system.file("index_template.html", 
                         package="brainR"), 
  toggle="checkbox", xtkgui = FALSE){
  
  
  stopifnot(!is.null(scene))
  
  f <- file(index.file)
  htmltmp <- readLines(f)
  close(f)
  
  classes <- sapply(scene, class)
  scaler <- 100
  if (rescale) scaler <- max(scene[[1]]$v1)
  
  htmltmp <- gsub("%SCALER%", scaler, htmltmp)
  
  
  
  ## figure out what function to use
  formats <- sapply(fnames, gsub, pattern=".*\\.(.*)$", replacement="\\1")
  cformat <- unlist(formats)
  cformat <- toupper(cformat)
  if (!all(cformat %in% c("PLY", "STL", "OBJ"))){
    stop("Formats are not PLY,OBJ, or STL!")
  }
  
  # roi_names <- names(scene)
  # if (is.null(roi_names)) {
  # tmp <- tolower(sapply(fnames, function(x) x[1]))
  # tmp <- gsub(pattern=".ply", replacement="", x=tmp, fixed=TRUE)
  # tmp <- gsub(pattern=".stl", replacement="", x=tmp, fixed=TRUE)
  # tmp <- gsub(pattern=".obj", replacement="", x=tmp, fixed=TRUE)
  # roi_names <- tmp
  # }
  
  
  if (!"logical" %in% class(visible)) stop("visible must be logical")
  copac <- unlist(opacity)
  if (any(copac > 1 | copac < 0)) stop("Opacity must be in [0,1]")
  if (!is.null(colors)){
    colors <- lapply(colors, function(x) t(col2rgb(x))/(256 / 2))
    # if (class(colors) == "character"){
    # colors <- t(col2rgb(colors))/(256 / 2)
    # }
  } else {
    colors = lapply(scene, function(x) x$color)
    colors = lapply(colors, col2rgb)
  }
  stopifnot(all(sapply(colors, inherits, what = "matrix")))
  
  ## generic checking
  nrois <- length(fnames) 
  lopac <- length(opacity)  
  params <- list(opacity=opacity, visible=visible, captions=captions)
  
  ## make sure lengths are fine
  check_size <- function(obj){
    lobj <- length(obj)
    if (lobj != nrois & length(lobj) > 1){
      stop("One parameter doesn't have same size as fnames")
    }
  }
  
  rep_out <- function(obj){
    if (length(obj) == 1 & nrois > 1) return(rep(obj, nrois))
    else return(obj)
  }
  
  ## will error if fails
  sapply(params, check_size)
  ## fill in the list (so that it can be referenced by index)
  params <- lapply(params, rep_out)
  
  ### looping throught the rois and setting parameters
  add_roi <- grep("%ADDROI%", htmltmp)
  indent <- gsub("%ADDROI%", "", htmltmp[add_roi])
  ### assume that the first image is a brain
  
  make_input <- function(roiname, caption, vis, toggle){
    if (caption == "" | is.na(caption)) caption <- roiname
    stopifnot(all(vis %in% c("true", "false")))
    addto <- paste0(', Value = "', roiname, '"')
    if (toggle == "checkbox") {
      fcn <- "GetSelectedItem() "
      rname <- "r2"
    }
    if (toggle == "radio") {
      fcn <- "GetradioSelectedItem() "
      rname <- "r1"
      ### have the first one clicked
      vis <- ifelse(roiname == "ROI2", TRUE, FALSE)
    }      
    ret <- paste0('<Input type = ', toggle, ' Name = ', rname, " ", addto, 
                  ' onClick = ', fcn, ifelse(vis, 'checked', ""), 
                  '>', caption)
    return(ret)
  }  
  
  
  pusher <- function(rname, fname, param, pushto="scene"){
    cmd <- paste0(rname, "= new X.mesh();")
    cmd <- c(cmd, 
             paste0(rname, ".file = '", fname, "';"))
    vis <- tolower(param$visible)
    cmd <- c(cmd, 
             paste0(rname, ".visible = ", vis, ";"))        
    cmd <- c(cmd, 
             paste0(pushto, ".children.push(", rname, ");"))
    cap <- param$captions
    cmd <- c(cmd, 
             paste0(rname, ".caption = '", cap, "';"))   
    
    
    rguiname = paste0(rname, "GUI")
    guicmd = sprintf("var %s = gui.addFolder('%s');", rguiname, cap)
    guicmd = c(guicmd, paste0(rguiname, ".add(", rname, ", 'visible');"))
    guicmd = c(guicmd, paste0(rguiname, ".add(", rname, ", 'opacity', 0, 1);"))
    guicmd = c(guicmd, paste0(rguiname, ".addColor(", rname, ", 'color');"))
    #     guicmd = c(guicmd, paste0(rguiname, ".open()"))
    
    ### options not yet implemented
    cols <- paste0(param$colors, collapse=", ")
    
    cmd <- c(cmd, 
             paste0(rname, ".color = [", cols, "];"))
    #     ## down with opp? - opacity true/false
    opp <- as.numeric(param$opacity)
    cmd <- c(cmd, 
             paste0(rname, ".opacity = ", opp, ";"))
    
    ## just nice formatting for the html to indent
    cmd <- paste0(indent, cmd)
    guicmd = paste0(indent, guicmd)
    #     if (xtkgui) cmd = c(cmd, guicmd)
    return(list(cmd=cmd, guicmd=guicmd))
    
    
  }
  
  iroi <- 1
  guicmds <- inputs <- cmds <- NULL
  for (iroi in 1:nrois) {
    ### allow you to set all the controls for the images
    rclass <- classes[iroi]
    
    cols <- colors[[iroi]]	
    fname <- fnames[[iroi]]
    
    rname <- paste0("ROI", iroi) 
    if (rclass == "Triangles3D"){
      param <- list(opacity = unlist(params$opacity[iroi]), 
                    visible = params$visible[iroi], 
                    captions= params$captions[iroi], colors=cols)			
      topush = pusher(rname, fname, param, pushto= "scene")
      cmd <- topush$cmd
      guicmd = topush$guicmd
    }
    if (rclass == "list"){
      
      cmd <- paste0(rname, "= new X.object();")
      cmd <- c(cmd, paste0("scene.children.push(", rname, ");"))
      vis <- tolower(params$visible[iroi])
      cmd <- c(cmd, paste0(rname, ".visible = ", vis, ";"), "")
      for (isubroi in 1:length(fname)){
        param <- list(opacity = unlist(params$opacity[iroi])[isubroi], 
                      visible = params$visible[iroi], captions= params$captions[iroi], 
                      colors=cols[isubroi,])		
        rrname <- paste0(rname, "_", isubroi)
        ffname <- fname[isubroi]
        topush = pusher(rrname, ffname, param, pushto= rname)
        cmd <- c(cmd, topush$cmd, "")
      }
      param <- list(opacity = 1, 
                    visible = TRUE, captions= params$captions[iroi], 
                    colors= "white")     
      topush = pusher(rname, fname, param, pushto= "blah")
      guicmd <- topush$guicmd
      
    }
    
    
    cap <- params$captions[iroi][1]
    vis <- tolower(params$visible[iroi][1])
    
    # print("Caption")
    # print(cap)
    ### for checkboxes
    input = NULL
    if (iroi == 1) {
      input <- make_input(roiname=rname, caption=cap, vis=vis, toggle= "checkbox")
    } else {
      #       print(iroi)
      if (!(toggle %in% "slider")) {
        #         print('making input')
        input <- make_input(roiname=rname, caption=cap,
                            vis=vis, toggle= toggle)
      }
    }
    inputs <- c(inputs, input)
    
    cmds <- c(cmds, "", cmd)
    guicmds <- c(guicmds, "", guicmd)
    
  }
  
  if ((toggle %in% "slider") & nrois > 1){
    #     print(toggle)
    inputs = c(inputs, 
               paste0('<input id="defaultSlider" type="range" min="2" max="', 
                      nrois, 
                      '" step="1" value="2" onchange="GetSliderItem(', 
                      "'defaultSlider'", 
                      ');" />'))
  }
  
  ### add in the commands to the html
  htmltmp <- c(htmltmp[1:(add_roi-1)], cmds, 
               htmltmp[(add_roi+1):length(htmltmp)])
  roinames <- "'ROI1'"
  if (nrois > 1) roinames <- paste0("'ROI", 2:nrois, "'", collapse = ", ")
  
  
  addgui <- grep("%ADDGUI%", htmltmp)
  if (xtkgui) {
    htmltmp <- c(htmltmp[1:(addgui -1)], 
                 "var gui = new dat.GUI();", 
                 guicmds,
                 htmltmp[(addgui+1):length(htmltmp)])
  } else {
    htmltmp <- c(htmltmp[1:(addgui -1)], 
                 htmltmp[(addgui+1):length(htmltmp)])
  }
  
  addlist <- grep("%ADDROILIST%", htmltmp)
  htmltmp[addlist] <- gsub("%ADDROILIST%", roinames, htmltmp[addlist])
  
  if (xtkgui){
    rmbrainopac <- grep("%BRAINOPAC%", htmltmp)
    htmltmp <- c(htmltmp[1:(rmbrainopac-1)], 
                 htmltmp[(rmbrainopac+1):length(htmltmp)])
    ### remove text box
    rmbrainopac <- grep("range_brain", htmltmp)
    htmltmp <- c(htmltmp[1:(rmbrainopac-1)], 
                 htmltmp[(rmbrainopac+1):length(htmltmp)])    
  }
  ## set opacity
  htmltmp <- gsub("%BRAINOPAC%", copac[1], htmltmp)
  
  ## add checkboxes for control
  addbox <- grep("%ADDCHECKBOXES%", htmltmp)
  #   print(inputs)
  if (!xtkgui){
    htmltmp <- c(htmltmp[1:(addbox-1)], inputs, 
                 htmltmp[(addbox+1):length(htmltmp)])
  } else {
    htmltmp <- c(htmltmp[1:(addbox-1)], 
                 htmltmp[(addbox+1):length(htmltmp)])    
  }
  
  ## put in the other xtk_edge stuff if standalone
  outdir <- dirname(outfile)
  if (standalone) {
    htmltmp <- gsub("http://get.goxtk.com/xtk_edge.js", "xtk_edge.js", 
                    htmltmp, fixed=TRUE)
    htmltmp <- gsub("http://get.goXTK.com/xtk_xdat.gui.js", "xtk_xdat.gui.js", 
                    htmltmp, fixed=TRUE)    
    file.copy(from=system.file("xtk_xdat.gui.js", package="brainR"), 
              to=file.path(outdir, "xtk_xdat.gui.js") )
    file.copy(from=system.file("xtk_edge.js", package="brainR"), 
              to=file.path(outdir, "xtk_edge.js") )    
    ### copy xtk_edge.js to file
  }  
  writeLines(htmltmp, con=outfile, sep="\n")
  
  return(invisible(NULL))
}
