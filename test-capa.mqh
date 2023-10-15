#include <NN.mqh>

double fa(double valor) {
   return valor > 0.5 ? 1 : 0;
}

void OnInit() {
   Neurona n2(fa, false, false);
   
   // Test capas
   Capa c1(2, fa, true, false);
   c1.conectarNeurona(n2);
   c1.disparar();
   
   Capa c2(2, fa, true, false);
   Capa c3(2, fa, false, true);
   
   c2.conectarCapa(&c3);
   c2.disparar();
   c3.disparar();
}