//

functions{
  real weight_f(real L_raw, real w_raw) {
    real L;
    real w;
    L = exp(L_raw);
    w = 0.5 + inv_logit(w_raw)/2;
    return log((w * L + 1 - w)./((1 - w) * L + w));
  }

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
  real weight1;
  real weight2;
  real<lower=0> sigma; 
}

model {
  target += normal_lpdf(weight1 | 0,1);
  target += normal_lpdf(weight2 | 0,1);
  target += normal_lpdf(sigma | 0.3, 0.15) - normal_lccdf(0 | 0.3, 0.15);
  
  for (n in 1:N){  
  target += normal_lpdf(second_rating[n] | weight_f(first_rating[n], weight1) + weight_f(other_rating[n], weight2), sigma);
  
  }
}

generated quantities{
  array[N] real log_lik; 
  array[N] real prior_preds;
  array[N] real post_preds;
  
  real weight1_prior;
  real weight2_prior;
  real w1;
  real w2;
  real w1_prior;
  real w2_prior;
  real sigma_prior;
  
  weight1_prior = normal_rng(0,1);
  weight2_prior = normal_rng(0,1);
  w1_prior = 0.5 + inv_logit(weight1_prior)/2;
  w2_prior = 0.5 + inv_logit(weight2_prior)/2;
  w1 = 0.5 + inv_logit(weight1)/2;
  w2 = 0.5 + inv_logit(weight2)/2;
  sigma_prior = normal_lb_rng(0.3, 0.15, 0);
  
  for (n in 1:N){  
    log_lik[n] = normal_lpdf(second_rating[n] | weight_f(first_rating[n], weight1) + weight_f(other_rating[n], weight2), sigma);
    prior_preds[n] = normal_rng(weight_f(first_rating[n], weight1_prior) + weight_f(other_rating[n], weight2_prior), sigma_prior);
    post_preds[n] = normal_rng(weight_f(first_rating[n], weight1) + weight_f(other_rating[n], weight2), sigma);
  }
  
}

