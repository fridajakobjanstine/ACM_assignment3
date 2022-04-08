library(pacman)
p_load(tidyverse, patchwork, wesanderson, rcartocolor, cmdstanr, brms, posterior)
schizo <-  read.csv("sc_schizophrenia.csv")

schizo <- schizo[!is.na(schizo$FirstRating),]

d <- schizo %>% mutate(Feedback = OtherRating-FirstRating,
                            Change = SecondRating-FirstRating,
                            Group = ifelse(ID >= 200, "Control", "Sz"))

data <- list(
  N = nrow(d),
  second_rating = d$SecondRating/9,
  first_rating = d$FirstRating/9,
  other_rating = d$OtherRating/9
)


##### SIMPLE #####

file <- file.path("W8_simpleBayes.stan")
mod <- cmdstan_model(file, cpp_options = list(stan_threads = TRUE), pedantic=T)
samples_simple <- mod$sample(
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

# Save model
samples_simple$save_object(file = "weighted.RDS")

samples_simple <- readRDS("samples_simple.RDS")

# Extract and save df
draws_df_simple <- as_draws_df(samples_simple$draws())
write_csv(draws_df_simple, 'draws_df_simple.csv')

samples_simple$summary() 

# Extract and save loo
loo_simple <- samples_simple$loo(save_psis = TRUE, cores = 3)
plot(loo_simple)
write_csv(as.data.frame(loo_simple), 'loo_simple.csv')


# Plotting mcmc trace 
ggplot(draws_df_simple, aes(.iteration, sigma, group=factor(.chain), color=factor(.chain))) + 
  geom_line(alpha=0.85) +
  scale_colour_manual(values=c("#0D4468","#37AAF6"))+
  theme_classic() +
  labs(title="MCMC trace for sigma (simple model)", 
       x='Iterations', 
       y="Sigma",
       color='Chain')


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
  iter_warmup = 1000,
  iter_sampling = 2000,
  refresh = 500,
  max_treedepth = 20,
  adapt_delta = 0.99
)

# Extract and save df
draws_df <- as_draws_df(samples$draws())
write_csv(draws_df, 'draws_df_weighted.csv')

# Save model
samples$save_object(file = "weighted.RDS")

#test_read <- readRDS("weighted.RDS")

# Extract and save loo
loo_weighted <- samples$loo(save_psis = TRUE, cores = 3)
plot(loo_weighted)
write_csv(as.data.frame(loo_weighted), 'loo_weighted.csv')


 # Plotting mcmc trace 
w_w1_mcmc <- ggplot(draws_df, aes(.iteration, w1, group=factor(.chain), color=factor(.chain))) + 
  geom_line(alpha=0.85) +
  scale_colour_manual(values=c("#0D4468","#37AAF6"))+
  theme_classic() +
  labs(title="MCMC trace for weight of first rating", 
       x='Iterations', 
       y="Weight of first rating",
       color='Chain')

w_w2_mcmc <-ggplot(draws_df, aes(.iteration, w2, group=factor(.chain), color=factor(.chain))) + 
  geom_line(alpha=0.85) +
  scale_colour_manual(values=c("#0D4468","#37AAF6"))+
  theme_classic() +
  labs(title="MCMC trace for weight of other's ratings", 
       x='Iterations', 
       y="Weight of other's ratings",
       color='Chain')

w_sigma_mcmc <- ggplot(draws_df, aes(.iteration, sigma, group=factor(.chain), color=factor(.chain))) + 
  geom_line(alpha=0.85) +
  scale_colour_manual(values=c("#0D4468","#37AAF6"))+
  theme_classic() +
  labs(title="MCMC trace for sigma", 
       x='Iterations', 
       y="Sigma",
       color='Chain')

# Create subplot
library(devtools)
library(patchwork)

w_w1_mcmc + w_w2_mcmc + w_sigma_mcmc

#
