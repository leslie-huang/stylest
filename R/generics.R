#' Summarise Predictions
#'
#' This summary function returns a data frame with documents as
#' rownames and either the most likely author, or posterior
#' probabilities over all possible authors, for each document.
#' 
#' If \code{type} is "\code{predicted}",
#' the columns are "\code{author}", a character vector of predicted author
#' names, and "\code{prob}", the posterior probability of this author
#' assignment under the model.
#' If \code{type} is "\code{logprobs}" columns are named by
#' possible author and each element is
#' the log posterior probability assigned to each document and author,
#' relative to the other possible authors.
#' If \code{type} is "\code{probs}", each element is the posterior
#' probability that a document is assigned to each author relative to
#' the others.  This is constructed from the log posterior
#' unsing a logistic transformation across rows, a.k.a. 'softmax'.
#'
#' Note: if \code{newdata} is a quanteda::corpus then quanteda's \code{docnames} may return generic names.  These are currently 
#' "text1", "text2", etc. so you may want to change them first.
#' 
#' @param object Predictions from a stylest_model
#'               (a \code{\link{stylest_predict}} object)
#' @param type Type of prediction "\code{predicted}" (the default),
#'             "\code{logprobs}" or "\code{probs}".  See Details.
#' @param ... Other arguments (ignored)
#'
#' @return a summary data frame of predictions
#' @export
#' @examples
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' preds <- stylest_predict(speaker_mod, "This is an example text, who wrote it?")
#' summary(preds)
summary.stylest_predict <- function(object,
                                    type = c("predicted", "probs", "logprobs"),
                                    ...){
  type <- match.arg(type)
  m <- as.data.frame(as.matrix(object$log_probs))
  if (type != "logprobs"){
    m <- exp(as.matrix(object$log_probs))
    m <- as.data.frame(m / rowSums(m))
    if (type == "predicted")
      m <- data.frame(author = as.character(object$predicted),
                      prob = apply(m, 1, max),
                      stringsAsFactors = FALSE)
  }
  m
}

#' Predict the Authors of Documents
#'
#' This function returns a data frame with documents as
#' rownames and author predictions as columns.
#' 
#' If \code{type} is "\code{predicted}" the columns are
#' "\code{author}", a character vector of predicted author names, and
#' "\code{prob}", the posterior probability of this author assignment under the model.
#' If \code{type} is "\code{logprobs}" there are as many columns as possible
#' authors and each element of the data frame is
#' the log posterior probability the model assigns to each author and
#' document.  If \code{type} is "\code{probs}", each element is the posterior
#' probability that a document is assigned to an author relative to all the
#' others.  This is constructed from the log posterior by inverse logistic
#' transformation, a.k.a. 'softmax'.
#'
#' Note: if \code{newdata} is a quanteda::corpus then quanteda's \code{docnames}
#' may return generic names.  These are currently "text1", "text2", etc.
#'
#' @param object A fitted stylest_model
#' @param newdata A character vector of texts, corpus::corpus_frame, or
#'                quanteda::corpus object
#' @param type Type of prediction "\code{predicted}" (the default),
#'             "\code{logprobs}" or "\code{probs}". See below for details
#' @param ... Other arguments (ignored)
#' @return a data frame of author predictions
#' @export
#' @examples
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' predict(speaker_mod, "This is an example text, who wrote it?", type = "probs")
predict.stylest_model <- function(object, newdata,
                                  type = c("predicted", "probs", "logprobs"),
                                  ...){
  type <- match.arg(type)
  if ("corpus_frame" == class(newdata)){
    newdata <- newdata$text
    names(newdata) <- newdata$title
  }
  preds <- stylest_predict(object, newdata)
  m <- as.data.frame(as.matrix(preds$log_probs))
  if (type != "logprobs"){
    m <- exp(as.matrix(preds$log_probs))
    m <- as.data.frame(m / rowSums(m))
    if (type == "predicted")
      m <- data.frame(author = as.character(preds$predicted),
                      prob = apply(m, 1, max),
                      stringsAsFactors = FALSE)
  }
  m
}
