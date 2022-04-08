//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// Learn more about model development with Stan at:
//
//    http://mc-stan.org/users/interfaces/rstan.html
//    https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started
//

functions{
  real normal_lb_rng(real mu, real sigma, real lb) {
    real p = normal_cdf(lb | mu, sigma);  // cdf for bounds
    real u = uniform_rng(p, 1);
    return (sigma * inv_Phi(u)) + mu;  // inverse cdf for value
  }
}

data {
  int<lower=0> N;
  vector[N] second_rating;
  vector[N] first_rating;
  vector[N] other_rating;
}

parameters {
  real<lower=0> sigma; 
}

model {
  target += normal_lpdf(sigma | 0.3, 0.15) - normal_lccdf(0 | 0.3, 0.15);
  for (n in 1:N){  
  target += normal_lpdf(second_rating[n] | logit(first_rating[n]) + logit(other_rating[n]), sigma);
  } 
}

generated quantities{
  array[N] real log_lik; 
  array[N] real prior_preds;
  array[N] real post_preds;
  
  real sigma_prior;
  
  sigma_prior = normal_lb_rng(0.3, 0.15, 0);
  
  for (n in 1:N){  
    log_lik[n] = normal_lpdf(second_rating[n] | logit(first_rating[n]) + logit(other_rating[n]), sigma);
    prior_preds[n] = normal_rng(logit(first_rating[n]) + logit(other_rating[n]), sigma_prior);
    post_preds[n] = normal_rng(logit(first_rating[n]) + logit(other_rating[n]), sigma);
  }
}

