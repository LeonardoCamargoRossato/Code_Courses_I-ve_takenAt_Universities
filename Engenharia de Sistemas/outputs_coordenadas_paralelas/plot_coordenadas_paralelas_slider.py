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

# Limites originais
limites_base = {
    "TempoSubida": 10.0,
    "Overshoot": 0.25,
    "Undershoot": 0.15,
    "ErroRampa": 5.0
}

# Percentuais de redução do limite
percentuais_reducao = list(range(0, 55, 5))  # 0%, 5%, 10%, ..., 50%


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
print(f"Número total de curvas: {len(df)}")


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


def normalizar_valor(valor, col):
    vmin = valores_min[col]
    vmax = valores_max[col]

    if vmax == vmin:
        return 0.5

    return (valor - vmin) / (vmax - vmin)


# ============================================================
# FUNÇÃO DE FILTRO POR PERCENTUAL
# ============================================================

def mascara_por_percentual(df_base, percentual):
    fator = 1 - percentual / 100

    limite_tempo = limites_base["TempoSubida"] * fator
    limite_overshoot = limites_base["Overshoot"] * fator
    limite_undershoot = limites_base["Undershoot"] * fator
    limite_rampa = limites_base["ErroRampa"] * fator

    mascara = (
        (df_base["TempoSubida"] <= limite_tempo) &
        (df_base["Overshoot"] <= limite_overshoot) &
        (df_base["Undershoot"] <= limite_undershoot) &
        (df_base["ErroRampa"] <= limite_rampa)
    )

    return mascara


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

for col in indicadores:
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
            x=col,
            y=y_norm,
            text=f"{valor:.3g}",
            showarrow=False,
            xshift=-38,
            font=dict(size=11, color="black"),
            bgcolor="rgba(255,255,255,0.90)",
            bordercolor="rgba(0,0,0,0.20)",
            borderwidth=1
        )


# ============================================================
# LINHAS VERTICAIS DOS EIXOS
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
# SLIDER DE FILTRO
# ============================================================

steps = []

for percentual in percentuais_reducao:
    mascara = mascara_por_percentual(df, percentual)
    visibilidade = mascara.tolist()

    fator = 1 - percentual / 100

    limite_tempo = limites_base["TempoSubida"] * fator
    limite_overshoot = limites_base["Overshoot"] * fator
    limite_undershoot = limites_base["Undershoot"] * fator
    limite_rampa = limites_base["ErroRampa"] * fator

    n_visiveis = sum(visibilidade)

    titulo = (
        "Coordenadas Paralelas dos Indicadores — "
        f"Redução dos limites: {percentual}% | "
        f"Curvas visíveis: {n_visiveis}/{len(df)}"
    )

    step = dict(
        method="update",
        label=f"{percentual}%",
        args=[
            {"visible": visibilidade},
            {
                "title": titulo,
                "annotations": fig.layout.annotations
            }
        ]
    )

    steps.append(step)


sliders = [
    dict(
        active=0,
        currentvalue=dict(
            prefix="Redução dos limites: ",
            suffix="",
            font=dict(size=16)
        ),
        pad=dict(t=60),
        steps=steps
    )
]


# ============================================================
# BOTÕES AUXILIARES
# ============================================================

n_traces = len(fig.data)

botoes = [
    dict(
        label="Mostrar todas",
        method="update",
        args=[
            {"visible": [True] * n_traces},
            {
                "title": f"Coordenadas Paralelas dos Indicadores — Todas as curvas visíveis: {len(df)}/{len(df)}",
                "annotations": fig.layout.annotations
            }
        ]
    ),
    dict(
        label="Ocultar todas",
        method="update",
        args=[
            {"visible": [False] * n_traces},
            {
                "title": "Coordenadas Paralelas dos Indicadores — Todas as curvas ocultas",
                "annotations": fig.layout.annotations
            }
        ]
    )
]


# ============================================================
# LAYOUT
# ============================================================

fig.update_layout(
    title=f"Coordenadas Paralelas dos Indicadores — Redução dos limites: 0% | Curvas visíveis: {len(df)}/{len(df)}",
    width=1500,
    height=900,

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

    margin=dict(l=90, r=330, t=120, b=150),

    sliders=sliders,

    updatemenus=[
        dict(
            type="buttons",
            direction="right",
            x=0,
            y=1.16,
            buttons=botoes
        )
    ]
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
# TABELA DE RESUMO DOS FILTROS
# ============================================================

resumo = []

for percentual in percentuais_reducao:
    mascara = mascara_por_percentual(df, percentual)
    fator = 1 - percentual / 100

    resumo.append({
        "ReducaoPercentual": percentual,
        "Limite_TempoSubida": limites_base["TempoSubida"] * fator,
        "Limite_Overshoot": limites_base["Overshoot"] * fator,
        "Limite_Undershoot": limites_base["Undershoot"] * fator,
        "Limite_ErroRampa": limites_base["ErroRampa"] * fator,
        "CurvasVisiveis": int(mascara.sum()),
        "CurvasEliminadas": int(len(df) - mascara.sum())
    })

df_resumo = pd.DataFrame(resumo)


# ============================================================
# SALVANDO OUTPUTS
# ============================================================

arquivo_html = os.path.join(
    pasta_saida,
    "coordenadas_paralelas_slider_filtro.html"
)

arquivo_png = os.path.join(
    pasta_saida,
    "coordenadas_paralelas_slider_filtro.png"
)

arquivo_resumo_csv = os.path.join(
    pasta_saida,
    "resumo_filtros_slider.csv"
)

fig.write_html(arquivo_html)
df_resumo.to_csv(arquivo_resumo_csv, index=False)

try:
    fig.write_image(arquivo_png, scale=2)
    print(f"PNG salvo em: {arquivo_png}")
except Exception as erro:
    print("Não foi possível salvar PNG. O HTML foi salvo normalmente.")
    print(erro)

print("\nHTML salvo em:")
print(arquivo_html)

print("\nResumo dos filtros salvo em:")
print(arquivo_resumo_csv)

print("\nResumo dos filtros:")
print(df_resumo)

fig.show()
