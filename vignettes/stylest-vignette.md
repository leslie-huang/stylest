About
-----

This vignette describes the usage of `stylest` for estimating speaker
(author) style distinctiveness.

### Installation

Install `stylest` from GitHub by executing:

    # install.packages("devtools")
    devtools::install_github("leslie-huang/stylest")

### Load the package

`stylest` is built on top of `corpus`. `corpus` is required to specify
(optional) parameters in `stylest`, so we recommend installing `corpus`
as well.

    library(stylest)
    library(corpus)

Example: Fitting a model to English novels
==========================================

Corpus
------

We will be using texts of the first lines of novels by Jane Austen,
George Eliot, and Elizabeth Gaskell. Excerpts were obtained from the
full texts of novels available on Project Gutenberg: .

    data(novels_excerpts)

The corpus should have at least one variable by which the texts can be
grouped --- the most common examples are a "speaker" or "author"
attribute. Here, we will use `novels_excerpts$author`.

    unique(novels_excerpts$author)
    #> [1] "Gaskell, Elizabeth Cleghorn" "Eliot, George"              
    #> [3] "Austen, Jane"

Using `stylest_select_vocab`
----------------------------

This function uses n-fold cross-validation to identify the set of terms
that maximizes the model's rate of predicting the speakers of
out-of-sample texts. For those unfamiliar with cross-validation, the
technical details follow:

-   The terms of the raw vocabulary are ordered by frequency.
-   A subset of the raw vocabulary above a frequency percentile is
    selected; e.g. terms above the 50th percentile are those which occur
    more frequently than the median term in the raw vocabulary.
-   The corpus is divided into n folds.
-   One of these folds is held out and the model is fit using the
    remaining n-1 folds. The model is then used to predict the speakers
    of texts in the held-out fold. (This step is repeated n times.)
-   The mean prediction rate for models using this vocabulary
    (percentile) is calculated.

(Vocabulary selection is optional; the model can be fit using all the
terms in the support of the corpus.)

Setting the seed before this step, to ensure reproducible runs, is
recommended:

    set.seed(1234)

Below are examples of `stylest_select_vocab` using the defaults and with
custom parameters:

    vocab_with_defaults <- stylest_select_vocab(novels_excerpts$text, novels_excerpts$author)

Tokenization selections can optionally be passed as the `filter`
argument; see the `corpus` package for more information about
`text_filter`.

    filter <- corpus::text_filter(drop_punct = TRUE, drop_number = TRUE)

    vocab_custom <- stylest_select_vocab(novels_excerpts$text, novels_excerpts$author, 
                                         filter = filter, smooth = 1, nfold = 10, 
                                         cutoff_pcts = c(50, 75, 99))

Let's look inside the `vocab_with_defaults` object.

    # Percentile with best prediction rate
    vocab_with_defaults$cutoff_pct_best
    #> [1] 80

    # Rate of INCORRECTLY predicted speakers of held-out texts
    vocab_with_defaults$miss_pct
    #>          [,1]     [,2]     [,3]     [,4]     [,5]     [,6]
    #> [1,] 25.00000 25.00000 25.00000  0.00000 50.00000 50.00000
    #> [2,] 75.00000 75.00000 75.00000 75.00000 75.00000 75.00000
    #> [3,] 66.66667 66.66667 66.66667 33.33333 33.33333 33.33333
    #> [4,] 20.00000 20.00000 20.00000 20.00000 40.00000 40.00000
    #> [5,] 80.00000 80.00000 80.00000 60.00000 40.00000 20.00000

    # Data on the setup:

    # Percentiles tested
    vocab_with_defaults$cutoff_pcts
    #> [1] 50 60 70 80 90 99

    # Number of folds
    vocab_with_defaults$nfold
    #> [1] 5

Fitting a model
---------------

### Using a percentile to select terms

With the best percentile identified as 80 percent, we can select the
terms above that percentile to use in the model. Be sure to use the same
`text_filter` here as in the previous step.

    terms_80 <- stylest_terms(novels_excerpts$text, novels_excerpts$author, 80, filter = filter)

### Fitting the model

Below, we fit the model using the terms above the 80th percentile, using
the same `text_filter` as before, and leaving the smoothing value for
term frequencies as the default `0.5`.


    mod <- stylest_fit(novels_excerpts$text, novels_excerpts$author, terms = terms_80, filter = filter)

The model contains detailed information about token usage by each of the
authors; exploring this is left as an exercise.

Using the model
---------------

### Calculating speaker log odds


    odds <- stylest_odds(mod, novels_excerpts$text, novels_excerpts$author)

We can examine the mean log odds that Jane Austen wrote Pride and
Prejudice.

    # Pride and Prejudice
    novels_excerpts$text[14]
    #> [1] "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife. However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters. \"My dear Mr. Bennet,\" said his lady to him one day, \"have you heard that Netherfield Park is let at last?\" Mr. Bennet replied that he had not. \"But it is,\" returned she; \"for Mrs. Long has just been here, and she told me all about it.\" Mr. Bennet made no answer. \"Do you not want to know who has taken it?\" cried his wife impatiently. \"_You_ want to tell me, and I have no objection to hearing it.\" This was invitation enough."

    odds$log_odds_avg[14]
    #> [1] 0.2491968

    odds$log_odds_se[14]
    #> [1] 0.1290187

### Predicting the speaker of a new text

In this example, the model is used to predict the speaker of a new text,
in this case *Northanger Abbey* by Jane Austen.


    na_text <- "No one who had ever seen Catherine Morland in her infancy would have supposed 
                her born to be an heroine. Her situation in life, the character of her father 
                and mother, her own person and disposition, were all equally against her. Her 
                father was a clergyman, without being neglected, or poor, and a very respectable 
                man, though his name was Richard—and he had never been handsome. He had a 
                considerable independence besides two good livings—and he was not in the least 
                addicted to locking up his daughters."

    pred <- stylest_predict(mod, na_text)

Viewing the result, and recovering the log probabilities calculated for
each speaker, is simple:

    pred$predicted
    #> [1] Austen, Jane
    #> Levels: Austen, Jane Eliot, George Gaskell, Elizabeth Cleghorn

    pred$log_probs
    #> 1 x 3 Matrix of class "dgeMatrix"
    #>      Austen, Jane Eliot, George Gaskell, Elizabeth Cleghorn
    #> [1,]  -1.1956e-05     -42.61985                   -11.33428

### Influential terms

`stylest_term_influence` identifies terms contribute to speakers'
distinctiveness in a fitted model.


    influential_terms <- stylest_term_influence(mod, novels_excerpts$text, novels_excerpts$author)

The terms with the highest mean influence can be obtained:

    head(influential_terms[order(influential_terms$infl_avg, decreasing = TRUE), ])
    #>    term  infl_avg infl_max
    #> 1   the 3.1276856 5.943936
    #> 2    of 1.2237994 1.624485
    #> 10    i 1.1128586 2.445026
    #> 16  was 0.9560661 2.513274
    #> 36  her 0.8214846 2.276707
    #> 15   on 0.8014783 1.868317

And the least influential terms:

    tail(influential_terms[order(influential_terms$infl_avg, decreasing = TRUE), ])
    #>        term   infl_avg   infl_max
    #> 249   taken 0.02133423 0.06211633
    #> 252 thought 0.02133423 0.06211633
    #> 254  turned 0.02133423 0.06211633
    #> 259   whose 0.02133423 0.06211633
    #> 260   woman 0.02133423 0.06211633
    #> 33     from 0.01113619 0.01683299
