#' Make Leveled Scene
#'
#' Make scene returns a list of levels - but makes them mutually distinct.
#' So if cutoff 0.1, 0.2, then 0.1<= x < 0.2 is an roi, not > 0.1 and > 0.2.
#' Different than \code{\link[misc3d]{contour3d}} as these are mutually exclusive levels.
#'
#'
#' @param data - 3D array of values (can be \link[oro.nifti]{nifti-class})
#' @param cutoffs - series of levels to be created
#' @param alpha - alpha levels for each contour
#' @param cols - colors for each contour
#' @export
#' @import rgl
#' @import misc3d
#' @return scene with multiple objects - can be passed to \link{write4D}
makeScene <- function(data, cutoffs, alpha, cols ){
  scene <- list()
  ### make sure ordered
  ord <- order(cutoffs)
  cutoffs <- cutoffs[ord]
  alpha <- alpha[ord]
  cols <- cols[ord]
  nlevels <- length(cutoffs)
  stopifnot(all(!is.na(alpha)), all(!is.na(cols)), all(!is.na(cutoffs)))
  ### going through rois to make the activaiton
  for (iroi in 1:nlevels){
    eps <- 0.0001
    ### levels are right inclusive
    tmp <- array(FALSE, dim=dim(data))
    mlev <- cutoffs[iroi]
    if (iroi == nlevels) {
      nlev <- max(data) + eps
    } else {
      nlev <- cutoffs[iroi+1]
    }
    ## make binary mask
    tmp[ data >= mlev & data < nlev  ] <- 1
    if (sum(tmp != 0, na.rm=TRUE) == 0){
      #     activation <- list()
      warning("No contour to make")
      next
    } else {
      activation <- contour3d(tmp, level = 0, alpha = alpha[iroi],
                              color=cols[iroi], draw=FALSE)
    }
    scene <- c(scene, list(activation))
  }
  return(scene)
}
