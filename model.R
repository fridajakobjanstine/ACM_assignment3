library(pacman)
p_load(tidyverse, patchwork, wesanderson, rcartocolor, cmdstanr, brms)
schizo <-  read.csv("sc_schizophrenia.csv")

schizo <- schizo[!is.na(schizo$FirstRating),]

d <- schizo %>% mutate(Feedback = OtherRating-FirstRating,
                            Change = SecondRating-FirstRating,
                            Group = ifelse(ID >= 200, "Control", "Sz"))

data <- list(
  N = nrow(d),
  second_rating = d$SecondRating/9,
  first_rating = d$FirstRating/9,
  other_rating = d$OtherRating/9,
  sd1 = sd(d$SecondRating),
  sd_2 = sd(d$SecondRating)/2
)


##### SIMPLE #####

file <- file.path("W8_simpleBayes.stan")
mod <- cmdstan_model(file, cpp_options = list(stan_threads = TRUE), pedantic=T)
samples <- mod$sample(
  data = data,
  # fixed_param = F,
  seed = 123,
  chains = 2,
  parallel_chains = 2,
  threads_per_chain = 2,
  iter_warmup = 1500,
  iter_sampling = 3000,
  refresh = 500,
  max_treedepth = 20,
  adapt_delta = 0.99
)


samples$summary()

draws_df <- as_draws_df(samples$draws())

ggplot(draws_df, aes(.iteration, log_lik, group=.chain, color=.chain)) + geom_line() + theme_classic()



#SimpleBayes_f <- function(source1, source2){
#  outcome <-  inv_logit_scaled(logit_scaled(source1) + logit_scaled(source2))
  
#  return(outcome)
#}





##### WEIGHTED #####


file <- file.path("W8_weightedBayes.stan")
mod <- cmdstan_model(file, cpp_options = list(stan_threads = TRUE), pedantic=T)
samples <- mod$sample(
  data = data,
  # fixed_param = F,
  seed = 123,
  chains = 2,
  parallel_chains = 2,
  threads_per_chain = 2,
  iter_warmup = 1500,
  iter_sampling = 3000,
  refresh = 500,
  max_treedepth = 20,
  adapt_delta = 0.99
)
samples$output(2)
draws_df <- as_draws_df(samples$draws())


#samples$summary()


ggplot(draws_df, aes(.iteration, weight2, group=.chain, color=.chain)) + geom_line() + theme_classic()


