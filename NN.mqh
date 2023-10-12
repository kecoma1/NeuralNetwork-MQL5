class Neurona;
class Conexion;

// Puntero función
typedef double (*FuncionActivacion)(double);

class Conexion {
   private:
      Neurona *neurona_entrada;
      Neurona *neurona_salida;
      double peso;
      
   public:
      Conexion();
      Conexion(Neurona &in, Neurona &out);
      void setNeuronas(Neurona &in, Neurona &out);
      void disparar();
      string toString();
};

Conexion::Conexion() {
   this.neurona_entrada = NULL;
   this.neurona_salida = NULL;
   this.peso = MathRand() / 32767.0;
}

Conexion::Conexion(Neurona &in,Neurona &out) {
   this.neurona_entrada = &in;
   this.neurona_salida = &out;
   this.peso = MathRand() / 32767.0;
}

void Conexion::setNeuronas(Neurona &in,Neurona &out) {
   this.neurona_entrada = &in;
   this.neurona_salida = &out;
}

void Conexion::disparar() {
   Print(this.peso, " ", this.neurona_entrada.getValor());
   double resultado = this.peso * this.neurona_entrada.getValor();
   this.neurona_salida.setValorEntrada(resultado);
}

string Conexion::toString() {
   return this.neurona_entrada.toString() + " --(" + DoubleToString(this.peso) + ")--> " + this.neurona_salida.toString();
}

class Neurona {
   private:
      double valor;
      double valor_entrada;
      bool es_bias;
      bool en_capa_entrada;
      Conexion conexiones[];
      FuncionActivacion func;
      uint id;
      
   public:
      static uint neuronas;
      
      Neurona(FuncionActivacion f, bool en_capa_entrada, bool es_bias);
      void ConectarNeurona(Neurona &neurona);
      //void ConectarCapa(Capa &capa);
      double getValor();
      void setValorEntrada(double v);
      void setValor(double v);
      void disparar();
      string toString();
      void toStringConexiones();
};

Neurona::Neurona(FuncionActivacion f,bool ece,bool eb) {
   this.valor = 0;
   this.valor_entrada = 0;
   this.func = f;
   this.en_capa_entrada = ece;
   this.es_bias = eb;
   
   neuronas += 1;
   this.id = neuronas;
}

void Neurona::ConectarNeurona(Neurona &neurona) {
   int new_size = ArraySize(this.conexiones) + 1;
   ArrayResize(this.conexiones, new_size);
   
   this.conexiones[new_size-1].setNeuronas(&this, neurona);
}

double Neurona::getValor() {
   return this.valor;
}

void Neurona::setValorEntrada(double v) {
   this.valor_entrada = v;
}

void Neurona::setValor(double v) {
   this.valor = v;
}

void Neurona::disparar() {
   if (!this.en_capa_entrada) {
      this.valor = this.func(this.valor_entrada);
      this.valor_entrada = 0;
   }
   
   if (this.es_bias) this.valor = 1;
   
   for (int i = 0; i < ArraySize(this.conexiones); i++)
      this.conexiones[i].disparar();
}

string Neurona::toString() {
   string res = "[" + IntegerToString(this.id) + "]";
   return res;
}

uint Neurona::neuronas=0;

// TEST 1
