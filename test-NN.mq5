#include <NN.mqh>

double sigmoide(double v) {
   return 1/(1+MathPow(2.71828, v*-1));
}

double derivada_sigmoide(double v) {
   return sigmoide(v)*(1-sigmoide(v));
}

void OnInit() {
   int estructura[3] = {2, 2, 2};
   matrix matriz{{1,1}, {1, 0}, {0, 1}, {0, 0}};
   matrix resultados{{0, 1}, {1, 0}, {1, 0}, {0, 1}};
   
   RedNeuronal rn(3, estructura, sigmoide, derivada_sigmoide, 1);
   
   rn.entrenar(10000, matriz, resultados);
   
   vector v1{1, 1};
   Print(rn.predecir(v1));
   
   vector v2{1, 0};
   Print(rn.predecir(v2));
   
   vector v3{0, 1};
   Print(rn.predecir(v3));
   
   vector v4{0, 0};
   Print(rn.predecir(v4));
}