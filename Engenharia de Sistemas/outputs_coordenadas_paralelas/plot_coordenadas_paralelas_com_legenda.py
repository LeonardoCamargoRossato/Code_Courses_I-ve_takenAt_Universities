import os
import pandas as pd
import plotly.graph_objects as go


# ============================================================
# CONFIGURAÇÕES
# ============================================================

arquivo_csv = "dados_usados_coordenadas_paralelas.csv"

pasta_saida = "outputs_plotly_coordenadas_paralelas"
os.makedirs(pasta_saida, exist_ok=True)

indicadores = [
    "TempoSubida",
    "Overshoot",
    "Undershoot",
    "ErroRampa"
]


# ============================================================
# LEITURA DO CSV
# ============================================================

if not os.path.isfile(arquivo_csv):
    raise FileNotFoundError(
        f"Arquivo não encontrado: {arquivo_csv}\n"
        "Coloque o CSV na mesma pasta deste script."
    )

df = pd.read_csv(arquivo_csv)

colunas_necessarias = ["Kp", "Ki"] + indicadores

for coluna in colunas_necessarias:
    if coluna not in df.columns:
        raise ValueError(f"Coluna ausente no CSV: {coluna}")

for coluna in colunas_necessarias:
    df[coluna] = pd.to_numeric(df[coluna], errors="coerce")

df = df.dropna(subset=colunas_necessarias)

if len(df) == 0:
    raise ValueError("A tabela ficou vazia depois de remover NaN.")

print("CSV carregado com sucesso.")
print(f"Número de curvas: {len(df)}")


# ============================================================
# NORMALIZAÇÃO DOS INDICADORES
# ============================================================

df_norm = df.copy()

valores_min = {}
valores_max = {}

for col in indicadores:
    valor_min = df[col].min()
    valor_max = df[col].max()

    valores_min[col] = valor_min
    valores_max[col] = valor_max

    if valor_max == valor_min:
        df_norm[col] = 0.5
    else:
        df_norm[col] = (df[col] - valor_min) / (valor_max - valor_min)


# ============================================================
# FUNÇÃO AUXILIAR PARA CONVERTER VALOR REAL PARA NORMALIZADO
# ============================================================

def normalizar_valor(valor, col):
    vmin = valores_min[col]
    vmax = valores_max[col]

    if vmax == vmin:
        return 0.5

    return (valor - vmin) / (vmax - vmin)


# ============================================================
# GRÁFICO COM UMA CURVA POR PAR (Kp, Ki)
# ============================================================

fig = go.Figure()

for idx, row in df.iterrows():

    nome_curva = f"Kp={row['Kp']:.2f}, Ki={row['Ki']:.2f}"

    valores_norm = [
        df_norm.loc[idx, "TempoSubida"],
        df_norm.loc[idx, "Overshoot"],
        df_norm.loc[idx, "Undershoot"],
        df_norm.loc[idx, "ErroRampa"]
    ]

    texto_hover = [
        f"{nome_curva}<br>TempoSubida = {row['TempoSubida']:.4f}",
        f"{nome_curva}<br>Overshoot = {row['Overshoot']:.4f}",
        f"{nome_curva}<br>Undershoot = {row['Undershoot']:.4f}",
        f"{nome_curva}<br>ErroRampa = {row['ErroRampa']:.4f}",
    ]

    fig.add_trace(
        go.Scatter(
            x=indicadores,
            y=valores_norm,
            mode="lines+markers",
            name=nome_curva,
            text=texto_hover,
            hoverinfo="text",
            line=dict(width=2),
            marker=dict(size=7),
            visible=True
        )
    )


# ============================================================
# ADICIONANDO VALORES REAIS EM CADA EIXO
# ============================================================

for i, col in enumerate(indicadores):
    x_pos = col

    vmin = valores_min[col]
    vmax = valores_max[col]

    valores_ticks = [
        vmin,
        vmin + 0.25 * (vmax - vmin),
        vmin + 0.50 * (vmax - vmin),
        vmin + 0.75 * (vmax - vmin),
        vmax
    ]

    for valor in valores_ticks:
        y_norm = normalizar_valor(valor, col)

        fig.add_annotation(
            x=x_pos,
            y=y_norm,
            text=f"{valor:.3g}",
            showarrow=False,
            xshift=-38,
            font=dict(size=11, color="black"),
            bgcolor="rgba(255,255,255,0.85)",
            bordercolor="rgba(0,0,0,0.15)",
            borderwidth=1
        )


# ============================================================
# ADICIONANDO LINHAS VERTICAIS DOS EIXOS
# ============================================================

for col in indicadores:
    fig.add_shape(
        type="line",
        x0=col,
        x1=col,
        y0=0,
        y1=1,
        line=dict(color="black", width=1)
    )


# ============================================================
# LAYOUT COM BACKGROUND BRANCO
# ============================================================

fig.update_layout(
    title="Coordenadas Paralelas dos Indicadores — Curvas por par (Kp, Ki)",
    width=1450,
    height=820,
    xaxis_title="Indicadores",
    yaxis_title="Valor normalizado entre 0 e 1",
    hovermode="closest",

    paper_bgcolor="white",
    plot_bgcolor="white",

    font=dict(
        size=14,
        color="black"
    ),

    legend=dict(
        title="Pares (Kp, Ki)",
        orientation="v",
        x=1.03,
        y=1,
        xanchor="left",
        yanchor="top",
        bgcolor="white",
        bordercolor="black",
        borderwidth=1
    ),

    margin=dict(l=90, r=320, t=100, b=90)
)

fig.update_xaxes(
    showgrid=False,
    zeroline=False,
    showline=True,
    linecolor="black",
    tickfont=dict(color="black")
)

fig.update_yaxes(
    range=[0, 1],
    showgrid=True,
    gridcolor="rgba(0,0,0,0.12)",
    zeroline=False,
    showline=True,
    linecolor="black",
    tickfont=dict(color="black")
)


# ============================================================
# BOTÕES PARA MOSTRAR/ESCONDER TODAS AS CURVAS
# ============================================================

n_traces_curvas = len(df)
n_traces_total = len(fig.data)

fig.update_layout(
    updatemenus=[
        dict(
            type="buttons",
            direction="right",
            x=0,
            y=1.12,
            buttons=[
                dict(
                    label="Mostrar todas",
                    method="update",
                    args=[{"visible": [True] * n_traces_total}]
                ),
                dict(
                    label="Ocultar curvas",
                    method="update",
                    args=[{"visible": [False] * n_traces_curvas}]
                )
            ]
        )
    ]
)


# ============================================================
# SALVANDO OUTPUTS
# ============================================================

arquivo_html = os.path.join(
    pasta_saida,
    "coordenadas_paralelas_com_legenda_valores.html"
)

arquivo_png = os.path.join(
    pasta_saida,
    "coordenadas_paralelas_com_legenda_valores.png"
)

fig.write_html(arquivo_html)

try:
    fig.write_image(arquivo_png, scale=2)
    print(f"PNG salvo em: {arquivo_png}")
except Exception as erro:
    print("Não foi possível salvar PNG. O HTML foi salvo normalmente.")
    print(erro)

print("HTML salvo em:")
print(arquivo_html)

fig.show()
