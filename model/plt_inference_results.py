import pandas as pd
import matplotlib.pyplot as plt
import os

# Nombre del archivo CSV generado por la Zybo Z7
CSV_FILENAME = "results/registro_potencia_zybo.csv"

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
    plt.xlabel("Tiempo / Muestras (Intervalos de 100ms)", fontsize=11, labelpad=10)
    plt.ylabel("Potencia (Vatios - W)", fontsize=11, labelpad=10)
    
    # Ajustar límites verticales dinámicamente
    plt.ylim(max(0, potencia_min - 0.3), potencia_max + 0.4)

    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="upper left", frameon=True, shadow=True)

    plt.tight_layout()

def plot_simple_csv(csv_path="results/resultado_inferencia.csv"):
    if not os.path.exists(csv_path):
        print(f"[ERROR] No se encontró el archivo: {csv_path}")
        return

    stats_df = pd.read_csv("results/sklearn_max_min.csv")

    max_value = stats_df.loc[0, "max"]
    min_value = stats_df.loc[0, "min"]
    
    # 1. Leer el CSV (detecta automáticamente cabeceras como 'Indice' y 'Valor')
    # Si tu CSV no tiene cabeceras, usamos names=['Indice', 'Valor']
    try:
        df = pd.read_csv(csv_path)
    except Exception as e:
        print(f"[ERROR] Al leer el archivo CSV: {e}")
        return
    try:
        a = pd.read_csv("results/sklearn_results.csv")
    except Exception as e:
        print(f"[ERROR] Al leer el archivo CSV: {e}")
        return

    # Asegurarnos de que las columnas se llamen como esperamos para el script
    # Cambia estos nombres si tus columnas se llaman distinto (ej: 'index', 'hex_val')
    col_indice = df.columns[0]
    col_valor = df.columns[1]

    col_indice_a = a.columns[0]
    col_valor_a = a.columns[1]

    # 2. Convertir los valores Hexadecimales (String) a Decimales (Enteros) para poder graficar
    try:
        # Maneja tanto formatos con '0x' (ej: 0x1A) como limpios (ej: 1A)
        df['Valor_Decimal'] = df[col_valor].astype(str).apply(lambda x: int(x, 16))
    except ValueError as e:
        print(f"[ERROR] No se pudieron convertir algunos valores HEX a decimal: {e}")
        return

    df['Valor_Norm'] = (df['Valor_Decimal'] / 1024) * (max_value - min_value) + min_value 
    #df['Valor_Norm'] = (df['Valor_Decimal'] / 1024) * (58.53 - 17.19) + 17.19 


    # 3. Configurar y crear la gráfica
    plt.figure(figsize=(12, 6))
    
    # Graficar los datos como una línea con marcadores en cada punto
    plt.plot(df[col_indice], df['Valor_Norm'],
             color='#1f77b4',          # Azul analítico
             linestyle='-',            # Línea continua
             marker='o',               # Puntos en cada muestra
             markersize=4,             # Tamaño del punto
             alpha=0.8,                # Ligera transparencia para ver densidad
             label='Salida FPGA')
    
    plt.plot(df[col_indice_a], a[col_valor_a],
             color='#ff7f0e',          # Azul analítico
             linestyle='-',            # Línea continua
             marker='o',               # Puntos en cada muestra
             markersize=4,             # Tamaño del punto
             alpha=0.8,                # Ligera transparencia para ver densidad
             label='Salida sklearn')
    # Estética y etiquetas
    plt.title("Valores de Salida del Acelerador FPGA", fontsize=14, fontweight='bold', pad=15)
    plt.xlabel("Índice de la Muestra", fontsize=11)
    plt.ylabel("Valor Obtenido (Decimal)", fontsize=11)
    
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend(loc='upper right')
    
    # Ajustar márgenes
    plt.tight_layout()

    # 4. Guardar y mostrar
    output_img = "grafica_salidas_fpga.png"
    plt.savefig(output_img, dpi=300)
    print(f"[INFO] Gráfica guardada exitosamente como '{output_img}'")

if __name__ == "__main__":
    plot_simple_csv()
    generar_grafico()
    plt.show()
