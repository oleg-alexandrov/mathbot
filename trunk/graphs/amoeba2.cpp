#include <iostream>
#include <fstream>
#include <cmath>
#include <algorithm>
#include<complex>
using namespace std;

double small = 1e-14;
double mylog (double); 
int main(){

  complex<double> z2, root, z11, z12;
  double A=-5, B=5, x, y, h, a1, a2, b;
  int N=1000, i, j;

  double R, pi, r, theta0, theta;

  h= (B-A)/(N-1);
  theta0 = 2*M_PI/(N-1.0);

  ofstream mfile ("data.txt");
  
  for (i=0 ; i < N ; i++){
    r = exp(A+i*h); 

    for (j=0 ; j < N ; j++){
      theta = j*theta0;

      z2 = r*complex<double>(cos(theta), sin(theta));
      root = sqrt(25.0*z2*z2-12.0*(z2*z2*z2+1.0));
      z11 = (-5.0*z2+root)/6.0;
      z12 = (-5.0*z2-root)/6.0;

      a1 = mylog(abs(z11));
      a2 = mylog(abs(z12));
      b  = mylog(abs(z2));

      
      mfile << a1  << ' ' << b << endl;
      mfile << a2  << ' ' << b << endl;
    }
  }

  mfile.close();
}

double mylog (double x){

  if (x< 0){
    cout << "Error in log, negative x!" << endl;
    exit(0);
  }

  if (x < small){
    return log (small);
  }

  return log (x);

}
