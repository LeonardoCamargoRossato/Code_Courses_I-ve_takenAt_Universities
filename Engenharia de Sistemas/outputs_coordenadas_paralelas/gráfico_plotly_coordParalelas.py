import os
import pandas as pd
import plotly.graph_objects as go


# ============================================================
# CONFIGURAÇÕES
# ============================================================

# Nome do arquivo CSV de entrada
# Este script pressupõe que ele está na mesma pasta do arquivo .py
arquivo_csv = "dados_usados_coordenadas_paralelas.csv"

# Pasta de saída
pasta_saida = "outputs_plotly_coordenadas_paralelas"
os.makedirs(pasta_saida, exist_ok=True)


# ============================================================
# LEITURA DO CSV
# ============================================================

if not os.path.isfile(arquivo_csv):
    raise FileNotFoundError(
        f"Arquivo não encontrado: {arquivo_csv}\n"
        "Coloque o arquivo dados_usados_coordenadas_paralelas.csv "
        "na mesma pasta deste script."
    )

df = pd.read_csv(arquivo_csv)

print("CSV carregado com sucesso.")
print("Primeiras linhas:")
print(df.head())
print(f"\nTotal de linhas carregadas: {len(df)}")


# ============================================================
# VERIFICAÇÃO DAS COLUNAS NECESSÁRIAS
# ============================================================

colunas_necessarias = [
    "Kp",
    "Ki",
    "TempoSubida",
    "Overshoot",
    "Undershoot",
    "ErroRampa"
]

for coluna in colunas_necessarias:
    if coluna not in df.columns:
        raise ValueError(f"Coluna obrigatória ausente no CSV: {coluna}")


# ============================================================
# LIMPEZA DOS DADOS
# ============================================================

# Remove linhas com NaN nas colunas importantes
df = df.dropna(subset=colunas_necessarias)

# Garante que as colunas são numéricas
for coluna in colunas_necessarias:
    df[coluna] = pd.to_numeric(df[coluna], errors="coerce")

# Remove novamente linhas que viraram NaN após conversão
df = df.dropna(subset=colunas_necessarias)

print(f"Total de linhas após limpeza: {len(df)}")

if len(df) == 0:
    raise ValueError("A tabela ficou vazia após remover NaN. Verifique o CSV.")


# ============================================================
# CRIA RÓTULO DE CADA CURVA
# ============================================================

df["Par_Kp_Ki"] = df.apply(
    lambda row: f"Kp={row['Kp']:.2f}, Ki={row['Ki']:.2f}",
    axis=1
)


# ============================================================
# GRÁFICO DE COORDENADAS PARALELAS
# ============================================================

fig = go.Figure(
    data=go.Parcoords(
        line=dict(
            color=df["Kp"],
            colorscale="Viridis",
            showscale=True,
            colorbar=dict(
                title="Kp"
            )
        ),
        dimensions=[
            dict(
                label="TempoSubida",
                values=df["TempoSubida"],
                range=[
                    df["TempoSubida"].min(),
                    df["TempoSubida"].max()
                ]
            ),
            dict(
                label="Overshoot",
                values=df["Overshoot"],
                range=[
                    df["Overshoot"].min(),
                    df["Overshoot"].max()
                ]
            ),
            dict(
                label="Undershoot",
                values=df["Undershoot"],
                range=[
                    df["Undershoot"].min(),
                    df["Undershoot"].max()
                ]
            ),
            dict(
                label="ErroRampa",
                values=df["ErroRampa"],
                range=[
                    df["ErroRampa"].min(),
                    df["ErroRampa"].max()
                ]
            )
        ]
    )
)

fig.update_layout(
    title="Coordenadas Paralelas dos Indicadores",
    width=1300,
    height=750,
    font=dict(size=14)
)


# ============================================================
# SALVANDO OUTPUTS
# ============================================================

arquivo_html = os.path.join(
    pasta_saida,
    "coordenadas_paralelas_plotly.html"
)

arquivo_png = os.path.join(
    pasta_saida,
    "coordenadas_paralelas_plotly.png"
)

arquivo_csv_saida = os.path.join(
    pasta_saida,
    "dados_plotly_usados.csv"
)

fig.write_html(arquivo_html)

try:
    fig.write_image(arquivo_png, scale=2)
    print(f"PNG salvo em: {arquivo_png}")
except Exception as erro:
    print("\nNão foi possível salvar o PNG.")
    print("O HTML foi salvo normalmente.")
    print("Erro retornado:")
    print(erro)

df.to_csv(arquivo_csv_saida, index=False)

print("\nArquivos gerados:")
print(arquivo_html)
print(arquivo_csv_saida)

print("\nAbrindo gráfico no navegador...")
fig.show()
