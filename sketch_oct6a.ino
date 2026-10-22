#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// Dimensiones de tu pantalla OLED
#define ANCHO_PANTALLA 128
#define ALTO_PANTALLA 64

// Crear el objeto para la pantalla
Adafruit_SSD1306 display(ANCHO_PANTALLA, ALTO_PANTALLA, &Wire, -1);

void setup() {
  Serial.begin(115200);
  
  // Forzar explícitamente los pines que acabas de soldar (SDA=21, SCL=22)
  Wire.begin(21, 22);

  // Iniciar la pantalla en la dirección estándar 0x3C
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("ERROR: Pantalla OLED no encontrada. Revisa los puentes de estaño.");
    while(true); // Se detiene aquí si no la encuentra
  }

  // Limpiar la memoria de la pantalla
  display.clearDisplay();

  // Configurar el texto de éxito
  display.setTextSize(2);      // Tamaño de letra grande
  display.setTextColor(SSD1306_WHITE); // Color del texto
  display.setCursor(10, 20);   // Posición (X, Y)
  display.println("OLED OK!");
  
  display.setTextSize(1);      // Tamaño de letra pequeño
  display.setCursor(10, 45);
  display.println("Baston Inteligente");
  
  // ¡El comando más importante! Envía la imagen a la pantalla
  display.display(); 
  
  Serial.println("¡Señal enviada a la pantalla con éxito!");
}

void loop() {
  // Para esta prueba inicial no necesitamos que haga nada en bucle
}