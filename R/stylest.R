#' stylest: A package for estimating textual distinctiveness
#'
#' stylest provides a set of functions for fitting a model of speaker
#' distinctiveness, including tools for selecting the optimal vocabulary for the
#' model and predicting the most likely speaker (author) of a new text.
#' 
#' @importFrom Matrix rowSums colMeans
#' @importFrom stats smooth quantile
#' 
#' @name stylest
NULL