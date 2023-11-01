CREATE OR REPLACE PROCEDURE stage_and_load_parquet(
        s3_path VARCHAR,
        iam_role VARCHAR,
        target_table_name VARCHAR
    ) LANGUAGE plpgsql AS $$ BEGIN -- Dynamically create and load the staging table
    EXECUTE format(
        '
        CREATE TABLE IF NOT EXISTS %s_staging (LIKE %s);
        COPY %s_staging FROM %L
        IAM_ROLE %L
        FORMAT AS PARQUET;
    ',
        target_table_name,
        target_table_name,
        target_table_name,
        s3_path,
        iam_role
    );
-- Swap: Delete from main table and insert from staging table
EXECUTE format(
    '
        DELETE FROM %s;
        INSERT INTO %s SELECT * FROM %s_staging;
        TRUNCATE %s_staging;
    ',
    target_table_name,
    target_table_name,
    target_table_name,
    target_table_name
);
END;
$$;