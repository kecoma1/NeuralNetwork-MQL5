#include <NN.mqh>

double fa(double valor) {
   return valor > 0.5 ? 1 : 0;
}

void OnInit() {
   Neurona n1(fa, true, false);
   Neurona n2(fa, false, false);
   n1.ConectarNeurona(n2);
   n1.setValor(10000);
   Print(n2.getValor());
   n1.disparar();
   n2.disparar();
   Print(n2.getValor());
}