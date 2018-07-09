About `stylest`
===============

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
full texts of novels available on Project Gutenberg:
<http://gutenberg.org>.

    data(novels_excerpts)

<table class="table table-striped table-hover" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:left;">
title
</th>
<th style="text-align:left;">
author
</th>
<th style="text-align:left;">
text
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
A Dark Night's Work
</td>
<td style="text-align:left;">
Gaskell, Elizabeth Cleghorn
</td>
<td style="text-align:left;">
In the county town of a certain shire there lived (about forty years
ago) one Mr. Wilkins, a conveyancing attorney of considerable standing.
The certain shire was but a small county, and the principal town in it
contained only about four thousand inhabitants; so in saying that Mr.
Wilkins was the principal lawyer in Hamley, I say very little, unless I
add that he transacted all the legal business of the gentry for twenty
miles round. His grandfather had established the connection; his father
had consolidated and strengthened it, and, indeed, by his wise and
upright conduct, as well as by his professional skill, had obtained for
himself the position of confidential friend to many of the surrounding
families of distinction.
</td>
</tr>
<tr>
<td style="text-align:left;">
4
</td>
<td style="text-align:left;">
Brother Jacob
</td>
<td style="text-align:left;">
Eliot, George
</td>
<td style="text-align:left;">
Among the many fatalities attending the bloom of young desire, that of
blindly taking to the confectionery line has not, perhaps, been
sufficiently considered. How is the son of a British yeoman, who has
been fed principally on salt pork and yeast dumplings, to know that
there is satiety for the human stomach even in a paradise of glass jars
full of sugared almonds and pink lozenges, and that the tedium of life
can reach a pitch where plum-buns at discretion cease to offer the
slightest excitement? Or how, at the tender age when a confectioner
seems to him a very prince whom all the world must envy--who breakfasts
on macaroons, dines on meringues, sups on twelfth-cake, and fills up the
intermediate hours with sugar-candy or peppermint--how is he to foresee
the day of sad wisdom, when he will discern that the confectioner's
calling is not socially influential, or favourable to a soaring
ambition?
</td>
</tr>
<tr>
<td style="text-align:left;">
8
</td>
<td style="text-align:left;">
Emma
</td>
<td style="text-align:left;">
Austen, Jane
</td>
<td style="text-align:left;">
Emma Woodhouse, handsome, clever, and rich, with a comfortable home and
happy disposition, seemed to unite some of the best blessings of
existence; and had lived nearly twenty-one years in the world with very
little to distress or vex her. She was the youngest of the two daughters
of a most affectionate, indulgent father; and had, in consequence of her
sister's marriage, been mistress of his house from a very early period.
Her mother had died too long ago for her to have more than an indistinct
remembrance of her caresses; and her place had been supplied by an
excellent woman as governess, who had fallen little short of a mother in
affection. Sixteen years had Miss Taylor been in Mr. Woodhouse's family,
less as a governess than a friend, very fond of both daughters, but
particularly of Emma. Between *them* it was more the intimacy of
sisters.
</td>
</tr>
</tbody>
</table>
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

We can examine the mean log odds that Jane Austen wrote *Pride and
Prejudice* (in-sample).

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

Note that a `prior` may be specified, and may be useful for handling
texts containing out-of-sample terms. Here, we do not specify a prior,
so a uniform prior is used.


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

`stylest_term_influence` identifies terms' contributions to speakers'
distinctiveness in a fitted model.


    influential_terms <- stylest_term_influence(mod, novels_excerpts$text, novels_excerpts$author)

The mean and maximum influence can be accessed with `$infl_avg` and
`$infl_max`, respectively.

The terms with the highest mean influence can be obtained:

<table class="table table-striped table-hover" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:left;">
term
</th>
<th style="text-align:right;">
infl\_avg
</th>
<th style="text-align:right;">
infl\_max
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
the
</td>
<td style="text-align:right;">
3.1276856
</td>
<td style="text-align:right;">
5.943936
</td>
</tr>
<tr>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
of
</td>
<td style="text-align:right;">
1.2237994
</td>
<td style="text-align:right;">
1.624485
</td>
</tr>
<tr>
<td style="text-align:left;">
10
</td>
<td style="text-align:left;">
i
</td>
<td style="text-align:right;">
1.1128586
</td>
<td style="text-align:right;">
2.445026
</td>
</tr>
<tr>
<td style="text-align:left;">
16
</td>
<td style="text-align:left;">
was
</td>
<td style="text-align:right;">
0.9560661
</td>
<td style="text-align:right;">
2.513274
</td>
</tr>
<tr>
<td style="text-align:left;">
36
</td>
<td style="text-align:left;">
her
</td>
<td style="text-align:right;">
0.8214846
</td>
<td style="text-align:right;">
2.276707
</td>
</tr>
<tr>
<td style="text-align:left;">
15
</td>
<td style="text-align:left;">
on
</td>
<td style="text-align:right;">
0.8014783
</td>
<td style="text-align:right;">
1.868317
</td>
</tr>
</tbody>
</table>
And the least influential terms:

<table class="table table-striped table-hover" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:left;">
term
</th>
<th style="text-align:right;">
infl\_avg
</th>
<th style="text-align:right;">
infl\_max
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
249
</td>
<td style="text-align:left;">
taken
</td>
<td style="text-align:right;">
0.0213342
</td>
<td style="text-align:right;">
0.0621163
</td>
</tr>
<tr>
<td style="text-align:left;">
252
</td>
<td style="text-align:left;">
thought
</td>
<td style="text-align:right;">
0.0213342
</td>
<td style="text-align:right;">
0.0621163
</td>
</tr>
<tr>
<td style="text-align:left;">
254
</td>
<td style="text-align:left;">
turned
</td>
<td style="text-align:right;">
0.0213342
</td>
<td style="text-align:right;">
0.0621163
</td>
</tr>
<tr>
<td style="text-align:left;">
259
</td>
<td style="text-align:left;">
whose
</td>
<td style="text-align:right;">
0.0213342
</td>
<td style="text-align:right;">
0.0621163
</td>
</tr>
<tr>
<td style="text-align:left;">
260
</td>
<td style="text-align:left;">
woman
</td>
<td style="text-align:right;">
0.0213342
</td>
<td style="text-align:right;">
0.0621163
</td>
</tr>
<tr>
<td style="text-align:left;">
33
</td>
<td style="text-align:left;">
from
</td>
<td style="text-align:right;">
0.0111362
</td>
<td style="text-align:right;">
0.0168330
</td>
</tr>
</tbody>
</table>
Issues
------

Please submit any bugs, error reports, etc. on GitHub at:
<https://github.com/leslie-huang/stylest/issues>.
