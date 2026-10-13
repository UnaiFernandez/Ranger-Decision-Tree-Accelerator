import pandas as pd
import matplotlib.pyplot as plt
import os

# Nombre del archivo CSV generado por la Zybo Z7
CSV_FILENAME = "registro_potencia_zybo.csv"

# Tamaño de la ventana para suavizar (5 muestras = promediar ~0.5 segundos)
# Sube este número si quieres que la gráfica sea todavía más lisa
VENTANA_SUAVIZADO = 200 

def generar_grafico():
    if not os.path.exists(CSV_FILENAME):
        print(f"[ERROR] No se encuentra el archivo '{CSV_FILENAME}' en este directorio.")
        return

    print(f"Cargando datos desde {CSV_FILENAME}...")
    df = pd.read_csv(CSV_FILENAME)
    
    # --- FILTRADO DIGITAL (Media Móvil) ---
    # Esto suaviza el ruido y los dientes de sierra manteniendo la tendencia real
    df["Potencia_Suave_W"] = df["Potencia_W"].rolling(window=VENTANA_SUAVIZADO, center=True, min_periods=1).mean()
    # Rellenar los bordes que quedan vacíos por la ventana con el valor original
    df["Potencia_Suave_W"] = df["Potencia_Suave_W"].fillna(df["Potencia_W"])

    # --- CÁLCULO DE ENERGÍA TOTAL (JULIOS) ---
    # Cada muestra representa ~100ms (0.1 segundos)
    intervalo_segundos = 0.1
    energia_julios = (df["Potencia_W"] * intervalo_segundos).sum()

    # Métricas estadísticas basadas en la señal real
    potencia_max = df["Potencia_W"].max()
    potencia_media = df["Potencia_W"].mean()
    potencia_min = df["Potencia_W"].min()
    
    print("-" * 50)
    print(f"Métricas del Ensayo:")
    print(f"  - Consumo Mínimo (Base):   {potencia_min:.3f} W")
    print(f"  - Consumo Medio:           {potencia_media:.3f} W")
    print(f"  - Pico Máximo Real:        {potencia_max:.3f} W")
    print(f"  - Energía Total Consumida: {energia_julios:.2f} Julios (J)")
    print("-" * 50)

    # Configuración del Gráfico
    plt.figure(figsize=(11, 5.5), dpi=100)
    
    # 1. Dibujar la señal original con ruido (en gris claro y fino para que sirva de fondo)
    plt.plot(df.index, df["Potencia_W"], color="#7f7f7f", linewidth=0.6, alpha=0.4, 
             label="Señal Original (Con Ruido)")
    
    # 2. Dibujar la señal suavizada (Línea principal en azul)
    plt.plot(df.index, df["Potencia_Suave_W"], color="#1f77b4", linewidth=1.8, 
             label=f"Señal Suavizada (Media Móvil n={VENTANA_SUAVIZADO})")

    # Líneas de referencia horizontales
    plt.axhline(y=potencia_max, color="#d62728", linestyle="--", alpha=0.7, 
                label=f"Pico Máximo ({potencia_max:.2f} W)")
    plt.axhline(y=potencia_media, color="#2ca02c", linestyle=":", alpha=0.8, 
                label=f"Consumo Medio ({potencia_media:.2f} W)")

    # Títulos y anotaciones estéticas
    plt.title("Perfil de Consumo Energético Filtrado - Zybo Z7", fontsize=13, fontweight='bold', pad=15)
    plt.xlabel("Tiempo / Muestras (Intervalos de 5ms)", fontsize=11, labelpad=10)
    plt.ylabel("Potencia (Vatios - W)", fontsize=11, labelpad=10)
    
    # Ajustar límites verticales dinámicamente
    plt.ylim(max(0, potencia_min - 0.3), potencia_max + 0.4)

    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="upper left", frameon=True, shadow=True)

    plt.tight_layout()
    print("Mostrando gráfico optimizado...")
    plt.show()

if __name__ == "__main__":
    generar_grafico()
