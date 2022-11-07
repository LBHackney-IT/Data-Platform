from datetime import date

from freezegun import freeze_time

from scripts.jobs.env_services.alloy_api_export import create_s3_key


@freeze_time("2022-11-07")
class TestCreateS3Key:
    def test_no_prefix_no_import_date(self):
        output = create_s3_key(s3_prefix="my/s3/prefix/", file="I_Hate_horses.csv")
        assert output == "my/s3/prefix/i_hate_horses/"

    def test_no_import_date(self):
        output = create_s3_key(
            s3_prefix="my/s3/prefix/",
            file="I_Hate_horses.csv",
            prefix_to_remove="I_Hate_",
        )
        assert output == "my/s3/prefix/horses/"

    def test_no_prefix(self):
        output = create_s3_key(
            s3_prefix="my/s3/prefix/",
            file="I_Hate_horses.csv",
            import_date=date.today(),
        )
        assert (
            output
            == "my/s3/prefix/i_hate_horses/import_year=2022/import_month=11/import_day=07/import_date=20221107/"
        )

    def test_import_date_and_prefix(self):
        output = create_s3_key(
            s3_prefix="my/s3/prefix/",
            file="I_Hate_horses.csv",
            prefix_to_remove="I_Hate_",
            import_date=date.today(),
        )
        assert (
            output
            == "my/s3/prefix/horses/import_year=2022/import_month=11/import_day=07/import_date=20221107/"
        )

    def test_prefix_arg_not_in_filename(self):
        output = create_s3_key(
            s3_prefix="my/s3/prefix/",
            file="I_Hate_horses.csv",
            prefix_to_remove="I_Love_",
            import_date=date.today(),
        )
        assert (
            output
            == "my/s3/prefix/i_hate_horses/import_year=2022/import_month=11/import_day=07/import_date=20221107/"
        )

    def test_prefix_case_insensitive(self):
        output = create_s3_key(
            s3_prefix="my/s3/prefix/",
            file="I_Hate_horses.csv",
            prefix_to_remove="i_HaTe_",
            import_date=date.today(),
        )
        assert (
            output
            == "my/s3/prefix/horses/import_year=2022/import_month=11/import_day=07/import_date=20221107/"
        )

    def test_include_file_name_in_key(self):
        output = create_s3_key(
            s3_prefix="my/s3/prefix/",
            file="I_Hate_horses.csv",
            prefix_to_remove="i_HaTe_",
            import_date=date.today(),
            include_file_name=True,
        )
        assert (
            output
            == "my/s3/prefix/horses/import_year=2022/import_month=11/import_day=07/import_date=20221107/I_Hate_horses.csv"
        )
