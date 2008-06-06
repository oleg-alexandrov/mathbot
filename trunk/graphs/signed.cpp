#include <iostream>
#include <fstream>
#include <cmath>
#include <algorithm>
using namespace std;

double f(double, double);

int main (){

  cout << "x" << endl;

}

double f (double x, double y){
  return 60-pow(x, 2.0)-1.2*pow(y, 2.0)-0.006*pow(x-6, 4.0)-0.01*pow(y-5, 4.0);
}
