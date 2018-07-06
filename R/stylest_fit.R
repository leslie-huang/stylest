#' Fit speaker_model to a corpus
#'
#' The main function in \code{stylest}, \code{stylest_fit} fits a
#' model using a corpus of texts labeled by speaker.
#' 
#' The user may specify only one of \code{terms} or \code{cutoff}.
#' If neither is specified, all terms will be used.
#'
#' @export
#' 
#' @param x Text vector. May be a \code{corpus_frame} object
#' @param speaker Vector of speaker labels. Should be the same length as
#'   \code{x}
#' @param terms If not \code{NULL}, terms to be used in the model. If
#'   \code{NULL}, use all terms
#' @param filter If not \code{NULL}, a text filter to specify the tokenization.
#' See \code{corpus} for more information about specifying \code{filter}
#' @param smooth Numeric value used smooth term frequencies instead of the
#'   default of 0.5
#' @return A S3 \code{stylest_model} object containing:
#' \code{speakers} Vector of unique speakers,
#' \code{filter} text_filter used,
#' \code{terms} terms used in fitting the model,
#' \code{ntoken} Vector of number of tokens per speaker,
#' \code{smooth} Smoothing value,
#' \code{rate} Matrix of speaker rates for each term in vocabulary
#' 
#' @examples
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' 
stylest_fit <- function(x, speaker, terms = NULL, filter = NULL, smooth = 0.5)
{
  
  if (smooth <= 0) {
    stop("smooth value must be greater than or equal to 0")
  }
  
  {
    # coerce arguments to their expected types
    x <- corpus::as_corpus_text(x, filter)
    speaker <- as.factor(speaker)

    if (is.null(terms)) {
        # default to fitting a model with all terms
        terms <- corpus::text_types(x, collapse = TRUE)
    } else {
        terms <- as.character(terms)
    }

    smooth <- as.numeric(smooth)[[1]]

    # fit the model
    model <- fit_term_usage(x, speaker, terms, smooth)
    cl <- "stylest_model_term"

    # package everything in an object
    result <- structure(c(list(speakers = levels(speaker),
                              filter = corpus::text_filter(x)),
                          model), 
                       class = c(cl, "stylest_model"))
    
    result
  }
}

#' Computes speakers' term usage rates
#'
#' @param x Text vector. May be a \code{corpus_frame} object
#' @param speaker Vector of speaker labels. Should be the same length as
#'   \code{x}
#' @param terms Vocabulary for document term matrix
#' @param smooth Numeric value used smooth term frequencies
#' @return named list of terms, vector of num tokens uttered by each speaker,
#'   smoothing value, and (smoothed) term usage rate matrix
#'   
fit_term_usage <- function(x, speaker, terms, smooth)
{
    # get a term matrix for the selected terms and selected speaker
    selected_dtm <- corpus::term_matrix(x, select = terms, group = speaker)

    # get the number of tokens uttered by each speaker
    ntok <- rowSums(selected_dtm)

    # get the number of unique types in the corpus
    ntype <- ncol(selected_dtm)

    # compute the (smoothed) usage rates
    rate <- (as.matrix(selected_dtm) + smooth) / (ntok + smooth * ntype)
    
    list(terms = terms, ntoken = ntok, smooth = smooth, rate = rate)
}
