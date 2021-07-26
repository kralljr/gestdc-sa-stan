// Bayesian source apportionment model


data {
  
  // Ambient
  int<lower=0> Na;  // Number of observations
  int<lower=0> La;  // Number of sources
  int<lower=0> Pa;  // Number of pollutants
  int<lower=0> Ba;  // Number of free
  matrix<lower=0>[Na, Pa] ya; // Chemical constituent data matrix
  
  
  int<lower=0> LBa; // length of matchamb (all free elements)
  int posra[LBa]; // positions of rows free elements in local
  int posca[LBa]; // positions of column free elements in local
  
  matrix[La, Pa] zeromata; // all constraints
  matrix[La, Pa] onemata; // one constraints
  
  // Local
  int<lower=0> Nl;  // Number of observations
  int<lower=0> Ll;  // Number of sources
  int<lower=0> Pl;  // Number of pollutants (total)
  // Free elements are those free
  int<lower=0> Bl;  // Number of free 
  matrix<lower=0>[Nl, Pl] yl; // Chemical constituent data matrix
  
  
  //int posl[Ll, Bl]; // positions of free elements in local
  matrix[Ll, Pl] zeromatl; // all constraints
  matrix[Ll, Pl] onematl; // one constraints
  

  // matching sources
  int<lower=0> LBl1; // length of free elements not in ambient
  
  int<lower=0> LBl2; // length of matchamb (all free elements)
  int matchamb[LBl2]; // Length of Fl
  int posrl[LBl2]; // positions of rows free elements in local
  int poscl[LBl2]; // positions of column free elements in local

}


transformed data {
  int<lower=0> NPa; // length of y (by row)
  //int<lower=0> LBa; // length of F
  int<lower=0> NLa; // length of G
  vector<lower=0>[Na * Pa] vya;  // Chemical constituent data matrix, column major order
  matrix[La, Pa] Fholda = zeromata + onemata; // F holding matrix to create profiles: 1s and 0s in correct places
  
  int<lower=0> NPl; // length of y (by row)
  //int<lower=0> LBl; // length of F
  int<lower=0> NLl; // length of G
  vector<lower=0>[Nl * Pl] vyl;  // Chemical constituent data matrix, column major order
  matrix[Ll, Pl] Fholdl = zeromatl + onematl; // F holding matrix to create profiles: 1s and 0s in correct places
  
  
  
  NPa = Na * Pa;
  //LBa = La* Ba;
  NLa = Na * La;
  
  vya = to_vector(ya);
  
  

  NPl = Nl * Pl;

  NLl = Nl * Ll;
  
  vyl = to_vector(yl);
}




parameters {
  // Ambient

  matrix[Na, La] lGa; 
  matrix[Nl, Ll] lGl; 
  //row_vector<lower=0>[L] G[N]; // Source contributions
  //matrix[Na, La] lG0a; // Needed for matrix computation
  //matrix<lower=0>[L, B] Fstar; // Scale to 1 source profiles
  vector[LBa] nvFa; // Source profile/ free elements

  
  
  row_vector<lower=0>[La] muga;  // G mean
  row_vector<lower=0>[La] sigmaga; // G SD
  row_vector<lower=0>[Pa] sigmaepsa; // standard deviations
  
  //matrix[Nl, Ll] lG0l; // Needed for matrix computation
  vector[LBl1] nvFl; // Source profile/ free elements not in ambient



  row_vector<lower=0>[Ll] mugl;  // G mean
  row_vector<lower=0>[Ll] sigmagl; // G SD
  row_vector<lower=0>[Pl] sigmaepsl; // standard deviations
  

  vector[LBl2] ndev; //deviations
  vector[LBl2] lam; //inc deviations

}


transformed parameters {
  vector[LBl2] dev; //deviations
    vector[LBl2] sigmadev; //deviations

    matrix<lower=0>[Na, La] Ga; 
      matrix<lower=0>[Nl, Ll] Gl; 

  vector<lower=0>[LBl1] vFl; // Source profile/ free elements
    vector<lower=0>[LBa] vFa; // Source profile/ free elements
    vector<lower=0>[LBa] alpha; // Source profile/ free elements

    for(l in 1 : LBl2) {
        // value of ambient plus deviations
        alpha[l] = vFa[matchamb[l]] + dev[l];
    }
    sigmadev = lam^2 * 0.5^2;
    dev = ndev .* sigmadev;
    

  // Sample F lognormal (Nikolov 2011)
   vFl = exp(nvFl * 0.588 + -0.5);
    vFa = exp(nvFa * 0.588 + -0.5);

  //vF = exp(nvF * 1.8 + -0.5);
    Ga = exp(rep_matrix(muga, Na) + rep_matrix(sqrt(sigmaga), Na) .* lG0a);
  Gl = exp(rep_matrix(mugl, Nl) + rep_matrix(sqrt(sigmagl), Nl) .* lG0l);

}

model {

    // Temp things: to vectors
  //vector[NLa] vGa = (to_vector(lG0a)); // Source contributions
  vector[NPa] Vsigmaepsa = to_vector(rep_matrix(sigmaepsa, Na)); // sigma column order for ly
  
  vector[NPa] meanlya; // Mean column order for ly
  matrix[La, Pa] Fhold1a; 

  // Temp things: to vectors
  //vector[NLl] vGl = (to_vector(lG0l)); // Source contributions
  vector[NPl] Vsigmaepsl = to_vector(rep_matrix(sigmaepsl, Nl)); // sigma column order for ly
  
  vector[NPl] meanlyl; // Mean column order for ly
  matrix[Ll, Pl] Fhold1l; 

  vector[NLa] vGa = (to_vector(lG0a)); // Source contributions
  vector[NLl] vGl = (to_vector(lG0l)); // Source contributions


  int k = 1;


  // Loop over sources, otherwise cannot do matrix on normal
  Fhold1a = Fholda;
  for(b in 1 : LBa) {
      Fhold1a[posra[b], posca[b]] = vFa[b]; // Replace all non-zeros with sampled
  
  }

  Fhold1l = Fholdl;

    // column major order
    for(l in 1 : LBl2) {
        
        // If belongs to ambient
        if(matchamb[l] > 0) {
          
           Fhold1l[posrl[l], poscl[l]] = alpha[l];  // columns iterate slower matchamb[(b-1) * Ll + l]
        // If does not belong to ambient
        } else {
          Fhold1l[posrl[l], poscl[l]] = vFl[k];
          // Add one to k
          k += 1;
        }
      }
      
  //dev ~ cauchy(0, 0.001); // 0.001 is scale of smaller values
  ndev ~ normal(0, 1);
  lam ~ bernoulli(0.2);
  
  nvFa ~ normal(0, 1);
  nvFl ~ normal(0, 1);

    
  sigmaga ~ inv_gamma(0.01, 0.01) ;
  sigmagl ~ inv_gamma(0.01, 0.01) ;
  
  sigmaepsl ~ inv_gamma(0.01, 0.01) ;
  sigmaepsa~ inv_gamma(0.01, 0.01) ;
  
  muga ~ normal(0, 10); // maybe too vague, try sd =5?
  mugl ~ normal(0, 10); // maybe too vague, try sd =5?
  
  // Dist for G
  vGl ~ normal(0, 1);
  vGa ~ normal(0, 1);

  
  // Mean y
  meanlya = to_vector((Ga * Fhold1a));
  // Dist y
  vya ~ normal(meanlya, Vsigmaepsa);
  

        
  // Mean y

  meanlyl = to_vector((Gl * Fhold1l));

  // Dist y
  vyl ~ normal(meanlyl, Vsigmaepsl);
  
  
}


