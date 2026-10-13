import pandas as pd
import matplotlib.pyplot as plt
import os

# Nombre del archivo CSV generado por la Zybo Z7
CSV_FILENAME = "registro_potencia_zybo.csv"

# Ajustado para reflejar tu nuevo muestreo: 
# 200 muestras a 5ms equivalen a una ventana de promediado de exactamente 1.0 segundo.
VENTANA_SUAVIZADO = 200 

def generar_grafico():
    if not os.path.exists(CSV_FILENAME):
        print(f"[ERROR] No se encuentra el archivo '{CSV_FILENAME}' en este directorio.")
        return

    print(f"Cargando datos desde {CSV_FILENAME}...")
    df = pd.read_csv(CSV_FILENAME)
    
    # --- FILTRADO DIGITAL (Media Móvil) ---
    df["Potencia_Suave_W"] = df["Potencia_W"].rolling(window=VENTANA_SUAVIZADO, center=True, min_periods=1).mean()
    df["Potencia_Suave_W"] = df["Potencia_Suave_W"].fillna(df["Potencia_W"])

    # --- CÁLCULO DE ENERGÍA TOTAL (JULIOS) ---
    # Cada muestra representa exactamente 5ms (0.005 segundos)
    intervalo_segundos = 0.005
    energia_julios = (df["Potencia_W"] * intervalo_segundos).sum()

    # Métricas estadísticas basadas en la señal real
    potencia_max = df["Potencia_W"].max()
    potencia_media = df["Potencia_W"].mean()
    potencia_min = df["Potencia_W"].min()
    
    print("-" * 50)
    print(f"Métricas del Ensayo (Muestreo: 5ms):")
    print(f"  - Consumo Mínimo (Base):   {potencia_min:.3f} W")
    print(f"  - Consumo Medio:           {potencia_media:.3f} W")
    print(f"  - Pico Máximo Real:        {potencia_max:.3f} W")
    print(f"  - Energía Total Consumida: {energia_julios:.4f} Julios (J)")
    print("-" * 50)

    # --- ANÁLISIS TEMPORAL DE PICOS Y RESPUESTA TRANSTORIA ---
    df['Time_Obj'] = pd.to_datetime(df['Timestamp'], format='%H:%M:%S.%f', errors='coerce')
    
    potencia_base_suave = df["Potencia_Suave_W"].head(5).mean()
    idx_pico = df["Potencia_Suave_W"].idxmax()
    pico_max_suave = df["Potencia_Suave_W"].loc[idx_pico]
    
    # Umbral dinámico para delimitar el pulso de estrés (Consumo Base + 15% del salto neto hacia el pico)
    umbral_activacion = potencia_base_suave + (pico_max_suave - potencia_base_suave) * 0.15
    
    df_antes_del_pico = df.loc[:idx_pico]
    df_arranque = df_antes_del_pico[df_antes_del_pico["Potencia_Suave_W"] > umbral_activacion]
    
    df_despues_del_pico = df.loc[idx_pico:]
    df_parada = df_despues_del_pico[df_despues_del_pico["Potencia_Suave_W"] < umbral_activacion]

    datos_temporales_validos = False
    if not df_arranque.empty and not df_parada.empty and not df['Time_Obj'].isna().any():
        # Extraccíon del primer índice escalar limpio en el que se cruza el umbral
        idx_arranque_unico = df_arranque.index[0]
        idx_parada_unica = df_parada.index[0]
        
        # Extraer los objetos de tiempo individuales de forma estrictamente escalar
        time_arranque = df['Time_Obj'].loc[idx_arranque_unico]
        time_pico = df['Time_Obj'].loc[idx_pico]
        time_parada = df['Time_Obj'].loc[idx_parada_unica]
        
        # --- CÁLCULO DE TRAMOS ELÉCTRICOS REALES ---
        tiempo_subida = (time_pico - time_arranque).total_seconds()
        tiempo_bajada = (time_parada - time_pico).total_seconds()
        duracion_pulso_total = (time_parada - time_arranque).total_seconds()
        
        # --- ESTIMACIÓN DE LA INFERENCIA ---
        # Restamos el efecto del filtro capacitivo/amortiguador eléctrico de la Zybo Z7
        tiempo_estimado_computo = duracion_pulso_total - (tiempo_subida * 0.5 + tiempo_bajada * 0.5)
        
        # Parámetros del bucle de estrés que ejecutaste en Petalinux (Ajusta si cambiaste de valores)
        num_repeticiones_bucle = 20000  
        num_muestras_por_bucle = 1000
        total_inferencias_totales = num_repeticiones_bucle * num_muestras_por_bucle
        
        # Calcular el tiempo estimado por cada inferencia individual en nanosegundos (ns)
        tiempo_por_inferencia_ns = (tiempo_estimado_computo / total_inferencias_totales) * 1e9
        
        print("=" * 55)
        print(" ESTIMACIÓN DE TIEMPOS DE INFERENCIA POR POTENCIA")
        print("=" * 55)
        print(f" Tiempo transitorio de Subida:  {tiempo_subida:.3f} s")
        print(f" Tiempo transitorio de Bajada:  {tiempo_bajada:.3f} s")
        print(f" Duración total del pulso (W):  {duracion_pulso_total:.3f} s")
        print("-" * 55)
        print(f" TIEMPO NETO ESTIMADO DE CÓMPUTO: {tiempo_estimado_computo:.3f} s")
        print(f" Tiempo estimado por muestra:     {tiempo_por_inferencia_ns:.2f} ns")
        print("=" * 55)
        
        datos_temporales_validos = True
    else:
        print("[AVISO] Estructura temporal o salto de potencia insuficiente para extraer métricas dinámicas.")

    # Configuración del Gráfico
    plt.figure(figsize=(11, 5.5), dpi=100)
    
    # 1. Dibujar la señal original con ruido (en gris claro)
    plt.plot(df.index, df["Potencia_W"], color="#7f7f7f", linewidth=0.6, alpha=0.4, 
             label="Señal Original (Con Ruido)")
    
    # 2. Dibujar la señal suavizada (Línea principal en azul)
    plt.plot(df.index, df["Potencia_Suave_W"], color="#1f77b4", linewidth=1.8, 
             label=f"Señal Suavizada (Media Móvil n={VENTANA_SUAVIZADO})")

    # Si los datos de tiempo son válidos, incrustamos los marcadores de eventos críticos
    if datos_temporales_validos:
        plt.scatter(idx_arranque_unico, df["Potencia_Suave_W"].loc[idx_arranque_unico], color="green", s=60, zorder=5, label="Inicio Subida")
        plt.scatter(idx_pico, pico_max_suave, color="red", s=60, zorder=5, label=f"Pico Suavizado ({pico_max_suave:.2f} W)")
        plt.scatter(idx_parada_unica, df["Potencia_Suave_W"].loc[idx_parada_unica], color="orange", s=60, zorder=5, label="Retorno a Base")
        
        plt.axvline(x=idx_arranque_unico, color="green", linestyle=":", alpha=0.5)
        plt.axvline(x=idx_pico, color="red", linestyle=":", alpha=0.5)
        plt.axvline(x=idx_parada_unica, color="orange", linestyle=":", alpha=0.5)

    # Líneas de referencia horizontales
    plt.axhline(y=potencia_max, color="#d62728", linestyle="--", alpha=0.7, 
                label=f"Pico Máximo Real ({potencia_max:.2f} W)")
    plt.axhline(y=potencia_media, color="#2ca02c", linestyle=":", alpha=0.8, 
                label=f"Consumo Medio ({potencia_media:.2f} W)")

    # Títulos y anotaciones estéticas
    plt.title("Perfil de Consumo Energético Filtrado y Dinámica de Transitorios - Zybo Z7", fontsize=13, fontweight='bold', pad=15)
    plt.xlabel("Tiempo / Muestras (Intervalos de 5ms)", fontsize=11, labelpad=10)
    plt.ylabel("Potencia (Vatios - W)", fontsize=11, labelpad=10)
    
    plt.ylim(max(0, potencia_min - 0.3), potencia_max + 0.4)
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="upper left", frameon=True, shadow=True)

    plt.tight_layout()
    print("Mostrando gráfico optimizado con análisis temporal a 5ms...")
    plt.show()

if __name__ == "__main__":
    generar_grafico()

