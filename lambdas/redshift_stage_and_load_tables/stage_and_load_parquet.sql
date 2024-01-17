BEGIN 
    -- Create the staging table
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I.%I_staging (LIKE %I.%I);',
        {schema_name},
        {table_name},
        {schema_name},
        {table_name}
    );
    -- Load data from S3 into the staging table
    EXECUTE format(
        'COPY %I.%I_staging FROM %L FORMAT AS PARQUET iam_role %L;',
        {schema_name},
        {table_name},
        {s3_path},
        {iam_role}
    );
    -- Insert data from staging to main table
    EXECUTE format(
        'INSERT INTO %I.%I SELECT * FROM %I.%I_staging;',
        {schema_name},
        {table_name},
        {schema_name},
        {table_name}
    );
    -- Truncate staging table
    EXECUTE format(
        'TRUNCATE %I.%I_staging;',
        {schema_name},
        {table_name}
    );
COMMIT;