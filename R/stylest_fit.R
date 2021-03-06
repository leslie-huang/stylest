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
#' @param term_weights Dataframe of distances (or any weights) per
#' word in the vocab. This dataframe should have one column $word and
#' a second column $weight_var containing the weight for the word.
#' See the vignette for details.
#' @param fill_method if \code{"value"} (default), \code{fill_weight} is
#' used to fill any terms with \code{NA} weight. If \code{"mean"}, the
#' mean term_weight should be used as the fill value
#' @param fill_weight numeric value to fill in as weight for any term
#' which does not have a weight specified in \code{term_weights}, 
#' default=\code{0.0} (drops any words without weights)
#' @param weight_varname Name of the column in term_weights containing the weights,
#' default=\code{"mean_distance"}
#' @return A S3 \code{stylest_model} object containing:
#' \code{speakers} Vector of unique speakers,
#' \code{filter} text_filter used,
#' \code{terms} terms used in fitting the model,
#' \code{ntoken} Vector of number of tokens per speaker,
#' \code{smooth} Smoothing value,
#' \code{weights} If not NULL, a named matrix of weights for each term in the vocab,
#' \code{rate} Matrix of speaker rates for each term in vocabulary
#'
#' @examples
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#'
stylest_fit <-
  function(x,
           speaker,
           terms = NULL,
           filter = NULL,
           smooth = 0.5,
           term_weights = NULL,
           fill_method = "value",
           fill_weight = 0.0,
           weight_varname = "mean_distance")
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
      model <-
        fit_term_usage(x,
                       speaker,
                       terms,
                       smooth,
                       term_weights,
                       fill_method,
                       fill_weight,
                       weight_varname)
      cl <- "stylest_model_term"
      
      # package everything in an object
      result <- structure(c(
        list(
          speakers = levels(speaker),
          filter = corpus::text_filter(x)
        ),
        model
      ),
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
#' @param term_weights Dataframe of distances (or any weights) per
#' word in the vocab. This dataframe should have one column $word and
#' a second column $weight_var containing the weight for the word
#' @param fill_method if \code{"value"} (default), \code{fill_weight} is
#' used to fill any terms with \code{NA} weight. If \code{"mean"}, the
#' mean term_weight should be used as the fill value
#' @param weight_varname Name of the column in term_weights containing the weights
#' @param fill_weight numeric value to fill in as weight for any term
#' which does not have a weight specified in \code{term_weights}
#' @return named list of: terms, vector of num tokens uttered by each speaker,
#'   smoothing value, term weights (NULL if no weights), terms whose 
#'   weights were imputed (NULL if no \code{term_weights=NULL}), fill_weight 
#'   used to fill missing weights (NULL if no \code{term_weights=NULL}),
#'   and (smoothed) term usage rate matrix

#'
fit_term_usage <-
  function(x,
           speaker,
           terms,
           smooth,
           term_weights,
           fill_method,
           fill_weight,
           weight_varname)
  {
    # get a term matrix for the selected terms and selected speaker
    selected_dtm <-
      corpus::term_matrix(x, select = terms, group = speaker)
    
    # get the number of tokens uttered by each speaker
    ntok <- Matrix::rowSums(selected_dtm)
    
    # get the number of unique types in the corpus
    ntype <- ncol(selected_dtm)
    
    # compute the (smoothed) usage rates
    rate <-
      (as.matrix(selected_dtm) + smooth) / (ntok + smooth * ntype)
    
    if (is.null(term_weights)) {
      weights <- NULL
      terms_without_weights <- NULL
      fill_value_used <- NULL
    } else {
      # construct vector of multipliers for words in same order as rate
      rownames(term_weights) <- term_weights$word
      weights <- term_weights[colnames(rate), weight_varname]
      terms_without_weights <- colnames(rate)[is.na(weights)]
      
      if (fill_method == "mean") {
        fill_value_used <- mean(weights, na.rm = TRUE)
      }
      else {
        fill_value_used <- fill_weight
      }
      weights[is.na(weights)] <- fill_value_used
      names(weights) <- colnames(rate)
    }
    
    list(
      terms = terms,
      ntoken = ntok,
      smooth = smooth,
      weights = weights,
      rate = rate,
      terms_without_weights = terms_without_weights,
      fill_weight = fill_value_used
    )
  }

#'
#' Custom print method for stylest_model
#'
#' @export
#'
#' @param x `stylest_model` object
#' @param ... Additional arguments
#' @return Prints summary information about the `stylest_model` object
#'
#' @examples
#'
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' print(speaker_mod)
#'
print.stylest_model <- function(x, ...) {
  cat("A S3 stylest_model object containing: ")
  cat(length(x$speakers),
      "unique authors and",
      length(x$terms),
      "unique terms.")
  
}