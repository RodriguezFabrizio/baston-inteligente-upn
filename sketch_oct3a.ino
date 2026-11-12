#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// --- Configuración de Wi-Fi y MQTT ---
const char* ssid = "TP-Link_3DEE";
const char* password = "37503116";
const char* mqtt_server = "broker.emqx.io";

WiFiClient espClient;
PubSubClient client(espClient);

// --- Configuración de Pantalla OLED ---
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// --- Pines de los Sensores y Actuadores ---
const int trigPin = 18;
const int echoPin = 19;
const int buzzerPin = 4;   
const int vibratorPin = 23; 

unsigned long lastMsg = 0;
const long interval = 1000;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Conectando a ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi conectado!");
  Serial.print("Dirección IP: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Intentando conexión MQTT...");
    // ID único basado en el chip para evitar rechazos en el broker público
    String clientId = "ESP32BastonClient-";
    clientId += String((uint32_t)ESP.getEfuseMac(), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("¡Conectado al Broker MQTT!");
    } else {
      Serial.print("falló, rc=");
      Serial.print(client.state());
      Serial.println(" reintentando en 5 segundos...");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  pinMode(vibratorPin, OUTPUT);
  
  digitalWrite(buzzerPin, LOW);
  digitalWrite(vibratorPin, LOW);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("Falla al iniciar la pantalla OLED"));
    while(1);
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0,0);
  display.println("Iniciando Baston...");
  display.display();

  setup_wifi();
  client.setServer(mqtt_server, 1883);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Medición de distancia con el HC-SR04
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  int distancia = duration * 0.034 / 2;

  // Actualizar Pantalla OLED
  display.clearDisplay();
  display.setCursor(0,0);
  display.setTextSize(1);
  display.println("--- BASTON INTELIGENTE ---");
  display.setCursor(0,20);
  display.setTextSize(2);
  display.print("Dist: ");
  display.print(distancia);
  display.print("cm");

  // Lógica de Alerta y Actuadores (Tal como la tenías)
  if (distancia > 0 && distancia <= 50) {
    digitalWrite(buzzerPin, LOW);
    digitalWrite(vibratorPin, LOW);
    
    display.setCursor(0, 50);
    display.setTextSize(1);
    display.println("¡PELIGRO CERCA!");
  } else {
    digitalWrite(buzzerPin, HIGH);
    digitalWrite(vibratorPin, HIGH);
  }

  // Envío MQTT
  if (distancia > 0 && distancia <= 100) {
    unsigned long now = millis();
    if (now - lastMsg > interval) {
      lastMsg = now;
      
      String payload = "{\"dispositivo\":\"ESP32_DevKit\",\"distancia_cm\":" + String(distancia) + ",\"alerta\":" + (distancia <= 50 ? "true" : "false") + "}";
      
      if (client.publish("baston/alerta", payload.c_str())) {
        Serial.println("Publicado en MQTT con éxito");
      }
    }
  }

  display.display();
  delay(200); 
}