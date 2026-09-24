import geopandas as gpd
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.colors import ListedColormap

#  import local variables


# 1. Load Data
file_path = FILE_PATH
shapefile_path = SHP_PATH

df = pd.read_csv(file_path, low_memory=False)
boundaries = gpd.read_file(shapefile_path)

# Filter criteria
df = df[
    (df["dwelling_flag"] == True)
    & (df["out_of_borough_flag"] == False)
    & (df["tmo_flag"] == False)
    & (df["leasehold_flag"] == False)
]

processed_groups = []

for area_name, group_df in df.groupby("neighbourhood_area"):

    # 1. SPLIT DATA
    has_estate = group_df[group_df["estate_name"].notna()].copy()
    no_estate = group_df[group_df["estate_name"].isna()].copy()

    if len(has_estate) == 0:
        has_estate = no_estate.copy()
        has_estate["estate_name"] = "Standalone_" + has_estate.index.astype(str)
        no_estate = pd.DataFrame(columns=group_df.columns)

    # --- DYNAMIC MULTI-LEVEL SPLITTING FOR LARGE ESTATES ---
    k = 4
    target_capacity = len(has_estate) / k

    # Calculate how big each estate is
    estate_counts = has_estate["estate_name"].value_counts()

    # Lowered threshold to 50% so more large estates get broken down into manageable geographic chunks
    oversized_estates = estate_counts[estate_counts > (target_capacity * 0.4)].index

    # Base grouping key is the estate name
    has_estate["grouping_key"] = has_estate["estate_name"]
    is_oversized = has_estate["estate_name"].isin(oversized_estates)

    # Prepare fallback text for missing blocks and sub-blocks
    block_str = has_estate["block_name"].fillna("Unspecified_Block").astype(str)

    # If there is no sub-block, fall all the way back to the individual property reference.
    # This guarantees the oversized estate is broken down to the finest possible level.
    if "sub_block_name" in has_estate.columns:
        sub_block_str = (
            has_estate["sub_block_name"]
            .fillna("Standalone_" + has_estate["property_reference"].astype(str))
            .astype(str)
        )
    else:
        # Safety net just in case the column is named differently
        sub_block_str = "Standalone_" + has_estate["property_reference"].astype(str)

    # Build the ultra-granular grouping key for oversized estates
    has_estate.loc[is_oversized, "grouping_key"] = (
        has_estate.loc[is_oversized, "estate_name"].astype(str)
        + " - B: "
        + block_str.loc[is_oversized]
        + " - SB: "
        + sub_block_str.loc[is_oversized]
    )

    # 2. PRE-AGGREGATION (Using 'grouping_key')
    estate_groups = has_estate.groupby("grouping_key")

    agg_data = []
    for g_key, e_df in estate_groups:
        prop_count = e_df["property_reference"].count()
        if prop_count > 0:
            avg_easting = e_df["eastings"].mean()
            avg_northing = e_df["northings"].mean()
        else:
            avg_easting = e_df["eastings"].mean()
            avg_northing = e_df["northings"].mean()

        agg_data.append(
            {
                "grouping_key": g_key,
                "total_properties": prop_count,
                "Agg_easting": avg_easting,
                "Agg_northing": avg_northing,
            }
        )

    agg_df = (
        pd.DataFrame(agg_data)
        .sort_values(by="total_properties", ascending=False)
        .reset_index(drop=True)
    )

    # 3. CLUSTERING
    if len(agg_df) < k:
        # Edge case: Less than 4 units total
        agg_df["Subgroup_ID"] = [(i % k) + 1 for i in range(len(agg_df))]
        has_estate = has_estate.merge(
            agg_df[["grouping_key", "Subgroup_ID"]], on="grouping_key", how="left"
        )

        centroids = np.zeros((k, 2))
        for j in range(k):
            sub_pts = has_estate[has_estate["Subgroup_ID"] == j + 1]
            if len(sub_pts) > 0:
                centroids[j] = sub_pts[["eastings", "northings"]].mean().values
            else:
                centroids[j] = has_estate[["eastings", "northings"]].mean().values
    else:
        coords = agg_df[["Agg_easting", "Agg_northing"]].values
        counts = agg_df["total_properties"].values

        # --- NEW GEOGRAPHIC INITIALIZATION (4 Extreme Corners) ---
        center = coords.mean(axis=0)
        c1 = coords[np.argmax(np.linalg.norm(coords - center, axis=1))]

        dist_c1 = np.linalg.norm(coords - c1, axis=1)
        c2 = coords[np.argmax(dist_c1)]

        dist_c2 = np.linalg.norm(coords - c2, axis=1)
        c3 = coords[np.argmax(np.minimum(dist_c1, dist_c2))]

        dist_c3 = np.linalg.norm(coords - c3, axis=1)
        c4 = coords[np.argmax(np.minimum(np.minimum(dist_c1, dist_c2), dist_c3))]

        centroids = np.array([c1, c2, c3, c4])
        # ---------------------------------------------------------

        target_capacity = counts.sum() / k
        cluster_multipliers = np.ones(k)
        learning_rate = 0.05  # Lower learning rate for smoother boundaries

        for iteration in range(200):
            distances = np.linalg.norm(
                coords[:, np.newaxis, :] - centroids[np.newaxis, :, :], axis=2
            )

            penalized_distances = distances * cluster_multipliers
            labels = np.argmin(penalized_distances, axis=1)

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
            cluster_multipliers = cluster_multipliers * (
                1 + learning_rate * (ratio - 1)
            )

            # Tighter penalty limits to prevent overlapping islands
            cluster_multipliers = np.clip(cluster_multipliers, 0.5, 2.0)

        # Apply labels back to properties using grouping_key
        agg_df["Subgroup_ID"] = labels + 1
        has_estate = has_estate.merge(
            agg_df[["grouping_key", "Subgroup_ID"]], on="grouping_key", how="left"
        )

    # 4. ASSIGN ISOLATED PROPERTIES TO THE NEAREST CLUSTER
    if len(no_estate) > 0:
        unassigned_coords = no_estate[["eastings", "northings"]].values

        point_distances = np.linalg.norm(
            unassigned_coords[:, np.newaxis, :] - centroids[np.newaxis, :, :], axis=2
        )

        no_estate["Subgroup_ID"] = np.argmin(point_distances, axis=1) + 1

    # 5. RECOMBINE FOR THIS AREA
    final_group_df = pd.concat([has_estate, no_estate], ignore_index=True)
    processed_groups.append(final_group_df)

# ==========================================
# POST-PROCESSING & MAPPING (OUTSIDE LOOP)
# ==========================================

# 1. Combine all areas together
final_df = pd.concat(processed_groups, ignore_index=True)

# 2. Generate the Summary Table FIRST (so we have the counts for the legend)
df_group = (
    final_df.groupby(["neighbourhood_area", "Subgroup_ID"])["property_reference"]
    .count()
    .reset_index(name="total_properties")
)
print("--- Patch Summary ---")
print(df_group)
print("---------------------\n")

# 3. Create Global Cluster IDs (1 through 16)
# We apply this to both the main dataframe and our summary table so they link up perfectly
final_df["Global_Cluster_ID"] = (
    final_df.groupby(["neighbourhood_area", "Subgroup_ID"]).ngroup() + 1
)
df_group["Global_Cluster_ID"] = (
    df_group.groupby(["neighbourhood_area", "Subgroup_ID"]).ngroup() + 1
)

# 4. Construct the Legend Labels using the counts from the summary table
# This formats the text as: "North West - Patch 1 (2500)"
df_group["Legend_Label"] = (
    df_group["neighbourhood_area"]
    + " - Patch "
    + df_group["Subgroup_ID"].astype(int).astype(str)
    + " ("
    + df_group["total_properties"].astype(str)
    + ")"
)

# Create a dictionary to map the Global_Cluster_ID to this new rich label
patch_mapping = df_group.set_index("Global_Cluster_ID")["Legend_Label"].to_dict()

# 5. Clean up for plotting
plot_df = final_df.dropna(subset=["Subgroup_ID"])

# 6. Visualise the Entire City
fig, ax = plt.subplots(
    figsize=(16, 12)
)  # Adjusted ratio slightly to leave room for legend

boundaries.plot(
    ax=ax, facecolor="none", edgecolor="dimgrey", linewidth=1.5, linestyle="--"
)

## 16 highly distinct, high-contrast colors
custom_hex_colors = [
    "#E6194B",  # Vivid Red
    "#3CB44B",  # Green
    "#FFE119",  # Yellow
    "#4363D8",  # Blue
    "#F58231",  # Orange
    "#911EB4",  # Purple
    "#42D4F4",  # Cyan
    "#F032E6",  # Magenta
    "#BFEEF4",  # Light Blue
    "#FABEBE",  # Pink
    "#469990",  # Teal
    "#E6BEFF",  # Lavender
    "#9A6324",  # Brown
    "#FFFAC8",  # Beige
    "#800000",  # Maroon
    "#AAFFC3",  # Mint
]
# Convert the hex list into a Matplotlib colormap
custom_cmap = ListedColormap(custom_hex_colors)

# Map Points
scatter = ax.scatter(
    plot_df["eastings"],
    plot_df["northings"],
    c=plot_df["Global_Cluster_ID"],
    cmap=custom_cmap,  # <--- Apply the new custom colormap here
    s=15,
    alpha=0.8,  # Increased opacity slightly to make colors pop
    edgecolors="black",
    linewidth=0.3,
    zorder=5,
)

# --- NEW LEGEND LOGIC ---
# 1. Get the exact list of unique IDs first (all 16 of them)
unique_ids = sorted(plot_df["Global_Cluster_ID"].unique())

# 2. FORCE Matplotlib to generate a color handle for every single ID in that list
handles, _ = scatter.legend_elements(num=unique_ids)

# 3. Retrieve the matching text label with the property count for each ID
custom_labels = [patch_mapping[uid] for uid in unique_ids]

# 4. Build the legend outside the plot area on the right
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

plt.title("Spatial Clustering Balance: All Neighbourhood Areas")
plt.xlabel("Easting")
plt.ylabel("Northing")
plt.grid(True, linestyle=":", alpha=0.5)
plt.axis("equal")
plt.subplots_adjust(right=0.75)

# If you want to save it to a file, this guarantees the legend is included in the image
plt.savefig(OUT_PATH, dpi=300, bbox_inches="tight")

plt.show()
