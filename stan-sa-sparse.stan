// Bayesian source apportionment model

data {
  int<lower=0> N;  // Number of observations
  int<lower=0> L;  // Number of sources
  int<lower=0> P;  // Number of pollutants
  int<lower=0> B;  // Number of free
  matrix[N, P] y;  // Chemical constituent data matrix
  matrix[N, P] x;  // X: indicator for location 1 vs. 2
  
  
  //int pos[L, B]; // positions of free elements
  matrix[L, P] zeromat; // all constraints
  matrix[L, P] onemat; // one constraints
  
  int<lower=0> LB; // length of matchamb (all free elements)
  int posr[LB]; // positions of rows free elements in local
  int posc[LB]; // positions of column free elements in local
}



transformed data {
  int<lower=0> NP; // length of y (by row)
  int<lower=0> NL; // length of G
  vector[N * P] vy;  // Chemical constituent data matrix, column major order
  matrix[L, P] Fhold = zeromat + onemat; // F holding matrix to create profiles: 1s and 0s in correct places
  matrix[N, P] x1 = 1 - x;  
  NP = N * P;
  NL = N * L;
  
  vy = to_vector(y);
}



parameters {
  

  matrix[N, L] G; 
  
  vector[LB] nvF; // Source profile/ free elements
  
  
  
  row_vector<lower=0>[L] mug0;  // G mean
  row_vector<lower=0>[L] sigmag0; // G SD
  row_vector<lower=0>[L] mug1;  // G mean
  row_vector<lower=0>[L] sigmag1; // G SD
  row_vector<lower=0>[P] sigmaeps0; // standard deviations
  row_vector<lower=0>[P] sigmaeps1; // standard deviations

}



transformed parameters {
    vector<lower=0>[LB] vF; // Source profile/ free elements
  

  matrix<lower=0>[N, L] mug; 
  matrix<lower=0>[N, L] sigmag; 
  matrix<lower=0>[N, P] sigmaeps; 

  mug = rep_matrix(mug0, N) .* x1 + rep_matrix(mug1, N) .* x;
  sigmag = rep_matrix(sigmag0, N) .* x1 + rep_matrix(sigmag1, N) .* x;
  sigmaeps = rep_matrix(sigmaeps0, N) .* x1 + rep_matrix(sigmaeps1, N) .* x;
  // Sample F lognormal (Nikolov 2011)
  vF = exp(nvF * 0.588 + -0.5);
}

model {
  // Temp things: to vectors
  vector[NP] Vsigmaeps = to_vector(sigmaeps); // sigma column order for ly

  vector[NP] meanly; // Mean column order for ly
  matrix[L, P] Fhold1; 

  // Loop over sources, otherwise cannot do matrix on normal
  Fhold1 = Fhold;
  for(b in 1 : LB) {
      Fhold1[posr[b], posc[b]] = vF[b]; // Replace all non-zeros with sampled
    
  }
  
  
  // Sample half cauchy: 
  //https://github.com/stan-dev/stan/wiki/Prior-Choice-Recommendations
  nvF ~ normal(0, 1);

  sigmag1 ~ inv_gamma(0.01, 0.01) ;
  sigmaeps1 ~ inv_gamma(0.01, 0.01) ;
  sigmag0 ~ inv_gamma(0.01, 0.01) ;
  sigmaeps0 ~ inv_gamma(0.01, 0.01) ;
  
  
  
  for(l in 1 : L) {
    mug0[l] ~ normal(2, 5) T[0,];
    mug1[l] ~ normal(2, 5) T[0,];

    for(n in 1 : N) {

          G[n,l] ~ normal(mug[n, l], sigmag[n, l]);
      
    }
  }
  
  // Dist for G
  //vG ~ normal(0, 1);
  
  // Mean y
  meanly = to_vector((G * Fhold1));
  // Dist y
  //vy ~ lognormal(meanly, Vsigmaeps);
  vy ~ normal(meanly, Vsigmaeps);

}


