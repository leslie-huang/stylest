library(stylest)

test_that("invalid smooth raises error", {
  expect_error(stylest_select_vocab(novels_excerpts, novels_excerpts$author, smooth = -1),
               "smooth value must be greater than or equal to 0")
}
)