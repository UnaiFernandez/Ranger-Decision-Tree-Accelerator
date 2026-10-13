import pandas as pd
import matplotlib.pyplot as plt
import os
import glob
import sys
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
import numpy as np


# =====================================================================
# CONFIGURACIÓN GLOBAL
# =====================================================================
VENTANA_SUAVIZADO = 50 
INTERVALO_SEGUNDOS = 0.1
NOMBRE_ARCHIVO_METRICAS = "results/tests_regresion/metrics.csv"

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

    print(f"\n[POTENCIA]\nCargando datos desde: {os.path.basename(csv_filename)}.\n")
    df = pd.read_csv(csv_filename)
    
    # --- FILTRADO DIGITAL (Media Móvil) ---
    df["Potencia_Suave_W"] = df["Potencia_W"].rolling(window=VENTANA_SUAVIZADO, center=True, min_periods=1).mean()
    df["Potencia_Suave_W"] = df["Potencia_Suave_W"].fillna(df["Potencia_W"])
    r_exec = df["Exec"].to_numpy()

    # 2. Detectar transiciones (cambios de estado)
    # Insertamos un 0 al inicio y al final para capturar ejecuciones que empiecen en la primera fila o terminen en la última
    cambios = np.diff(np.concatenate(([0], r_exec, [0])))
    
    # Donde cambios == 1 significa que pasó de 0 a 1 (Inicio de ventana)
    indices_inicio = np.where(cambios == 1)[0]
    # Donde cambios == -1 significa que pasó de 1 a 0 (Fin de ventana)
    indices_fin = np.where(cambios == -1)[0] - 1

    # --- CÁLCULO DE ENERGÍA TOTAL (JULIOS) ---
    energia_julios = (df["Potencia_W"] * INTERVALO_SEGUNDOS).sum()

    # Métricas estadísticas basadas en la señal real
    potencia_max = df["Potencia_Suave_W"].max()
    potencia_media = df["Potencia_W"].mean()
    potencia_min = df["Potencia_W"].min()
    
    print(f"  - Consumo Mínimo (Base):   {potencia_min:.3f} W")
    print(f"  - Consumo Medio:           {potencia_media:.3f} W")
    print(f"  - Pico Máximo Real:        {potencia_max:.3f} W")
    print(f"  - Energía Total Consumida: {energia_julios:.2f} Julios (J)")
    print(f"  - Inicio exec: {df.index[indices_inicio[0]]*0.005:.2f} s")
    print(f"  - Fin exec: {df.index[indices_fin[0]]*0.005:.2f} s")

    # Configuración del Gráfico
    plt.figure(figsize=(8, 5), dpi=100)
    
    plt.plot(df.index, df["Potencia_W"], color="#7f7f7f", linewidth=0.6, alpha=0.4, 
             label="Raw signal")
    
    plt.plot(df.index, df["Potencia_Suave_W"], color="#1f77b4", linewidth=1.8, 
             label=f"Smoothed signal")

    plt.axvspan(df.index[indices_inicio[0]], df.index[indices_fin[0]], color='orange', alpha=0.3, label="Execution")

    plt.axhline(y=potencia_max, color="#d62728", linestyle="--", alpha=0.7, 
                label=f"Max power ({potencia_max:.2f} W)")
    plt.axhline(y=potencia_media, color="#2ca02c", linestyle=":", alpha=0.8, 
                label=f"Avg. power ({potencia_media:.2f} W)")

    plt.title(f"Real-time power consumption", fontsize=13, fontweight='bold', pad=15)
    plt.xlabel("Samples", fontsize=11, labelpad=10)
    plt.ylabel("Power (W)", fontsize=11, labelpad=10)
    
    #plt.ylim(max(0, potencia_min - 0.3), potencia_max + 0.4)
    plt.ylim(1.6, 3.25)
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="upper left", frameon=True, shadow=True)
    plt.tight_layout()
    
    # Guardar el gráfico dentro de la carpeta del test correspondiente
    output_potencia = os.path.join(base_dir, "grafica_perfil_potencia.png")
    plt.savefig(output_potencia, dpi=300)
    #print(f"[INFO] Gráfica de potencia guardada en '{output_potencia}'")

    return potencia_min, potencia_media, potencia_max


def plot_inferencia_fpga(base_dir, p_min, p_med, p_max):
    """Compara las salidas de la FPGA frente a sklearn buscando archivos dinámicamente."""
    csv_inferencia = buscar_archivo_por_patron(base_dir, "resultado_inferencia")
    csv_stats = buscar_archivo_por_patron(base_dir, "sklearn_max_min")
    csv_sklearn = buscar_archivo_por_patron(base_dir, "sklearn_results")
    csv_ytest = buscar_archivo_por_patron(base_dir, "y_test")
    print(csv_sklearn)
    print(csv_ytest)

    # Validar que existan todos los archivos necesarios antes de procesar
    if not all([csv_inferencia, csv_stats, csv_sklearn]):
        print(f"[ERROR] Faltan archivos críticos en '{base_dir}/results/' para la inferencia.")
        print(f"  - Inferencia: {'Detectado' if csv_inferencia else 'FALTA'}")
        print(f"  - Stats:      {'Detectado' if csv_stats else 'FALTA'}")
        print(f"  - Sklearn:    {'Detectado' if csv_sklearn else 'FALTA'}")
        return

    print(f"\n[INFERENCIA]\nCargando archivos dinámicos de {base_dir}.\n")
    try:
        df_fpga = pd.read_csv(csv_inferencia)
        df_stats = pd.read_csv(csv_stats)
        df_sklearn = pd.read_csv(csv_sklearn)
        df_ytest = pd.read_csv(csv_ytest, header=None, names=['Valores'])
    except Exception as e:
        print(f"[ERROR] Al leer los archivos CSV de inferencia: {e}")
        return

    max_value = df_stats.loc[0, "max"]
    min_value = df_stats.loc[0, "min"]
    
    # Obtener nombres de columnas dinámicamente
    col_indice_fpga = df_fpga.columns[0]
    col_valor_fpga = df_fpga.columns[1]
    
    #col_indice_ytest = df_ytest.columns[0]
    #col_valor_ytest = df_ytest.columns[1]

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

    r2 = r2_score(df_sklearn[col_valor_sk], df_fpga['Valor_Norm'])
    mae = mean_absolute_error(df_sklearn[col_valor_sk], df_fpga['Valor_Norm'])
    mse = mean_squared_error(df_sklearn[col_valor_sk], df_fpga['Valor_Norm'])
    rmse = np.sqrt(mse)
    max_error = np.max(np.abs(df_sklearn[col_valor_sk] - df_fpga['Valor_Norm']))

    print(f"    - R² score (R2): {r2:.6f}")
    print(f"    - Error Absoluto Medio (MAE): {mae:.6f}")
    print(f"    - Error Cuadrático Medio (MSE): {mse:.6f}")
    print(f"    - Raíz del Error Cuadrático Medio (RMSE): {rmse:.6f}")
    print(f"    - Desviación máxima en una sola muestra: {max_error:.6f}")

    r2_fpga = r2_score(df_ytest, df_fpga['Valor_Norm'])
    mae_fpga = mean_absolute_error(df_ytest, df_fpga['Valor_Norm'])
    mse_fpga = mean_squared_error(df_ytest, df_fpga['Valor_Norm'])
    rmse_fpga = np.sqrt(mse)
    max_error_fpga = np.max(np.abs(df_ytest - df_fpga['Valor_Norm']))

    print("")
    print("")
    print(f"    - R² score (R2): {r2_fpga:.6f} / {df_stats.loc[0, "R2"]:.6f}")
    print(f"    - Error Absoluto Medio (MAE): {mae_fpga:.6f} / {df_stats.loc[0, "MAE"]:.6f}")
    print(f"    - Error Cuadrático Medio (MSE): {mse_fpga:.6f} / {df_stats.loc[0, "MSE"]:.6f}")
    print(f"    - Raíz del Error Cuadrático Medio (RMSE): {rmse_fpga:.6f} / {df_stats.loc[0, "RMSE"]:.6f}")
    print(f"    - Desviación máxima en una sola muestra: {max_error_fpga:.6f}")

    head_metrics = ['W_min', 'W_med', 'W_max', 'MAE', 'MSE', 'RMSE', 'desv','R2_f', 'MAE_f', 'MSE_f', 'RMSE_f', 'R2_s', 'MAE_s', 'MSE_s', 'RMSE_s']
    dict_metrics = {
            'W_min':[p_min],
            'W_med':[p_med],
            'W_max':[p_max],
            'MAE':[mae],
            'MSE':[mse],
            'RMSE':[rmse],
            'desv':[max_error],
            'R2_f':[r2_fpga],
            'MAE_f':[mae_fpga],
            'MSE_f':[mse_fpga],
            'RMSE_f':[rmse_fpga],
            'R2_s':[df_stats.loc[0, "R2"]],
            'MAE_s':[df_stats.loc[0, "MAE"]],
            'MSE_s':[df_stats.loc[0, "MSE"]],
            'RMSE_s':[df_stats.loc[0, "RMSE"]]
            } 
    # Configuración de la Gráfica
    plt.figure(figsize=(12, 6))
       
    plt.plot(df_ytest,
             color='#7f7f7f', linestyle='-', linewidth=0.6, alpha=0.8, 
             label='Salida sklearn')

    plt.plot(df_sklearn[col_indice_sk], df_sklearn[col_valor_sk],
             color='#ff7f0e', linestyle='-', marker='o', markersize=4, alpha=0.8, 
             label='Salida sklearn')
    
    plt.plot(df_fpga[col_indice_fpga], df_fpga['Valor_Norm'],
             color='#1f77b4', linestyle='-', marker='o', markersize=4, alpha=0.8, 
             label='Salida FPGA')
    
 


    plt.title(f"Valores de Salida del Acelerador FPGA vs Sklearn - {base_dir}", fontsize=14, fontweight='bold', pad=15)
    plt.xlabel("Índice de la Muestra", fontsize=11)
    plt.ylabel("Valor Obtenido (Decimal)", fontsize=11)
    
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend(loc='upper right')
    plt.tight_layout()

    # Guardar el gráfico dentro de la carpeta del test correspondiente
    output_img = os.path.join(base_dir, "grafica_salidas_fpga.png")
    plt.savefig(output_img, dpi=300)
    #print(f"[INFO] Gráfica de inferencia guardada en '{output_img}'")

    df_metrics = pd.DataFrame(dict_metrics)

    print(df_metrics)
    return df_metrics


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
        p_min, p_med, p_max = generar_grafico_potencia(carpeta_test)
        results = plot_inferencia_fpga(carpeta_test, p_min, p_med, p_max)

        if os.path.exists(NOMBRE_ARCHIVO_METRICAS):
            print("Existe")
            results.to_csv(NOMBRE_ARCHIVO_METRICAS, mode='a', header=False, index=False)
        else:
            results.to_csv(NOMBRE_ARCHIVO_METRICAS, index=False)
            print("No existe")
        
        # Muestra en pantalla los gráficos generados
        ret_plot = input("Plot results [y/n] >> ")
        
        if ret_plot in ['y', 'Y']:
            plt.show()
    else:
        print(f"[ERROR] La carpeta especificada '{carpeta_test}' no existe en este directorio.")
        sys.exit(1)

