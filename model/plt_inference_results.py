import pandas as pd
import matplotlib.pyplot as plt
import os
import glob
import sys

# =====================================================================
# CONFIGURACIÓN GLOBAL
# =====================================================================
VENTANA_SUAVIZADO = 200 
INTERVALO_SEGUNDOS = 0.1

# =====================================================================
# FUNCIONES AUXILIARES DE GESTIÓN DE ARCHIVOS
# =====================================================================
def buscar_archivo_por_patron(base_dir, palabra_clave):
    """
    Busca un archivo dentro de base_dir/results/ que contenga la 'palabra_clave'.
    Si encuentra varios (de distintas horas), devuelve el más reciente.
    """
    patron = os.path.join(base_dir, f"*{palabra_clave}*.csv")
    archivos_encontrados = glob.glob(patron)
    
    if not archivos_encontrados:
        return None
    
    # Ordenar por fecha de modificación y devolver el último (más reciente)
    archivos_encontrados.sort(key=os.path.getmtime)
    return archivos_encontrados[-1]

# =====================================================================
# FUNCIONES PRINCIPALES DE PROCESAMIENTO Y GRÁFICOS
# =====================================================================
def generar_grafico_potencia(base_dir):
    """Carga y grafica el registro de potencia de un test específico."""
    csv_filename = buscar_archivo_por_patron(base_dir, "registro_potencia")
    
    if not csv_filename:
        print(f"[ERROR] No se encontró ningún archivo de potencia (*registro_potencia*) en '{base_dir}/results/'")
        return

    print(f"\n[POTENCIA] Cargando datos desde: {os.path.basename(csv_filename)}...")
    df = pd.read_csv(csv_filename)
    
    # --- FILTRADO DIGITAL (Media Móvil) ---
    df["Potencia_Suave_W"] = df["Potencia_W"].rolling(window=VENTANA_SUAVIZADO, center=True, min_periods=1).mean()
    df["Potencia_Suave_W"] = df["Potencia_Suave_W"].fillna(df["Potencia_W"])

    # --- CÁLCULO DE ENERGÍA TOTAL (JULIOS) ---
    energia_julios = (df["Potencia_W"] * INTERVALO_SEGUNDOS).sum()

    # Métricas estadísticas basadas en la señal real
    potencia_max = df["Potencia_W"].max()
    potencia_media = df["Potencia_W"].mean()
    potencia_min = df["Potencia_W"].min()
    
    print("-" * 50)
    print(f"Métricas del Ensayo ({base_dir}):")
    print(f"  - Consumo Mínimo (Base):   {potencia_min:.3f} W")
    print(f"  - Consumo Medio:           {potencia_media:.3f} W")
    print(f"  - Pico Máximo Real:        {potencia_max:.3f} W")
    print(f"  - Energía Total Consumida: {energia_julios:.2f} Julios (J)")
    print("-" * 50)

    # Configuración del Gráfico
    plt.figure(figsize=(11, 5.5), dpi=100)
    
    plt.plot(df.index, df["Potencia_W"], color="#7f7f7f", linewidth=0.6, alpha=0.4, 
             label="Señal Original (Con Ruido)")
    
    plt.plot(df.index, df["Potencia_Suave_W"], color="#1f77b4", linewidth=1.8, 
             label=f"Señal Suavizada (Media Móvil n={VENTANA_SUAVIZADO})")

    plt.axhline(y=potencia_max, color="#d62728", linestyle="--", alpha=0.7, 
                label=f"Pico Máximo ({potencia_max:.2f} W)")
    plt.axhline(y=potencia_media, color="#2ca02c", linestyle=":", alpha=0.8, 
                label=f"Consumo Medio ({potencia_media:.2f} W)")

    plt.title(f"Perfil de Consumo Energético Filtrado - {base_dir}", fontsize=13, fontweight='bold', pad=15)
    plt.xlabel("Tiempo / Muestras (Intervalos de 100ms)", fontsize=11, labelpad=10)
    plt.ylabel("Potencia (Vatios - W)", fontsize=11, labelpad=10)
    
    plt.ylim(max(0, potencia_min - 0.3), potencia_max + 0.4)
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="upper left", frameon=True, shadow=True)
    plt.tight_layout()
    
    # Guardar el gráfico dentro de la carpeta del test correspondiente
    output_potencia = os.path.join(base_dir, "grafica_perfil_potencia.png")
    plt.savefig(output_potencia, dpi=300)
    print(f"[INFO] Gráfica de potencia guardada en '{output_potencia}'")


def plot_inferencia_fpga(base_dir):
    """Compara las salidas de la FPGA frente a sklearn buscando archivos dinámicamente."""
    csv_inferencia = buscar_archivo_por_patron(base_dir, "resultado_inferencia")
    csv_stats = buscar_archivo_por_patron(base_dir, "sklearn_max_min")
    csv_sklearn = buscar_archivo_por_patron(base_dir, "sklearn_results")

    # Validar que existan todos los archivos necesarios antes de procesar
    if not all([csv_inferencia, csv_stats, csv_sklearn]):
        print(f"[ERROR] Faltan archivos críticos en '{base_dir}/results/' para la inferencia.")
        print(f"  - Inferencia: {'Detectado' if csv_inferencia else 'FALTA'}")
        print(f"  - Stats:      {'Detectado' if csv_stats else 'FALTA'}")
        print(f"  - Sklearn:    {'Detectado' if csv_sklearn else 'FALTA'}")
        return

    print(f"\n[INFERENCIA] Cargando archivos dinámicos de {base_dir}...")
    try:
        df_fpga = pd.read_csv(csv_inferencia)
        df_stats = pd.read_csv(csv_stats)
        df_sklearn = pd.read_csv(csv_sklearn)
    except Exception as e:
        print(f"[ERROR] Al leer los archivos CSV de inferencia: {e}")
        return

    max_value = df_stats.loc[0, "max"]
    min_value = df_stats.loc[0, "min"]
    
    # Obtener nombres de columnas dinámicamente
    col_indice_fpga = df_fpga.columns[0]
    col_valor_fpga = df_fpga.columns[1]

    col_indice_sk = df_sklearn.columns[0]
    col_valor_sk = df_sklearn.columns[1]

    # Convertir Hexadecimal a Decimal para graficar
    try:
        df_fpga['Valor_Decimal'] = df_fpga[col_valor_fpga].astype(str).apply(lambda x: int(x, 16))
    except ValueError as e:
        print(f"[ERROR] No se pudieron convertir algunos valores HEX a decimal: {e}")
        return

    # Normalización
    df_fpga['Valor_Norm'] = (df_fpga['Valor_Decimal'] / 1024) * (max_value - min_value) + min_value 

    # Configuración de la Gráfica
    plt.figure(figsize=(12, 6))
    
    plt.plot(df_fpga[col_indice_fpga], df_fpga['Valor_Norm'],
             color='#1f77b4', linestyle='-', marker='o', markersize=4, alpha=0.8, 
             label='Salida FPGA')
    
    plt.plot(df_sklearn[col_indice_sk], df_sklearn[col_valor_sk],
             color='#ff7f0e', linestyle='-', marker='o', markersize=4, alpha=0.8, 
             label='Salida sklearn')
    
    plt.title(f"Valores de Salida del Acelerador FPGA vs Sklearn - {base_dir}", fontsize=14, fontweight='bold', pad=15)
    plt.xlabel("Índice de la Muestra", fontsize=11)
    plt.ylabel("Valor Obtenido (Decimal)", fontsize=11)
    
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend(loc='upper right')
    plt.tight_layout()

    # Guardar el gráfico dentro de la carpeta del test correspondiente
    output_img = os.path.join(base_dir, "grafica_salidas_fpga.png")
    plt.savefig(output_img, dpi=300)
    print(f"[INFO] Gráfica de inferencia guardada en '{output_img}'")


# =====================================================================
# BLOQUE PRINCIPAL DE EJECUCIÓN (USANDO PARÁMETROS)
# =====================================================================
if __name__ == "__main__":
    
    # Comprobar si se ha pasado el argumento de la carpeta por terminal
    if len(sys.argv) < 2:
        print("[ERROR] Falta especificar la carpeta del ensayo.")
        print("\nUso correcto:")
        print(f"  python {os.path.basename(sys.argv[0])} <nombre_carpeta_test>")
        print("\nEjemplo:")
        print(f"  python {os.path.basename(sys.argv[0])} test_1")
        sys.exit(1)
        
    # Obtener el primer parámetro enviado al script
    carpeta_test = sys.argv[1]
    
    if os.path.exists(carpeta_test):
        generar_grafico_potencia(carpeta_test)
        plot_inferencia_fpga(carpeta_test)
        
        # Muestra en pantalla los gráficos generados
        plt.show()
    else:
        print(f"[ERROR] La carpeta especificada '{carpeta_test}' no existe en este directorio.")
        sys.exit(1)

