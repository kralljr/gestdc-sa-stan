// Bayesian source apportionment model

data {
  int<lower=0> N;  // Number of observations
  int<lower=0> L;  // Number of sources
  int<lower=0> P;  // Number of pollutants
  int<lower=0> B;  // Number of free
  matrix[N, P] y;  // Chemical constituent data matrix
  
  
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
  
  NP = N * P;
  NL = N * L;
  
  vy = to_vector(y);
}



parameters {
  
  matrix[N, L] lG0; // Needed for matrix computation

  
  vector[LB] nvF; // Source profile/ free elements
  
  
  
  row_vector[L] mug;  // G mean
  row_vector<lower=0>[L] sigmag; // G variances
  row_vector<lower=0>[P] sigmaeps; // variances
}



transformed parameters {
  matrix<lower=0>[N, L] G; 
  vector<lower=0>[LB] vF; // Source profile/ free elements
  
  // Sample F lognormal (Nikolov 2011)
   vF = exp(nvF * 0.767  + -0.5);
  //vF = exp(nvF * 1.8 + -0.5);
  
  // G lognormalm lG0 normal
  G = exp(rep_matrix(mug, N) + rep_matrix(sqrt(sigmag), N) .* lG0);

}




model {
  // Temp things: to vectors
  vector[NL] vG = (to_vector(lG0)); // Source contributions
  vector[NP] Vsigmaeps = sqrt(to_vector(rep_matrix(sigmaeps, N))); // sigma column order for ly
  
  vector[NP] meanly; // Mean column order for ly
  matrix[L, P] Fhold1; 

  // Loop over sources, otherwise cannot do matrix on normal
  Fhold1 = Fhold;
  for(b in 1 : LB) {
      Fhold1[posr[b], posc[b]] = vF[b]; // Replace all non-zeros with sampled
    
  }
  
  
  nvF ~ normal(0, 1);
  
  
  
// Gelman 2006 Bayesian analysis ?

//    sigmag ~ inv_gamma(0.01, 0.01) ;
//  sigmaeps ~ inv_gamma(0.01, 0.01) ;
  
  sigmag ~ normal(0, 10) ;
  sigmaeps ~ normal(0, 10) ;
  
  mug ~ normal(0, 3.16); // maybe too vague, try sd =5?

  
  // Dist for G
  vG ~ normal(0, 1);
  
  // Mean y
  meanly = to_vector((G * Fhold1));
  // Dist y
  //vy ~ lognormal(meanly, Vsigmaeps);
  vy ~ normal(meanly, Vsigmaeps);

}


