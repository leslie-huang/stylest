#' Predict the most likely speaker of a text
#'
#' Use a fitted stylest_model to predict the most likely speaker of a text.
#' This function may be used on in-sample or out-of-sample texts.
#'
#' @export
#'
#' @param model \code{stylest_model} object
#' @param text Text vector. May be a \code{corpus_frame} object
#' @param prior Prior probability, defaults to \code{NULL}
#' @return \code{stylest_predict} object containing:
#' \code{model} the fitted \code{stylest_model} object used in prediction,
#' \code{predicted} the predicted speaker,
#' \code{log_probs} matrix of log probabilities,
#' \code{log_prior} matrix of log prior probabilities
#' 
#' @examples 
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' stylest_predict(speaker_mod, "This is an example text, who wrote it?")
#'   
stylest_predict <- function(model, text, prior = NULL)
{
    stopifnot(inherits(model, "stylest_model"))

    nspeaker <- length(model$speakers)

    text <- corpus::as_corpus_text(text, model$filter)

    # use an equal prior if left unspecified
    if (is.null(prior)) {
        log_prior <- rep(-log(nspeaker), nspeaker) # log(1/nspeaker)
    } else {
        log_prior <- log(prior)
    }
    names(log_prior) <- model$speakers

    terms <- model$terms
    x <- corpus::term_matrix(text, select = model$terms)
    ntok <- rowSums(x)

    # for each speech, evaluate the Poisson log-likelihoods for
    # the speakers; don't worry about the normalizing constant since
    # it is the same for all speakers
    eta <- log(model$rate)
    loglik <- x %*% t(eta) - ntok %*% t(rowSums(model$rate))
    rownames(loglik) <- rownames(x)

    # for each speech, compute the posterior probabilities for the speakers
    log_weights <- loglik
    if (!is.null(prior)) {
        log_weights <- sweep(log_weights, 2, log_prior, "+")
    }

    # guard against overflow
    log_weights <- log_weights - apply(log_weights, 1, max)

    const <- log(rowSums(exp(log_weights)))
    log_probs <- log_weights - const
    rownames(log_probs) <- rownames(x)

    predicted <- model$speakers[apply(log_probs, 1, which.max)]
    predicted <- factor(predicted, levels = model$speakers)

    res <- list(model = model, predicted = predicted,
                log_probs = log_probs, log_prior = log_prior)
    class(res) <- "stylest_predict"
    res
}
