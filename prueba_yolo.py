import cv2
from ultralytics import YOLO

# 1. Cargar el modelo pre-entrenado
modelo = YOLO("yolov8n.pt")

# 2. Conectar a la ESP32-CAM
cap = cv2.VideoCapture("http://172.29.94.44:81/stream")

print("Iniciando cámara... Presiona la tecla 'q' en la ventana de video para salir.")

while cap.isOpened():
    exito, frame = cap.read()
    if not exito:
        print("Error: No se pudo acceder a la cámara.")
        break

    # 3. Pasar el frame de video a YOLOv8 para que detecte objetos
    resultados = modelo(frame)

    # 4. Dibujar los recuadros de detección sobre la imagen original
    frame_anotado = resultados[0].plot()

    # 5. Mostrar la ventana con el video en vivo
    cv2.imshow("Prueba YOLOv8 - Baston Inteligente", frame_anotado)

    # 6. Esperar la tecla 'q' para cerrar el programa
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Liberar los recursos del sistema
cap.release()
cv2.destroyAllWindows()