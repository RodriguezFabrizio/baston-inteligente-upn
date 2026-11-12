#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// --- Configuración de Wi-Fi y MQTT ---
const char* ssid = "Fabu";
const char* password = "nxhq73ikhcujg4u";
const char* mqtt_server = "test.mosquitto.org"; // Broker ultra estable del video
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

// --- Configuración de Pantalla OLED ---
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// --- Pines ---
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
    Serial.print("Intentando conexión MQTT al broker...");
    String clientId = "BastonClient-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println(" ¡Conectado con éxito!");
    } else {
      Serial.print(" falló, rc=");
      Serial.print(client.state());
      Serial.println(" reintentando en 5s...");
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
  client.setServer(mqtt_server, mqtt_port);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Medición HC-SR04
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  int distancia = duration * 0.034 / 2;

  // OLED
  display.clearDisplay();
  display.setCursor(0,0);
  display.setTextSize(1);
  display.println("--- BASTON INTELIGENTE ---");
  display.setCursor(0,20);
  display.setTextSize(2);
  display.print("Dist: ");
  display.print(distancia);
  display.print("cm");

  // Actuadores
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

  // Envío MQTT con tópicos simples directos
  if (distancia > 0 && distancia <= 100) {
    unsigned long now = millis();
    if (now - lastMsg > interval) {
      lastMsg = now;
      
      // Enviamos la distancia en un tópico limpio y corto
      char msg[10];
      sprintf(msg, "%d", distancia);
      
      if (client.publish("baston/distancia", msg)) {
        Serial.print("Enviado al MQTT: ");
        Serial.println(msg);
      }
    }
  }

  display.display();
  delay(200); 
}