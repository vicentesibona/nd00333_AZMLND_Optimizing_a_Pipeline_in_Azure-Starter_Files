#!/usr/bin/env bash
# Crea un entorno conda local para desarrollar y probar train.py offline
# con el Azure ML SDK v1. Pensado para Linux (probado en Linux Mint / Ubuntu).
#
# Uso:
#   bash setup_env.sh            # crea/actualiza el entorno
#   conda activate azureml-v1    # luego actívalo
set -euo pipefail

ENV_NAME="azureml-v1"
PYTHON_VERSION="3.8"
MINICONDA_DIR="$HOME/miniconda3"

# 1. Instalar Miniconda si no hay conda disponible
if ! command -v conda >/dev/null 2>&1; then
    if [ -x "$MINICONDA_DIR/bin/conda" ]; then
        echo ">> Usando Miniconda existente en $MINICONDA_DIR"
    else
        echo ">> conda no encontrado, instalando Miniconda en $MINICONDA_DIR"
        installer="$(mktemp --suffix=.sh)"
        wget -q -O "$installer" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        bash "$installer" -b -p "$MINICONDA_DIR"
        rm -f "$installer"
        "$MINICONDA_DIR/bin/conda" init bash
    fi
    export PATH="$MINICONDA_DIR/bin:$PATH"
fi

# Permite usar 'conda activate' dentro del script
eval "$(conda shell.bash hook)"

# 2. Dependencia de sistema que pide azureml-dataprep para leer datasets
if ! ldconfig -p | grep -q libicu; then
    echo ">> Instalando libicu-dev (requiere sudo)"
    sudo apt-get update && sudo apt-get install -y libicu-dev
fi

# 3. Crear el entorno si no existe
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo ">> El entorno '$ENV_NAME' ya existe, se actualizarán los paquetes"
else
    echo ">> Creando entorno '$ENV_NAME' con Python $PYTHON_VERSION"
    conda create -n "$ENV_NAME" "python=$PYTHON_VERSION" -y
fi

conda activate "$ENV_NAME"

# 4. Paquetes. numpy<1.24 mantiene np.float / np.int que usa train.py
echo ">> Instalando paquetes de Python"
pip install --upgrade pip
pip install \
    "numpy<1.24" \
    "pandas<2" \
    scikit-learn \
    joblib \
    azureml-core \
    azureml-dataset-runtime \
    azureml-train-core \
    azureml-widgets \
    jupyter

# 5. Verificación
echo ">> Verificando instalación"
python - <<'EOF'
import numpy, sklearn, azureml.core
from azureml.core.run import Run
from azureml.data.dataset_factory import TabularDatasetFactory
print("numpy      ", numpy.__version__, "| np.float ->", numpy.float)
print("sklearn    ", sklearn.__version__)
print("azureml SDK", azureml.core.VERSION)
print("Run offline:", type(Run.get_context()).__name__)
EOF

echo
echo ">> Listo. Activa el entorno con:  conda activate $ENV_NAME"
