"""BreatheFlow Dashboard — Air Quality Station Coverage.

Visualises the fct_station_coverage dbt mart from BigQuery.

Run locally:
    streamlit run dashboard/app.py

Environment variables:
    GCP_PROJECT_ID                BigQuery project (required)
    BQ_DATASET                    dbt output dataset (default: breathe_flow)
    GOOGLE_APPLICATION_CREDENTIALS  path to service account JSON (optional)
"""

import os

import pandas as pd
import plotly.express as px
import streamlit as st
from google.cloud import bigquery

# ── Page config ──────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="BreatheFlow — Air Quality Coverage",
    page_icon="🌍",
    layout="wide",
)

# ── Helpers ───────────────────────────────────────────────────────────────────
PROJECT = os.environ.get("GCP_PROJECT_ID", "")
DATASET = os.environ.get("BQ_DATASET", "breathe_flow")


@st.cache_resource(show_spinner=False)
def get_bq_client() -> bigquery.Client:
    creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if creds_path:
        return bigquery.Client.from_service_account_json(creds_path, project=PROJECT)
    return bigquery.Client(project=PROJECT)


@st.cache_data(ttl=3600, show_spinner="Loading coverage data…")
def load_coverage() -> pd.DataFrame:
    client = get_bq_client()
    query = f"""
        SELECT
            snapshot_date,
            country_code,
            country_name,
            active_stations,
            avg_sensors_per_station,
            monitor_stations,
            mobile_stations
        FROM `{PROJECT}.{DATASET}.fct_station_coverage`
        ORDER BY snapshot_date DESC, active_stations DESC
    """
    return client.query(query).to_dataframe()


@st.cache_data(ttl=3600, show_spinner="Loading recent snapshots…")
def load_recent_stations(days: int = 1) -> pd.DataFrame:
    client = get_bq_client()
    query = f"""
        SELECT
            station_id,
            station_name,
            country_code,
            country_name,
            latitude,
            longitude,
            sensor_count,
            is_monitor,
            last_measured_at,
            ingested_date
        FROM `{PROJECT}.{DATASET}.stg_openaq_raw`
        WHERE ingested_date >= DATE_SUB(CURRENT_DATE(), INTERVAL {days} DAY)
          AND latitude IS NOT NULL
          AND longitude IS NOT NULL
        LIMIT 5000
    """
    return client.query(query).to_dataframe()


# ── Layout ────────────────────────────────────────────────────────────────────
st.title("🌍 BreatheFlow — Air Quality Station Coverage")
st.caption("Powered by OpenAQ · dbt · BigQuery")

if not PROJECT:
    st.error("Set the `GCP_PROJECT_ID` environment variable before running.")
    st.stop()

# ── Load data ─────────────────────────────────────────────────────────────────
with st.spinner("Connecting to BigQuery…"):
    try:
        df_cov = load_coverage()
        df_stations = load_recent_stations(days=1)
    except Exception as exc:
        st.error(f"Failed to query BigQuery: {exc}")
        st.stop()

if df_cov.empty:
    st.warning("No data in `fct_station_coverage` yet — run the pipeline first.")
    st.stop()

df_cov["snapshot_date"] = pd.to_datetime(df_cov["snapshot_date"])

# Latest snapshot date for KPIs
latest_date = df_cov["snapshot_date"].max()
df_latest = df_cov[df_cov["snapshot_date"] == latest_date]

# ── KPI row ───────────────────────────────────────────────────────────────────
k1, k2, k3, k4 = st.columns(4)
k1.metric("🗓 Latest snapshot", latest_date.strftime("%Y-%m-%d"))
k2.metric("🌐 Countries covered", df_latest["country_code"].nunique())
k3.metric("📡 Active stations", f"{df_latest['active_stations'].sum():,}")
k4.metric("🔬 Avg sensors / station",
          f"{df_latest['avg_sensors_per_station'].mean():.1f}")

st.divider()

# ── Two-column layout ─────────────────────────────────────────────────────────
col_left, col_right = st.columns([3, 2])

with col_left:
    st.subheader("🗺 Station map (last 24 h)")
    if df_stations.empty:
        st.info("No station data for the last 24 h.")
    else:
        fig_map = px.scatter_geo(
            df_stations,
            lat="latitude",
            lon="longitude",
            color="country_code",
            hover_name="station_name",
            hover_data={"country_name": True, "sensor_count": True,
                        "latitude": False, "longitude": False},
            size="sensor_count",
            size_max=12,
            projection="natural earth",
            title=f"Stations ingested on {latest_date.strftime('%Y-%m-%d')}",
        )
        fig_map.update_layout(margin={"r": 0, "t": 40, "l": 0, "b": 0},
                              height=420)
        st.plotly_chart(fig_map, use_container_width=True)

with col_right:
    st.subheader("📊 Active stations by country (latest)")
    fig_bar = px.bar(
        df_latest.sort_values("active_stations", ascending=True).tail(15),
        x="active_stations",
        y="country_code",
        orientation="h",
        color="active_stations",
        color_continuous_scale="Teal",
        labels={"active_stations": "Active stations", "country_code": "Country"},
        title="Top 15 countries",
    )
    fig_bar.update_layout(coloraxis_showscale=False, height=420,
                          margin={"t": 40, "b": 0})
    st.plotly_chart(fig_bar, use_container_width=True)

st.divider()

# ── Trend chart ───────────────────────────────────────────────────────────────
st.subheader("📈 Station coverage over time")

countries = sorted(df_cov["country_code"].unique())
selected = st.multiselect(
    "Filter countries",
    options=countries,
    default=countries[:5],
)

df_trend = df_cov[df_cov["country_code"].isin(selected)] if selected else df_cov

fig_line = px.line(
    df_trend,
    x="snapshot_date",
    y="active_stations",
    color="country_code",
    markers=True,
    labels={"active_stations": "Active stations", "snapshot_date": "Date",
            "country_code": "Country"},
)
fig_line.update_layout(height=350, margin={"t": 10, "b": 0})
st.plotly_chart(fig_line, use_container_width=True)

# ── Raw table ─────────────────────────────────────────────────────────────────
with st.expander("📋 Raw coverage data"):
    st.dataframe(
        df_latest.sort_values("active_stations", ascending=False)
                 .reset_index(drop=True),
        use_container_width=True,
    )
