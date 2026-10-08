#!/usr/bin/env bash
# Descarga una copia local del dataset "Bank Marketing" (UCI) para poder
# probar clean_data() y el flujo de train.py sin depender del blob de Azure
# (https://automlsamplenotebookdata.blob.core.windows.net/...), que a la
# fecha de este script devuelve 403 Forbidden fuera del entorno del lab.
#
# IMPORTANTE: esto es solo para desarrollo/prueba local. La entrega final de
# train.py / udacity-project.ipynb debe seguir usando la URL de Azure, que
# es la que funciona dentro del lab de Udacity.
#
# Uso:
#   bash download_dataset.sh
set -euo pipefail

URL="https://archive.ics.uci.edu/static/public/222/bank+marketing.zip"
DEST_DIR="data"
ZIP_NAME="bank-marketing.zip"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

echo ">> Verificando disponibilidad de $URL"
if ! curl -sfI --max-time 15 "$URL" >/dev/null; then
    echo "ERROR: $URL no responde (puede haber cambiado de ubicación)." >&2
    echo "Revisa https://archive.ics.uci.edu/dataset/222/bank+marketing" >&2
    exit 1
fi

echo ">> Descargando dataset"
curl -L -o "$ZIP_NAME" "$URL"

echo ">> Descomprimiendo"
unzip -o "$ZIP_NAME"

# El zip de UCI trae a su vez bank-additional.zip con los CSV reales
if [ -f "bank-additional.zip" ]; then
    unzip -o "bank-additional.zip"
fi

echo
echo ">> Listo. Archivos en $DEST_DIR/:"
find . -name "*.csv"
echo
echo "Ejemplo de carga en Python:"
echo "  import pandas as pd"
echo "  df = pd.read_csv('data/bank-additional/bank-additional-full.csv', sep=';')"
