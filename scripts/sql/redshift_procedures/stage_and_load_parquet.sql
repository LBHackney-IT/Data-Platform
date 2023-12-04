CREATE OR REPLACE PROCEDURE housing_rs.stage_and_load_parquet(
        s3_path VARCHAR,
        iam_role VARCHAR,
        schema_name VARCHAR,
        table_name VARCHAR
    ) AS $$ 
    BEGIN 
        -- Create the staging table
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I.%I_staging (LIKE %I.%I);',
            schema_name,
            table_name,
            schema_name,
            table_name
        );
        -- Load data from S3 into the staging table
        EXECUTE format(
            'COPY %I.%I_staging FROM %L FORMAT AS PARQUET IAM_ROLE %L;',
            schema_name,
            table_name,
            s3_path,
            iam_role
        );
        -- Insert data from staging to main table
        EXECUTE format(
            'INSERT INTO %I.%I SELECT * FROM %I.%I_staging;',
            schema_name,
            table_name,
            schema_name,
            table_name
        );
        -- Truncate staging table
        EXECUTE format(
            'TRUNCATE %I.%I_staging;',
            schema_name,
            table_name
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
        RAISE EXCEPTION 'Error loading tables, rolling back';
        ROLLBACK;
    END;
$$ LANGUAGE plpgsql;