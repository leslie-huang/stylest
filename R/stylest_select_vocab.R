#' Select vocabulary using cross-validated out-of-sample prediction
#'
#' Selects optimal vocabulary quantile(s) for model fitting using performance on
#' predicting out-of-sampletexts.
#'
#' @export
#'
#' @param x Corpus as text vector. May be a \code{corpus_frame} object
#' @param speaker Vector of speaker labels. Should be the same length as
#'   \code{x}
#' @param filter if not \code{NULL}, a \code{corpus} text_filter
#' @param smooth value for smoothing. Defaults to 0.5
#' @param nfold Number of folds for cross-validation. Defaults to 5
#' @param cutoff_pcts Vector of cutoff percentages to test. Defaults to
#'   \code{c(50, 60, 70, 80, 90, 99)}
#' @return List of: best cutoff percent with the best speaker classification
#'   rate; cutoff percentages that were tested; matrix of the mean percentage of
#'   incorrectly identified speakers for each cutoff percent and fold; and the
#'   number of folds for cross-validation
#'
#' @examples
#' \dontrun{
#' data(novels_excerpts)
#' stylest_select_vocab(novels_excerpts$text, novels_excerpts$author, cutoff_pcts = c(50, 90))
#' }
#'   
stylest_select_vocab <- function(x, speaker, filter = NULL, smooth = 0.5, nfold = 5,
                             cutoff_pcts = c(50, 60, 70, 80, 90, 99)) {

  if (as.integer(nfold) != nfold) {
    stop("nfold must be an integer value")
  }
  
  if (as.integer(nfold) < 1 ) {
    stop("nfolds must be at least 1")
  }

  if (smooth <= 0) {
    stop("smooth value must be greater than or equal to 0")
  }
  
  for (c in cutoff_pcts) {
    if (c < 0 | c >= 100) {
      stop("cutoff percent must be value between 0 and 100")
    }
  }
  
  {
  # coerce arguments to their expected types
  x <- corpus::as_corpus_text(x, filter)
  speaker <- as.factor(speaker)
  
  ntot <- length(x)
  test_fold <- sample(rep(1:nfold, ceiling(ntot / nfold)), ntot)
  
  miss_pct <- matrix(NA, nfold, length(cutoff_pcts))
  
  for (fold in 1:nfold)  {
    # set up test and training sets
    test_set <- (test_fold == fold)
    train_set <- !test_set
    test <- x[test_set]
    train <- x[train_set]
    
    speech_stats <- corpus::term_stats(train)
    
    for (i in seq_along(cutoff_pcts)) {
      # select subset of vocab above cutoff percent
      cutoff_pct <- cutoff_pcts[[i]]
      cutoff <- cutoff_pct / 100
      terms <- subset(speech_stats, speech_stats$support >= quantile(speech_stats$support, cutoff))$term
      
      # fit model on training data 
      fit <- stylest_fit(train, speaker[train_set], terms, smooth = smooth) 
      # predict speaker for test data
      pred <- stylest_predict(fit, test) 
      # mean num incorrectly predicted speakers on test data per fold
      miss_pct[fold, i] <- 100 * mean(pred$predicted != speaker[test_set]) 
    }
  }
  
  # find the cutoff percent with the lowest miss percentage
  avg <- apply(miss_pct, 2, mean)
  i <- which.min(avg)
  
  res <- list(cutoff_pct_best = cutoff_pcts[i],
       cutoff_pcts = cutoff_pcts,
       miss_pct = miss_pct,
       nfold = nfold)
  class(res) <- "stylest_select_vocab"
  
  res
  }
}


#' Use vocab cutoff to select terms for fitting the model
#' 
#' The same text, speaker, and filter should be used in this model
#' as in \code{fit_speaker} to select the terms for the latter function.
#' 
#' @export
#' 
#' @param x Corpus as text vector. May be a \code{corpus_frame} object
#' @param speaker Vector of speaker labels. Should be the same length as
#'   \code{x}
#' @param vocab_cutoff Quantile cutoff for the vocabulary in (0, 100]
#' @param filter if not \code{NULL}, a corpus filter
#' @return list of terms
#' @examples 
#' data(novels_excerpts)
#' stylest_terms(novels_excerpts$text, novels_excerpts$author, vocab_cutoff = 50)
#'  
stylest_terms <- function(x, speaker, vocab_cutoff, filter = NULL) {
  
  if (vocab_cutoff < 0 | vocab_cutoff > 100) {
    stop("vocab cutoff percent must be between 0 and 100")
  }
  
  {
    speeches <- corpus::corpus_frame(speaker = speaker,
                             text = x,
                             filter = filter)
    
    t_stats <- corpus::term_stats(speeches)
    
    cutoff_pct <- vocab_cutoff / 100
    
    terms <- subset(t_stats, t_stats$support >= quantile(t_stats$support, cutoff_pct))$term
    
    terms
  }
}