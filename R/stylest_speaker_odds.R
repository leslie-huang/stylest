#' Pairwise prediction of the most likely speaker of texts
#'
#' Computes the mean log odds of the most likely speaker of each
#' text over pairs of the speaker of a text and every other speaker in the
#' \code{stylest_model}.
#'
#' @export
#'
#' @param model \code{stylest_model} object
#' @param text Text vector. May be a \code{corpus_frame} object
#' @param speaker Vector of speaker labels. Should be the same length as
#'   \code{x}
#' @param prior Prior probability of speakers. Uses equal prior if \code{NULL}
#' @return A S3 \code{stylest_odds} object containing: a
#'   \code{stylest_model} object; vector of mean log odds that each actual
#'   speaker (compared with other speakers in the corpus) spoke their
#'   corresponding texts in the corpus; vector of SEs of the log odds
#'
#' @examples
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' stylest_odds(speaker_mod, novels_excerpts$text, novels_excerpts$author)
#'   
stylest_odds <- function(model, text, speaker, prior = NULL)
{
    stopifnot(inherits(model, "stylest_model"))
  
    nspeaker <- length(model$speakers)

    text <- corpus::as_corpus_text(text, model$filter)
    baseline <- match(as.character(speaker), model$speakers)

    # use an equal prior if left unspecified
    if (is.null(prior)) {
        log_prior <- rep(-log(nspeaker), nspeaker) # log(1/nspeaker)
    } else {
        log_prior <- log(prior)
    }
    names(log_prior) <- model$speakers

    terms <- model$terms
    x <- corpus::term_matrix(text, select = model$terms)
    ntok <- Matrix::rowSums(x)

    # for each speech, evaluate the Poisson log-likelihoods for
    # the speakers; don't worry about the normalizing constant since
    # it is the same for all speakers
    eta <- log(model$rate)
    
    # multiply by term weights if they exist
    if (!is.null(model$weights)) {
      # make sure weights are in the same order for matrix multiplication
      sorted_weights <- model$weights[colnames(eta)]
      for (i in 1:nrow(eta)) {
        eta[i, ] <- eta[i, ] * sorted_weights
      }
    }
    
    loglik <- x %*% t(eta) - ntok %*% t(Matrix::rowSums(model$rate))
    rownames(loglik) <- rownames(x)

    # for each speech, compute the posterior probabilities for the speakers
    log_weights <- loglik
    if (!is.null(prior)) {
        log_weights <- sweep(log_weights, 2, log_prior, "+")
    }

    # NOTE: normalize by number of tokens to make speeches of different
    # lengths comparable
    log_weights <- log_weights / ifelse(ntok == 0, 1, ntok)

    # compute ratio of baseline to other (zeros are actual spkr)
    log_odds <- log_weights[cbind(seq_along(baseline), baseline)] - log_weights

    # average globally
    nspk <- ncol(log_odds)
    log_odds_avg <- Matrix::rowSums(log_odds) / nspk
    log_odds_se  <- apply(log_odds, 1, stats::sd) / sqrt(nspk)

    # put NA for speeches of length 0
    log_odds_avg[ntok == 0] <- NA
    log_odds_se[ntok == 0] <- NA

    res <- list(model = model, log_odds_avg = log_odds_avg,
                log_odds_se = log_odds_se)
    class(res) <- "stylest_odds"
    res
}
