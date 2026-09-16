import pandas as pd
import matplotlib.pyplot as plt
import os

def plot_simple_csv(csv_path="results/resultado_inferencia.csv"):
    if not os.path.exists(csv_path):
        print(f"[ERROR] No se encontró el archivo: {csv_path}")
        return

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

    df['Valor_Norm'] = (df['Valor_Decimal'] / 1024) * (5.00001 - 0.14999) + 0.14999 
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
    plt.show()

if __name__ == "__main__":
    plot_simple_csv()
