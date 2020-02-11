#' Compute the influence of terms
#' 
#' @export
#'
#' @param model \code{stylest_model} object
#' @param text Text vector. May be a \code{corpus_frame} object
#' @param speaker Vector of speaker labels. Should be the same length as
#'   \code{x}
#' @return \code{data.frame} with columns representing terms, their mean influence,
#' and their maximum influence
#'   
#' @examples 
#' data(novels_excerpts)
#' speaker_mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author)
#' stylest_term_influence(speaker_mod, novels_excerpts$text, novels_excerpts$author)
stylest_term_influence <- function(model, text, speaker)
{
  if (!inherits(model, "stylest_model_term"))
    stop("unsupported stylest model type")
  
    eta <- log(model$rate)
    text <- corpus::as_corpus_text(text, model$filter)

    x <- corpus::term_matrix(text, select = model$terms)
    ntok <- Matrix::rowSums(x)

    fbar <- matrix(NA, length(model$speakers), length(model$terms))
    rownames(fbar) <- model$speakers
    colnames(fbar) <- model$terms

    for (i in seq_len(nrow(fbar))) {
        t <- model$speakers[[i]]
        x_t <- x[speaker == t, , drop = FALSE]
        fbar[i, ] <- Matrix::colMeans(x_t) #spkr's mean term frequency rate (averaged over their docs)
    }

    etabar <- Matrix::colMeans(eta)
    eta_centered <- eta - matrix(1, nrow(eta), 1) %*% etabar

    d <- fbar * eta_centered

    term <- model$terms
    infl_avg <- apply(abs(d), 2, mean)
    infl_max <- apply(abs(d), 2, max)

    data.frame(term, infl_avg, infl_max, row.names = NULL)
}
