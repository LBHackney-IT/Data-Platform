#TEST_DEV= ./state-migration.sh -dry-run 2>&1 | tee state-migration-output
#TEST_STAGING= ./state-migration.sh staging -dry-run 2>&1 | tee state-migration-output
#TEST_PRODUCTION= ./state-migration.sh production -dry-run 2>&1 | tee state-migration-output
#FOR_REAL_DEV= ./state-migration.sh 2>&1 | tee state-migration-output
#FOR_REAL_STAGING= ./state-migration.sh staging 2>&1 | tee state-migration-output
#FOR_REAL_PRODUCTION= ./state-migration.sh production 2>&1 | tee state-migration-output

rm -f state-migration-output
FILES="../etl/*.tf"
for f in $FILES
do
    grep -Eo -e '^module \".*\"' -e '^data \".*\"' "$f" | tr -s " \"" "." | sed 's/\.$//' | \
    while read -r resource_address; do aws-vault exec hackney-dataplatform-"${1:-development}" -- terraform state mv $2 -state-out=./tfstate-etl.tfstate "$resource_address" "$resource_address"; done

    grep -Eo '^resource \".*\"' "$f" | tr -s " \"" "." | sed 's/\.$//' | sed 's/^resource\.//' | \
    while read -r resource_address; do aws-vault exec hackney-dataplatform-"${1:-development}" -- terraform state mv $2 -state-out=./tfstate-etl.tfstate "$resource_address" "$resource_address"; done;
done

cp ./tfstate-etl.tfstate ../etl/tfstate-etl.tfstate
cd ../etl || exit
aws-vault exec hackney-dataplatform-"${1:-development}" -- terraform init
aws-vault exec hackney-dataplatform-"${1:-development}" -- terraform workspace select "${3:-ryanbratten}"
aws-vault exec hackney-dataplatform-"${1:-development}" -- terraform state push -force ./tfstate-etl.tfstate
