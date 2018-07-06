library(stylest)

test_that("invalid nfolds raises error", {
  expect_error(stylest_select_vocab(novels_excerpts, novels_excerpts$author, nfold = 0),
               "nfolds must be at least 1")
  expect_error(stylest_select_vocab(novels_excerpts, novels_excerpts$author, nfold = 0.5),
               "nfold must be an integer value")
  }
)

test_that("invalid smooth raises error", {
  expect_error(stylest_select_vocab(novels_excerpts, novels_excerpts$author, smooth = -1),
               "smooth value must be greater than or equal to 0")
}
)

test_that("invalid cutoff pct raises error", {
  expect_error(stylest_select_vocab(novels_excerpts, novels_excerpts$author, cutoff_pcts = c(-50, 100)),
               "cutoff percent must be value between 0 and 100")
}
)
