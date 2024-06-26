class Neurona;
class Conexion;
class Capa;
class RedNeuronal;

// Puntero función
typedef double (*FuncionActivacion)(double);


class RedNeuronal {
   private:
      uint num_capas;
      FuncionActivacion derivada_func;

   public:
      Capa capas[];
      double tasa_aprendizaje;
      
      RedNeuronal(int num_capas, int &neuronas_capas[], FuncionActivacion func, FuncionActivacion derivada_func, double tasa_aprendizaje);
      RedNeuronal(string filename, FuncionActivacion func, FuncionActivacion derivada_fa, double ta);
      void disparar();
      void setEntrada(double &valores[]);
      void backpropagation(vector &salidas_esperadas);
      void calcular_delta_capas_ocultas();
      void calcular_delta_capa_salida(vector &salidas_esperadas);
      void incrementar_pesos();
      vector getSalida();
      vector predecir(vector &valores);
      void entrenar(int epocas, matrix &valores, matrix &salidas_esperadas, bool mostrar_precision_loss = false, double umbral = 0.9, int max_epocas_sin_mejora = 200);
      void guardar(string filename, string estructura);
      void toString();
};

RedNeuronal::RedNeuronal(int nc,int &neuronas_capas[], FuncionActivacion func, FuncionActivacion derivada_fa, double ta) {
   this.num_capas = nc;
   this.derivada_func = derivada_fa;
   this.tasa_aprendizaje = ta;
   
   ArrayResize(this.capas, nc);
   
   for (int i = 0; i < nc; i++)
      this.capas[i].setCapa(neuronas_capas[i], func, i == 0, i == nc-1);
      
   for (int i = 0; i < nc-1; i++)
      this.capas[i].conectarCapa(this.capas[i+1]);
}

RedNeuronal::RedNeuronal(string filename, FuncionActivacion func, FuncionActivacion derivada_fa, double ta) {
   int fh = FileOpen(filename, FILE_ANSI|FILE_COMMON|FILE_READ, "\n");
   if (fh == -1) {
      Print("No se ha cargado el archivo \""+filename+"\" correctamente. Por favor comprueba que está en la carpeta MetaQuoutes/Terminal/Common/Files");
      ExpertRemove();
   }
   
   // Obtenemos el número de capas
   string cabecera = FileReadString(fh);
   string neuronas_capas[];
   StringSplit(cabecera, ',', neuronas_capas);
   
   // Guardamos las capas y las funciones de activación
   int nc = ArraySize(neuronas_capas);
   this.num_capas = nc;
   this.derivada_func = derivada_fa;
   this.tasa_aprendizaje = ta;
   
   ArrayResize(this.capas, nc);
   
   for (int i = 0; i < nc; i++) {
      int num_neuronas = (int)StringToInteger(neuronas_capas[i]);
      this.capas[i].setCapa(num_neuronas, func, i == 0, i == nc-1);
   }
      
   for (int i = 0; i < nc-1; i++)
      this.capas[i].conectarCapa(this.capas[i+1]);
      
   for (int i = 0; i < nc; i++) {
      Capa *capa = &this.capas[i];
      for (int n = 0; n < ArraySize(capa.neuronas); n++) {
         Neurona *neurona = &capa.neuronas[n];
         string fila = FileReadString(fh);
         string split_result[];
         StringSplit(fila, '|', split_result);
         neurona.setPesos(split_result[1]);
      }
   }
   
   FileClose(fh);
}

void RedNeuronal::disparar() {
   for (uint i = 0; i < this.num_capas; i++)
      this.capas[i].disparar();
}

void RedNeuronal::setEntrada(double &valores[]) {
   for (int i = 0; i < ArraySize(valores); i++)
      this.capas[0].neuronas[i].setValor(valores[i]);
}

void RedNeuronal::backpropagation(vector &salidas_esperada) {
   // Computing the output delta
   this.calcular_delta_capa_salida(salidas_esperada);
   
   // Computing the deltas in all the neuronas
   this.calcular_delta_capas_ocultas();
   
   // Incrementing the weights
   this.incrementar_pesos();
}

void RedNeuronal::calcular_delta_capa_salida(vector &salidas_esperadas) {
   Capa *capa_salida = &this.capas[ArraySize(this.capas)-1];
   
   for (int i = 0; i < ArraySize(capa_salida.neuronas); i++) {
      double salida_esperada = salidas_esperadas[i];
      Neurona *neurona_salida = &capa_salida.neuronas[i];
      double salida = neurona_salida.getValor();
      double valor_entrada_salida = neurona_salida.getValorEntradaBackPropagation();
      double valor_derivada = this.derivada_func(valor_entrada_salida);
      double delta_salida = (salida_esperada - salida) * valor_derivada;
      neurona_salida.setDelta(delta_salida);
   }
}

void RedNeuronal::calcular_delta_capas_ocultas() {
   // Staring from the previous of the last one
   // Ending in the second
   for (int i = ArraySize(this.capas)-2; i > 0; i--) {
      Capa *capa = &this.capas[i];
      for (int n = 0; n < ArraySize(capa.neuronas)-1; n++) {
         Neurona *neurona = &capa.neuronas[n];
         
         // Computing the delta of the neurona
         double delta_in = neurona.getDeltaIn();
         double valor_entrada = neurona.getValorEntradaBackPropagation();
         double valor_derivada = this.derivada_func(valor_entrada);
         neurona.setDelta(delta_in*valor_derivada);
      }
   }
}

void RedNeuronal::incrementar_pesos() {
   for (int i = 0; i < ArraySize(this.capas); i++) {
      Capa *capa = &this.capas[i];
      for (int n = 0; n < ArraySize(capa.neuronas); n++) {
         Neurona *neurona = &capa.neuronas[n];
         
         for (int j = 0; j < ArraySize(neurona.conexiones); j++) {
            Conexion *conexion = &neurona.conexiones[j];
            double delta = conexion.getDeltaNeuronaSalida();
            double salida = conexion.getSalidaNeuronaEntrada();
            //Print(conexion.toString(), " --delta-- ", delta, " - entrada - ", salida);
            conexion.incrementarPeso(this.tasa_aprendizaje*delta*salida);
         }
      }
   }
}

vector RedNeuronal::getSalida() {
   Capa *capa_salida = &this.capas[ArraySize(this.capas)-1];
   vector salida(ArraySize(capa_salida.neuronas));

   for (int i = 0; i < ArraySize(capa_salida.neuronas); i++) {
      Neurona *neurona_salida = &capa_salida.neuronas[i];
      salida.Set(i, neurona_salida.getValor());
   }
   
   return salida;
}

vector RedNeuronal::predecir(vector &valores) {
   double array[];
   valores.Swap(array); 
   this.setEntrada(array);
   this.disparar();
   return this.getSalida();
}

void RedNeuronal::entrenar(int epocas, matrix &valores, matrix &salidas_esperadas, bool mostrar_precision_loss = false, double umbral = 0.9, int max_epocas_sin_mejora = 200) {
    double mejor_accuracy = 0.0;
    int epocas_sin_mejora = 0;

    for (int i = 0; i < epocas; i++) {
        double total_loss = 0.0;
        int num_predicciones_correctas = 0;

        for (int n = 0; n < (int)valores.Rows(); n++) {
            vector salidas_esperadas_array = salidas_esperadas.Row(n);
            this.predecir(valores.Row(n));
            this.backpropagation(salidas_esperadas_array);

            if (mostrar_precision_loss) {
               // Calcular el loss
               vector prediccion = this.getSalida();
               for (ulong j = 0; j < prediccion.Size(); j++) {
                  total_loss += pow(salidas_esperadas_array[j] - prediccion[j], 2);
               }

               // Verificar la predicción
               bool es_correcta = true;
               for (ulong j = 0; j < salidas_esperadas_array.Size(); j++) {
                  if (round(salidas_esperadas_array[j]) != round(prediccion[j])) {
                     es_correcta = false;
                     break;
                  }
               }
               if (es_correcta) num_predicciones_correctas++;
            }
        }

         if (mostrar_precision_loss) {
            double loss = total_loss / (valores.Rows() * salidas_esperadas.Cols());
            double accuracy = (double)num_predicciones_correctas / valores.Rows();

            Print("Época ", IntegerToString(i+1), " - Loss: ", DoubleToString(loss), " - Accuracy: ", DoubleToString(accuracy));

            // Verificar si el accuracy ha disminuido
            if (accuracy < mejor_accuracy) {
                  epocas_sin_mejora++;
                  if (epocas_sin_mejora >= max_epocas_sin_mejora) {
                     Print("Deteniendo entrenamiento debido a la disminución del accuracy.");
                     break;
                  }
            } else {
                  mejor_accuracy = accuracy;
                  epocas_sin_mejora = 0;
            }
         } else {
            Print("Época ", IntegerToString(i+1));
         }
    }
}



void RedNeuronal::guardar(string filename, string _estructura) {
   int fh = FileOpen(filename, FILE_WRITE|FILE_COMMON, 0);
   
   // Escribimos la estructura
   FileWrite(fh, _estructura);
   
   // Escribimos la estructura de la RN
   for (uint i = 0; i < this.num_capas; i++) {
      Capa *capa = &this.capas[i];
      for (int n = 0; n < ArraySize(capa.neuronas); n++) {
         Neurona *neurona = &capa.neuronas[n];
         FileWrite(fh, neurona.toString()+"-"+ (neurona.getEsBias() ? "bias" : "normal") +"|"+neurona.getConexionesString());
      } 
   }
   
   FileClose(fh);
}

void RedNeuronal::toString() {
   for (uint i = 0; i < this.num_capas; i++) {
      Capa *capa = &this.capas[i];
      for (int n = 0; n < ArraySize(capa.neuronas); n++) {
         Neurona *neurona = &capa.neuronas[n];
         for (int j = 0; j < ArraySize(neurona.conexiones); j++) {
            Conexion *conexion = &neurona.conexiones[j];
            Print(conexion.toString());
         }
      } 
   }
}


/*********************************************************************************/



class Capa {
   private:
      bool es_capa_entrada;
   
   public:
      Neurona neuronas[];
      
      Capa();
      Capa(int num_neuronas, FuncionActivacion func, bool ece, bool es_capa_salida);
      int getNumNeuronas();
      void setCapa(int num_neuronas,FuncionActivacion func,bool ece,bool es_capa_salida);
      void disparar();
      void conectarCapa(Capa &capa);
      void conectarNeurona(Neurona &neurona);
      void setPesos(string pesos);
};

Capa::Capa() {}

Capa::Capa(int num_neuronas,FuncionActivacion func,bool ece,bool es_capa_salida) {
   ArrayResize(this.neuronas, num_neuronas+(es_capa_salida ? 0 : 1));
   
   // Inicializamos todas las neuronas de la capa
   for (int i = 0; i < num_neuronas; i++)
      this.neuronas[i].setNeurona(func, ece, false);
      
      
   // Inicializamos la bias
   if (!es_capa_salida) this.neuronas[num_neuronas].setNeurona(func, ece, true);
}

int Capa::getNumNeuronas() {
   return ArraySize(this.neuronas) - (this.es_capa_entrada ? 0 : 1);
}

void Capa::setCapa(int num_neuronas,FuncionActivacion func,bool ece,bool es_capa_salida) {
   ArrayResize(this.neuronas, num_neuronas+(es_capa_salida ? 0 : 1));
   
   // Inicializamos todas las neuronas de la capa
   for (int i = 0; i < num_neuronas; i++)
      this.neuronas[i].setNeurona(func, ece, false);
      
      
   // Inicializamos la bias
   if (!es_capa_salida) this.neuronas[num_neuronas].setNeurona(func, ece, true);
}

void Capa::disparar() {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      this.neuronas[i].disparar();
}

void Capa::conectarCapa(Capa &capa) {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      for (int n = 0; n < ArraySize(capa.neuronas); n++)
         if (capa.neuronas[n].getEsBias()) continue;
         else this.neuronas[i].ConectarNeurona(capa.neuronas[n]);
}

void Capa::conectarNeurona(Neurona &neurona) {
   for (int i = 0; i < ArraySize(this.neuronas); i++)
      this.neuronas[i].ConectarNeurona(neurona);
}

void Capa::setPesos(string fila) {
   for (int i = 0; i < ArraySize(this.neuronas); i++) {
      Neurona *neurona = &this.neuronas[i];
   }
}


/*********************************************************************************/


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
      double getDeltaNeuronaSalida();
      double getEntradaNeuronaEntrada();
      double getSalidaNeuronaEntrada();
      void incrementarPeso(double v);
      double getPeso();
      void setPeso(double p);
};

Conexion::Conexion() {
   this.neurona_entrada = NULL;
   this.neurona_salida = NULL;
   this.peso = (MathRand() / 32767.0)-0.5;
}

Conexion::Conexion(Neurona &in,Neurona &out) {
   this.neurona_entrada = &in;
   this.neurona_salida = &out;
   this.peso = (MathRand() / 32767.0)-0.5;
}

void Conexion::setNeuronas(Neurona &in,Neurona &out) {
   this.neurona_entrada = &in;
   this.neurona_salida = &out;
}

void Conexion::disparar() {
   //Print(this.peso, " ", this.neurona_entrada.getValor());
   double resultado = this.peso * this.neurona_entrada.getValor();
   this.neurona_salida.incrementarValorEntrada(resultado);
   //Print(this.neurona_entrada.getValor(), " --- ", this.toString(), " - Resultado - ", resultado);
}

string Conexion::toString() {
   return this.neurona_entrada.toString() + " --(" + DoubleToString(this.peso) + ")--> " + this.neurona_salida.toString();
}

double Conexion::getDeltaNeuronaSalida() {
   return this.neurona_salida.delta;
}

double Conexion::getEntradaNeuronaEntrada() {
   return this.neurona_entrada.valor_entrada_backpropagation;
}

double Conexion::getSalidaNeuronaEntrada() {
   return this.neurona_entrada.getValor();
}

void Conexion::incrementarPeso(double v) {
   //Print("OLD: ", this.peso, " - NEW: ", this.peso+v);
   this.peso += v;
}

double Conexion::getPeso() {
   return this.peso;
}

void Conexion::setPeso(double p) {
   this.peso = p;
}


/*********************************************************************************/


class Neurona {
   private:
      double valor;
      double valor_entrada;
      bool es_bias;
      bool en_capa_entrada;
      FuncionActivacion func;
      uint id;
      
   public:
      static uint neuronas;
      
      // Para back propagation
      double delta;
      double valor_entrada_backpropagation;
      Conexion conexiones[];
      
      Neurona();
      Neurona(FuncionActivacion f, bool en_capa_entrada, bool es_bias);
      void ConectarNeurona(Neurona &neurona);
      //void ConectarCapa(Capa &capa);
      void setNeurona(FuncionActivacion f, bool en_capa_entrada, bool es_bias);
      double getValor();
      bool getEsBias();
      void setValorEntrada(double v);
      void setValor(double v);
      void disparar();
      string toString();
      void toStringConexiones();
      double getValorEntradaBackPropagation();
      void setDelta(double v);
      double getDeltaIn();
      void incrementarValorEntrada(double v);
      string getConexionesString();
      void setPesos(string fila);
};

Neurona::Neurona() {
   neuronas += 1;
   this.id = neuronas;
}

Neurona::Neurona(FuncionActivacion f,bool ece,bool eb) {
   this.valor = 0;
   this.valor_entrada = 0;
   this.func = f;
   this.en_capa_entrada = ece;
   this.es_bias = eb;
   
   neuronas += 1;
   this.id = neuronas;
}

void Neurona::setNeurona(FuncionActivacion f,bool ece,bool eb) {
   this.valor = 0;
   this.valor_entrada = 0;
   this.func = f;
   this.en_capa_entrada = ece;
   this.es_bias = eb;
}

void Neurona::ConectarNeurona(Neurona &neurona) {
   int new_size = ArraySize(this.conexiones) + 1;
   ArrayResize(this.conexiones, new_size);
   
   this.conexiones[new_size-1].setNeuronas(&this, neurona);
}

double Neurona::getValor() {
   return this.valor;
}

bool Neurona::getEsBias() {
   return this.es_bias;
}

void Neurona::setValorEntrada(double v) {
   this.valor_entrada = v;
}

void Neurona::incrementarValorEntrada(double v) {
   this.valor_entrada += v;
}

void Neurona::setValor(double v) {
   this.valor = v;
}

void Neurona::disparar() {
   if (!this.en_capa_entrada) {
      //Print(this.toString(), " - ", this.valor_entrada);
      this.valor = this.func(this.valor_entrada);
      this.valor_entrada_backpropagation = this.valor_entrada;
      this.valor_entrada = 0;
   }
   
   if (this.es_bias) {
      this.valor = 1;
      this.valor_entrada = 1;
      this.valor_entrada_backpropagation = 1;
   }
   
   if (this.en_capa_entrada) {
      this.valor_entrada_backpropagation = this.valor;
      this.valor_entrada = this.valor;
   }
   
   for (int i = 0; i < ArraySize(this.conexiones); i++)
      this.conexiones[i].disparar();
}

string Neurona::toString() {
   string res = "[" + IntegerToString(this.id) + "]";
   return res;
}

double Neurona::getValorEntradaBackPropagation() {
   return this.en_capa_entrada ? this.valor : this.valor_entrada_backpropagation;
}

void Neurona::setDelta(double v) {
   this.delta = v;
}

double Neurona::getDeltaIn() {
   double delta_in = 0;
   for (int i = 0; i < ArraySize(this.conexiones); i++) {
      Conexion *conexion = &this.conexiones[i];
      double delta_siguiente_neurona = conexion.getDeltaNeuronaSalida();
      delta_in += delta_siguiente_neurona*conexion.getPeso();
   }
   
   return delta_in;
}

string Neurona::getConexionesString() {
   int num_conexiones = ArraySize(this.conexiones);
   string data = "";
   for (int i = 0; i < num_conexiones; i++) {
      double peso = this.conexiones[i].getPeso();
      data += (DoubleToString(peso))+(i+1 < num_conexiones ? "," : "");
   }
   
   return num_conexiones > 0 ? data : "salida";
}

void Neurona::setPesos(string fila) {
   string split_result[];
   StringSplit(fila, ',', split_result);
   for (int n = 0; n < ArraySize(this.conexiones); n++) {
      Conexion *conexion = &this.conexiones[n];
      conexion.setPeso(StringToDouble(split_result[n]));
   }
}

uint Neurona::neuronas=0;

// TEST 1
