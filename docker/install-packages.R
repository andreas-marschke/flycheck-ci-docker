dir.create(Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)
install.packages("lintr", Sys.getenv("R_LIBS_USER"), repos="http://cran.case.edu")