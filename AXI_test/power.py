import time
import csv
import sys
from datetime import datetime

# Ruta exacta detectada en tu Petalinux (XADC en bus PL / iio:device1)
XADC_PATH = "/sys/bus/iio/devices/iio:device1/in_voltage8_raw"
CSV_FILENAME = "registro_potencia_zybo.csv"

def get_power():
    """Lee el XADC y aplica la fórmula exacta de la Figura 1.4.1 del manual de la Zybo Z7."""
    try:
        with open(XADC_PATH, "r") as f:
            # Petalinux ya nos entrega el valor limpio de 12 bits (X) descartando los 4 bits LSB
            x_raw = int(f.read().strip())
        
        # Fórmula literal de la Figura 1.4.1 para obtener la Corriente (I en Amperios)
        current_amps = (((x_raw * 244.0) / 3900.0) - 0.8) / 52.0
        
        # Evitar corrientes negativas espurias por tolerancias del offset en reposo
        if current_amps < 0:
            current_amps = 0.0
            
        # Potencia total en Vatios (P = V * I) basada en la entrada externa regulada a 5V
        power_watts = 5.0 * current_amps
        
        return x_raw, current_amps, power_watts
    except Exception as e:
        print(f"\n[ERROR] No se pudo leer el XADC: {e}")
        return None

# Inicializar el archivo CSV escribiendo las cabeceras
try:
    with open(CSV_FILENAME, mode="w", newline="") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["Timestamp", "RAW_XADC", "Corriente_A", "Potencia_W"])
except Exception as e:
    print(f"Error al crear el archivo CSV: {e}")
    sys.exit(1)

print("=" * 60)
print(" MONITOR DE ENERGÍA OFICIAL - ZYBO Z7 (Petalinux)")
print("=" * 60)
print(f" Guardando datos en: {CSV_FILENAME}")
print(" Presiona Ctrl+C para finalizar la captura.")
print("-" * 60)
print(f"{'Tiempo':<12}{'RAW (X)':<10}{'Corriente (A)':<16}{'Potencia (W)':<15}")
print("-" * 60)

max_watts = 0.0
total_lecturas = 0
i = 0

try:
    while True:
        datos = get_power()
        if datos:
            raw, amps, watts = datos
            ahora = datetime.now().strftime("%H:%M:%S.%f")[:-3] # Formato HH:MM:SS.mmm
            
            # Registrar el pico máximo de potencia alcanzado
            if watts > max_watts:
                max_watts = watts
                
            # Imprimir en la terminal (sobreescribiendo la línea en tiempo real)
            sys.stdout.write(f"\r{ahora:<12}{raw:<10}{amps:<16.3f}{watts:<15.3f}")
            sys.stdout.flush()
            
            # Guardado inmediato en el archivo CSV
            with open(CSV_FILENAME, mode="a", newline="") as csv_file:
                writer = csv.writer(csv_file)
                writer.writerow([ahora, raw, round(amps, 4), round(watts, 4)])
                
            total_lecturas += 1
            
        # Muestreo cada 10ms (100 veces por segundo) para mantener la CPU al 0%
        time.sleep(0.005)

except KeyboardInterrupt:
    print("\n" + "-" * 60)
    print(" Monitorización detenida por el usuario.")
    print(f" Total de muestras guardadas en CSV: {total_lecturas}")
    print(f" Pico de potencia máximo registrado: {max_watts:.3f} W")
    print("=" * 60)

