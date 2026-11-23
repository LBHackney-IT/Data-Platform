# flake8: noqa: F821

import os

import geopandas as gpd
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.colors import ListedColormap
from matplotlib.patches import Patch

file_path = os.getenv("FILE_PATH")
shapefile_path = os.getenv("SHP_PATH")
out_path = os.getenv("OUT_PATH")
estates_shapefile_path = os.getenv("ESTATES_SHP_PATH")

df = pd.read_csv(file_path, low_memory=False)
boundaries = gpd.read_file(shapefile_path)
estates_boundaries = gpd.read_file(estates_shapefile_path)


# Filter out out-of-borough properties
df = df[df["out_of_borough_flag"] == False].copy()

# Identify garages vs dwellings using prop_type
df["is_garage"] = (
    df["prop_type"].astype(str).str.strip().str.contains("Garage", case=False, na=False)
)
df["is_dwelling"] = ~df["is_garage"]

# Identify Secure tenancies (case-insensitive check)
df["is_secure"] = df["latest_tenancy"].astype(str).str.strip().str.lower() == "secure"

# --- NEIGHBOURHOOD PAIRINGS ---
pairing_map = {
    "Central": "Central_South",
    "South": "Central_South",
    "North East": "NorthEast_NorthWest",
    "North West": "NorthEast_NorthWest",
}

df["macro_pair"] = df["neighbourhood_area"].map(pairing_map)
if df["macro_pair"].isna().any():
    df["macro_pair"] = np.where(
        df["neighbourhood_area"].str.contains("North", case=False, na=False),
        "NorthEast_NorthWest",
        "Central_South",
    )

# Assign balancing weights for macro-pair allocation and clustering:
# Secure Dwellings = 3.0, Non-Secure Dwellings = 1.0 - have boosted the weighting of secure dwellings
df["weight"] = np.where(df["is_dwelling"], np.where(df["is_secure"], 3, 1.0), 0.0)

# Calculate dynamic patch allocation (k) per area based on WEIGHTED dwelling workload
area_k_allocation = {}

for pair_name, pair_df in df.groupby("macro_pair"):
    areas = pair_df["neighbourhood_area"].unique()
    total_pair_weight = pair_df["weight"].sum()
    target_patch_weight = total_pair_weight / 8.0

    if len(areas) == 2:
        area_a, area_b = areas[0], areas[1]
        weight_a = pair_df[(pair_df["neighbourhood_area"] == area_a)]["weight"].sum()
        weight_b = pair_df[(pair_df["neighbourhood_area"] == area_b)]["weight"].sum()

        candidate_splits = [(4, 4), (3, 5), (5, 3)]
        best_split = None
        best_error = float("inf")

        for k_a, k_b in candidate_splits:
            avg_a = weight_a / k_a
            avg_b = weight_b / k_b
            error = abs(avg_a - target_patch_weight) + abs(avg_b - target_patch_weight)
            if error < best_error:
                best_error = error
                best_split = (k_a, k_b)

        area_k_allocation[area_a] = best_split[0]
        area_k_allocation[area_b] = best_split[1]
    else:
        area_k_allocation[areas[0]] = 8

processed_groups = []

for area_name, group_df in df.groupby("neighbourhood_area"):
    group_df = group_df.copy()
    k = area_k_allocation.get(area_name, 4)

    # Separate Dwellings and Garages for this neighbourhood area
    dwelling_df = group_df[group_df["is_dwelling"]].copy()
    garage_df = group_df[group_df["is_garage"]].copy()

    # 1. UNIFIED DATA PREPARATION (DWELLINGS ONLY)
    missing_estate = dwelling_df["estate_name"].isna()
    dwelling_df["grouping_key"] = dwelling_df["estate_name"]
    dwelling_df.loc[missing_estate, "grouping_key"] = "Standalone_" + dwelling_df.loc[
        missing_estate, "property_reference"
    ].astype(str)

    area_weighted_total = dwelling_df["weight"].sum()
    target_capacity = area_weighted_total / k

    # --- MULTI-LEVEL SPLITTING FOR LARGE ESTATES (Weighted) ---
    actual_estates = dwelling_df[~missing_estate]
    estate_weights = actual_estates.groupby("estate_name")["weight"].sum()

    oversized_estates = estate_weights[estate_weights > (target_capacity * 0.2)].index
    is_oversized = dwelling_df["estate_name"].isin(oversized_estates) & (
        ~missing_estate
    )

    block_str = dwelling_df["block_name"].fillna("Unspecified_Block").astype(str)
    if "sub_block_name" in dwelling_df.columns:
        sub_block_str = (
            dwelling_df["sub_block_name"]
            .fillna("Standalone_" + dwelling_df["property_reference"].astype(str))
            .astype(str)
        )
    else:
        sub_block_str = "Standalone_" + dwelling_df["property_reference"].astype(str)

    dwelling_df.loc[is_oversized, "grouping_key"] = (
        dwelling_df.loc[is_oversized, "estate_name"].astype(str)
        + " - B: "
        + block_str.loc[is_oversized]
        + " - SB: "
        + sub_block_str.loc[is_oversized]
    )

    # 2. PRE-AGGREGATION (Dwellings Only - Tracking Weighted Capacity)
    estate_groups = dwelling_df.groupby("grouping_key")

    agg_data = []
    for g_key, e_df in estate_groups:
        dwellings_count = len(e_df)
        weighted_val = e_df["weight"].sum()
        agg_data.append(
            {
                "grouping_key": g_key,
                "total_properties": dwellings_count,
                "weighted_capacity": weighted_val,
                "Agg_easting": e_df["eastings"].mean(),
                "Agg_northing": e_df["northings"].mean(),
            }
        )

    agg_df = (
        pd.DataFrame(agg_data)
        .sort_values(by="weighted_capacity", ascending=False)
        .reset_index(drop=True)
    )

    # 3. CAPACITY-BALANCED CLUSTERING (Weighted Dwellings)
    if len(agg_df) < k:
        agg_df["Subgroup_ID"] = [(i % k) + 1 for i in range(len(agg_df))]
        dwelling_df = dwelling_df.merge(
            agg_df[["grouping_key", "Subgroup_ID"]], on="grouping_key", how="left"
        )
    else:
        coords = agg_df[["Agg_easting", "Agg_northing"]].values
        counts = agg_df[
            "weighted_capacity"
        ].values  # <--- Balancing on weighted workload

        center = coords.mean(axis=0)
        selected_centroids = []
        c1 = coords[np.argmax(np.linalg.norm(coords - center, axis=1))]
        selected_centroids.append(c1)

        for _ in range(1, k):
            dist_matrix = np.array(
                [np.linalg.norm(coords - c, axis=1) for c in selected_centroids]
            )
            min_dists = dist_matrix.min(axis=0)
            next_c = coords[np.argmax(min_dists)]
            selected_centroids.append(next_c)

        centroids = np.array(selected_centroids)
        cluster_multipliers = np.ones(k)
        learning_rate = 0.2

        for iteration in range(300):
            distances = np.linalg.norm(
                coords[:, np.newaxis, :] - centroids[np.newaxis, :, :], axis=2
            )

            penalized_distances = distances * cluster_multipliers
            labels = np.argmin(penalized_distances, axis=1)

            # Dead Cluster Rescue
            for j in range(k):
                if not np.any(labels == j):
                    current_weights = np.array(
                        [counts[labels == c].sum() for c in range(k)]
                    )
                    heaviest = np.argmax(current_weights)
                    heaviest_pts = np.where(labels == heaviest)[0]
                    if len(heaviest_pts) > 0:
                        farthest = heaviest_pts[
                            np.argmax(distances[heaviest_pts, heaviest])
                        ]
                        centroids[j] = coords[farthest]
                        labels[farthest] = j
                        cluster_multipliers[j] = 0.5

            cluster_weights = np.array([counts[labels == j].sum() for j in range(k)])

            new_centroids = np.array(
                [
                    coords[labels == j].mean(axis=0)
                    if np.any(labels == j)
                    else centroids[j]
                    for j in range(k)
                ]
            )
            centroids = new_centroids

            ratio = cluster_weights / target_capacity
            cluster_multipliers = cluster_multipliers * (ratio**learning_rate)
            cluster_multipliers = np.clip(cluster_multipliers, 0.4, 2.5)

        agg_df["Subgroup_ID"] = labels + 1
        dwelling_df = dwelling_df.merge(
            agg_df[["grouping_key", "Subgroup_ID"]], on="grouping_key", how="left"
        )

    # 4. ASSIGN GARAGES TO THE NEAREST DWELLING POINT (Pure NumPy)
    if len(garage_df) > 0 and len(dwelling_df) > 0:
        dwelling_coords = dwelling_df[["eastings", "northings"]].values
        dwelling_subgroups = dwelling_df["Subgroup_ID"].values
        garage_coords = garage_df[["eastings", "northings"]].values

        distances = np.linalg.norm(
            garage_coords[:, np.newaxis, :] - dwelling_coords[np.newaxis, :, :], axis=2
        )

        nearest_dwelling_indices = np.argmin(distances, axis=1)
        garage_df["Subgroup_ID"] = dwelling_subgroups[nearest_dwelling_indices]
        garage_df["grouping_key"] = "Garage_Assigned_Nearest_Dwelling"

    # 5. RECOMBINE DWELLINGS + GARAGES FOR THIS AREA
    area_final_df = pd.concat([dwelling_df, garage_df], ignore_index=True)
    processed_groups.append(area_final_df)

# ==========================================
# POST-PROCESSING & MAPPING
# ==========================================

final_df = pd.concat(processed_groups, ignore_index=True)

# --- CREATE DERIVED COLUMNS ON FINAL CONCATENATED DATAFRAME ---
# 1. Mutually exclusive category for non-secure dwellings
final_df["is_other_dwelling"] = final_df["is_dwelling"] & (~final_df["is_secure"])

# 2. Assign Global Cluster IDs (1 through 16)
final_df["Global_Cluster_ID"] = (
    final_df.groupby(["neighbourhood_area", "Subgroup_ID"]).ngroup() + 1
)

# 3. Concatenated Area & Patch Name Column for CSV Export
final_df["Area_Patch"] = (
    final_df["neighbourhood_area"].astype(str)
    + " - Patch "
    + final_df["Subgroup_ID"].astype(int).astype(str)
)

# 4. Save CSV Output
if out_path:
    os.makedirs(out_path, exist_ok=True)
    csv_filename = os.path.join(out_path, "clustered_properties_secure_tenancies.csv")
    final_df.to_csv(csv_filename, index=False)
    print(f"Exported processed dataset to: {csv_filename}")
else:
    final_df.to_csv("clustered_properties_secure_tenancies.csv", index=False)
    print("Exported processed dataset to local directory.")

# Summary Table (Reordered: Secure Tenancies -> Other Dwellings -> Garages)
df_group = (
    final_df.groupby(["macro_pair", "neighbourhood_area", "Subgroup_ID"])
    .agg(
        secure_tenancies=("is_secure", lambda x: (x == True).sum()),
        other_dwellings=("is_other_dwelling", lambda x: (x == True).sum()),
        garages=("is_garage", lambda x: (x == True).sum()),
        total_dwellings=("is_dwelling", lambda x: (x == True).sum()),
        total_properties=("property_reference", "count"),
    )
    .reset_index()
)

df_group["Global_Cluster_ID"] = (
    df_group.groupby(["neighbourhood_area", "Subgroup_ID"]).ngroup() + 1
)

df_group["Legend_Label"] = (
    df_group["neighbourhood_area"]
    + " - Patch "
    + df_group["Subgroup_ID"].astype(int).astype(str)
    + " ("
    + df_group["secure_tenancies"].astype(str)
    + " Sec | "
    + df_group["other_dwellings"].astype(str)
    + " Other D | "
    + df_group["garages"].astype(str)
    + " G)"
)

print("\n--- Summary: 16 Patches (Secure Tenancies First) ---")
print(
    df_group[
        [
            "macro_pair",
            "neighbourhood_area",
            "Subgroup_ID",
            "Global_Cluster_ID",
            "secure_tenancies",
            "other_dwellings",
            "garages",
            "total_dwellings",
            "total_properties",
        ]
    ]
)
print("----------------------------------------------------\n")

patch_mapping = df_group.set_index("Global_Cluster_ID")["Legend_Label"].to_dict()
plot_df = final_df.dropna(subset=["Subgroup_ID"])

# --- LOAD AND FILTER ESTATES SHAPEFILE ---
if os.path.exists(estates_shapefile_path):
    estates_boundaries = gpd.read_file(estates_shapefile_path)

    status_filter = (
        ~estates_boundaries["status"]
        .astype(str)
        .str.strip()
        .str.contains("Disposed|to be removed", case=False, na=False)
    )
    tmo_filter = (
        estates_boundaries["management"].astype(str).str.strip().str.upper() != "TMO"
    )

    estates_boundaries = estates_boundaries[status_filter & tmo_filter].copy()
else:
    estates_boundaries = None

# --- FIGURE PLOTTING ---
fig, ax = plt.subplots(figsize=(20, 12))

# 1. Base Borough Outline
boundaries.plot(
    ax=ax,
    facecolor="none",
    edgecolor="dimgrey",
    linewidth=1.5,
    linestyle="--",
    zorder=1,
)

# 2. Filtered Estates Polygon Layer
if estates_boundaries is not None and len(estates_boundaries) > 0:
    estates_boundaries.plot(
        ax=ax,
        facecolor="gray",
        edgecolor="#777777",
        linewidth=0.8,
        alpha=0.5,
        zorder=3,
    )

# 3. Property Points (Semi-transparent scatter)
custom_hex_colors = [
    "#FFE600",
    "#0011B8",
    "#FF0055",
    "#00FF66",
    "#D800FF",
    "#00E5FF",
    "#FF5500",
    "#3A007D",
    "#76FF03",
    "#FF00AA",
    "#008941",
    "#FFB700",
    "#99D5FF",
    "#FF0000",
    "#00F5D4",
    "#7000FF",
]
custom_cmap = ListedColormap(custom_hex_colors)

scatter = ax.scatter(
    plot_df["eastings"],
    plot_df["northings"],
    c=plot_df["Global_Cluster_ID"],
    cmap=custom_cmap,
    s=15,
    alpha=0.4,
    edgecolors="black",
    linewidth=0.2,
    zorder=5,
)

# --- CONSTRUCT LEGEND HANDLES & LABELS ---
unique_ids = sorted(plot_df["Global_Cluster_ID"].unique())
scatter_handles, _ = scatter.legend_elements(num=unique_ids)
patch_labels = [patch_mapping[uid] for uid in unique_ids]

# Create custom legend item for Estates layer
estate_legend_handle = Patch(
    facecolor="#E0E0E0", edgecolor="#777777", alpha=0.5, label="Filtered LBH Estates"
)

# Combine Estates handle with Patch handles
all_handles = [estate_legend_handle] + scatter_handles
all_labels = ["Filtered LBH Estates"] + patch_labels

legend = ax.legend(
    all_handles,
    all_labels,
    title="Patches (Sec = Secure | Other D = Other Dwellings | G = Garages)",
    bbox_to_anchor=(1.02, 1.0),
    loc="upper left",
    ncol=1,
    fontsize=9.0,
    title_fontsize=10.0,
    frameon=True,
    facecolor="white",
    edgecolor="grey",
)
ax.add_artist(legend)

# Manual Neighborhood Area Labels
area_col = (
    "neighbourhood_area"
    if "neighbourhood_area" in boundaries.columns
    else ("NAME" if "NAME" in boundaries.columns else boundaries.columns[0])
)

label_positions = {
    "North West": (531500, 186000),
    "North East": (536100, 187000),
    "Central": (536000, 183500),
    "South": (532100, 182500),
}

for idx, row in boundaries.iterrows():
    area_name = str(row[area_col])
    if area_name in label_positions:
        text_x, text_y = label_positions[area_name]
    else:
        minx, miny, maxx, maxy = row.geometry.bounds
        text_x = minx
        text_y = maxy + ((maxy - miny) * 0.03)

    ax.text(
        text_x,
        text_y,
        s=area_name,
        fontsize=11,
        fontweight="bold",
        color="black",
        ha="center",
        va="center",
        bbox=dict(
            boxstyle="round,pad=0.4",
            facecolor="white",
            edgecolor="dimgrey",
            alpha=0.9,
            linewidth=1,
        ),
        zorder=10,
    )

plt.title("Spatial Clustering: 16 Patches (Secure Tenancies Weighted 2.0x)")
plt.xlabel("Easting")
plt.ylabel("Northing")
plt.grid(True, linestyle=":", alpha=0.5)
plt.axis("equal")

plt.subplots_adjust(right=0.66)

if out_path:
    plt.savefig(
        f"{out_path}neighbourhood_areas_clusters_filtered_estates.png",
        dpi=300,
        bbox_inches="tight",
    )

plt.show()
