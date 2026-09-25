# flake8: noqa: F821
import os

import geopandas as gpd
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.colors import ListedColormap

file_path = os.getenv("FILE_PATH")
shapefile_path = os.getenv("SHP_PATH")
out_path = os.getenv("OUT_PATH")

df = pd.read_csv(file_path, low_memory=False)
boundaries = gpd.read_file(shapefile_path)

# Filter criteria
df = df[
    (df["dwelling_flag"] == True)
    & (df["out_of_borough_flag"] == False)
    & (df["tmo_flag"] == False)
    & (df["leasehold_flag"] == False)
].copy()

processed_groups = []

for area_name, group_df in df.groupby("neighbourhood_area"):
    group_df = group_df.copy()

    # 1. UNIFIED DATA PREPARATION (Treat non-estate properties as size-1 estates)
    missing_estate = group_df["estate_name"].isna()
    group_df["grouping_key"] = group_df["estate_name"]

    # Assign standalone IDs so non-estate units participate in balancing
    group_df.loc[missing_estate, "grouping_key"] = "Standalone_" + group_df.loc[
        missing_estate, "property_reference"
    ].astype(str)

    k = 4
    total_properties_in_area = len(group_df)
    target_capacity = total_properties_in_area / k

    # --- DYNAMIC MULTI-LEVEL SPLITTING FOR LARGE ESTATES ---
    # Calculate sizes of actual estates (excluding standalones)
    actual_estates = group_df[~missing_estate]
    estate_counts = actual_estates["estate_name"].value_counts()

    # LOWER EFFECT OF LARGE ESTATES
    # Estates taking > 25% of target cluster capacity get split into blocks/sub-blocks
    oversized_estates = estate_counts[estate_counts > (target_capacity * 0.25)].index
    is_oversized = group_df["estate_name"].isin(oversized_estates) & (~missing_estate)

    block_str = group_df["block_name"].fillna("Unspecified_Block").astype(str)
    if "sub_block_name" in group_df.columns:
        sub_block_str = (
            group_df["sub_block_name"]
            .fillna("Standalone_" + group_df["property_reference"].astype(str))
            .astype(str)
        )
    else:
        sub_block_str = "Standalone_" + group_df["property_reference"].astype(str)

    # Shatter massive estates down to block/sub-block level
    group_df.loc[is_oversized, "grouping_key"] = (
        group_df.loc[is_oversized, "estate_name"].astype(str)
        + " - B: "
        + block_str.loc[is_oversized]
        + " - SB: "
        + sub_block_str.loc[is_oversized]
    )

    # 2. PRE-AGGREGATION (100% of properties are included)
    estate_groups = group_df.groupby("grouping_key")

    agg_data = []
    for g_key, e_df in estate_groups:
        prop_count = e_df["property_reference"].count()
        agg_data.append(
            {
                "grouping_key": g_key,
                "total_properties": prop_count,
                "Agg_easting": e_df["eastings"].mean(),
                "Agg_northing": e_df["northings"].mean(),
            }
        )

    agg_df = (
        pd.DataFrame(agg_data)
        .sort_values(by="total_properties", ascending=False)
        .reset_index(drop=True)
    )

    # 3. CAPACITY-BALANCED CLUSTERING
    if len(agg_df) < k:
        agg_df["Subgroup_ID"] = [(i % k) + 1 for i in range(len(agg_df))]
        group_df = group_df.merge(
            agg_df[["grouping_key", "Subgroup_ID"]], on="grouping_key", how="left"
        )
    else:
        coords = agg_df[["Agg_easting", "Agg_northing"]].values
        counts = agg_df["total_properties"].values

        # 4 Extreme Corners Initialization
        center = coords.mean(axis=0)
        c1 = coords[np.argmax(np.linalg.norm(coords - center, axis=1))]
        dist_c1 = np.linalg.norm(coords - c1, axis=1)
        c2 = coords[np.argmax(dist_c1)]
        dist_c2 = np.linalg.norm(coords - c2, axis=1)
        c3 = coords[np.argmax(np.minimum(dist_c1, dist_c2))]
        dist_c3 = np.linalg.norm(coords - c3, axis=1)
        c4 = coords[np.argmax(np.minimum(np.minimum(dist_c1, dist_c2), dist_c3))]

        centroids = np.array([c1, c2, c3, c4])
        cluster_multipliers = np.ones(k)
        learning_rate = 0.2  # Increased responsiveness

        for iteration in range(300):
            distances = np.linalg.norm(
                coords[:, np.newaxis, :] - centroids[np.newaxis, :, :], axis=2
            )

            penalized_distances = distances * cluster_multipliers
            labels = np.argmin(penalized_distances, axis=1)

            # Prevent empty clusters (Rescue logic)
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

            # Update Centroids
            new_centroids = np.array(
                [
                    coords[labels == j].mean(axis=0)
                    if np.any(labels == j)
                    else centroids[j]
                    for j in range(k)
                ]
            )
            centroids = new_centroids

            # Exponential Multiplier Scaling (Fast & direct balancing)
            ratio = cluster_weights / target_capacity
            cluster_multipliers = cluster_multipliers * (ratio**learning_rate)

            # Bounds: 0.4 to 2.5 keeps shapes contiguous without overlapping islands
            cluster_multipliers = np.clip(cluster_multipliers, 0.4, 2.5)

        # Apply labels back to ALL properties
        agg_df["Subgroup_ID"] = labels + 1
        group_df = group_df.merge(
            agg_df[["grouping_key", "Subgroup_ID"]], on="grouping_key", how="left"
        )

    processed_groups.append(group_df)


# MAPPING

final_df = pd.concat(processed_groups, ignore_index=True)

# Generate Summary Table
df_group = (
    final_df.groupby(["neighbourhood_area", "Subgroup_ID"])["property_reference"]
    .count()
    .reset_index(name="total_properties")
)
print("--- Patch Summary ---")
print(df_group)
print("---------------------\n")

# Assign Global Cluster IDs (1 through 16)
final_df["Global_Cluster_ID"] = (
    final_df.groupby(["neighbourhood_area", "Subgroup_ID"]).ngroup() + 1
)
df_group["Global_Cluster_ID"] = (
    df_group.groupby(["neighbourhood_area", "Subgroup_ID"]).ngroup() + 1
)

df_group["Legend_Label"] = (
    df_group["neighbourhood_area"]
    + " - Patch "
    + df_group["Subgroup_ID"].astype(int).astype(str)
    + " ("
    + df_group["total_properties"].astype(str)
    + ")"
)

patch_mapping = df_group.set_index("Global_Cluster_ID")["Legend_Label"].to_dict()
plot_df = final_df.dropna(subset=["Subgroup_ID"])

fig, ax = plt.subplots(figsize=(16, 12))

boundaries.plot(
    ax=ax, facecolor="none", edgecolor="dimgrey", linewidth=1.5, linestyle="--"
)

# colours for each cluster
custom_hex_colors = [
    "#FFE600",  # Vivid Yellow (Ultra Bright)
    "#0011B8",  # Deep Royal Blue (Very Dark Blue)
    "#FF0055",  # Electric Neon Pink (Warm Bright)
    "#00FF66",  # Hyper Lime (Light Cool Green)
    "#D800FF",  # Bright Neon Magenta-Purple (Warm Purple)
    "#00E5FF",  # Electric Cyan (Bright Light Blue)
    "#FF5500",  # Vivid Orange (Warm Bright)
    "#3A007D",  # Midnight Purple (Deep Dark Purple)
    "#76FF03",  # Bright Chartreuse (Yellow-Green)
    "#FF00AA",  # Hot Magenta (Vivid Pink)
    "#008941",  # Deep Emerald Green (Dark Green)
    "#FFB700",  # Bright Amber (Warm Yellow-Orange)
    "#99D5FF",  # Ice Blue (Very Light Pastel Blue)
    "#FF0000",  # Bright Pure Red (Warm)
    "#00F5D4",  # Electric Mint (Bright Aqua-Green)
    "#7000FF",  # Electric Violet-Blue (Indigo)
]

custom_cmap = ListedColormap(custom_hex_colors)

scatter = ax.scatter(
    plot_df["eastings"],
    plot_df["northings"],
    c=plot_df["Global_Cluster_ID"],
    cmap=custom_cmap,
    s=15,
    alpha=0.8,
    edgecolors="gray",
    linewidth=0.1,
    zorder=5,
)

unique_ids = sorted(plot_df["Global_Cluster_ID"].unique())
handles, _ = scatter.legend_elements(num=unique_ids)
custom_labels = [patch_mapping[uid] for uid in unique_ids]

legend = ax.legend(
    handles,
    custom_labels,
    title="Neighbourhood Patches (Count)",
    bbox_to_anchor=(1.02, 1),
    loc="upper left",
    ncol=1,
    fontsize=10,
    title_fontsize=11,
)
ax.add_artist(legend)

area_col = (
    "neighbourhood_area"
    if "neighbourhood_area" in boundaries.columns
    else ("NAME" if "NAME" in boundaries.columns else boundaries.columns[0])
)

# add specific locations for labels
label_positions = {
    "North West": (531500, 186000),
    "North East": (536100, 187000),
    "Central": (536000, 183500),
    "South": (532100, 182500),
}

for idx, row in boundaries.iterrows():
    area_name = str(row[area_col])

    # Check if custom coordinates exist for this area
    if area_name in label_positions:
        text_x, text_y = label_positions[area_name]
    else:
        # Fallback: Placed just outside the top-left of the bounding box if not in dictionary
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

plt.title("Spatial Clustering Balance: All Neighbourhood Areas")
plt.xlabel("Easting")
plt.ylabel("Northing")
plt.grid(True, linestyle=":", alpha=0.5)
plt.axis("equal")
plt.subplots_adjust(right=0.75)

if out_path:
    plt.savefig(
        f"{out_path}neighbourhood_areas_clusters_v1.png", dpi=300, bbox_inches="tight"
    )

plt.show()
