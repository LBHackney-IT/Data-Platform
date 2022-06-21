#./state-migration.sh development 2>&1 | tee state-migration-output
rm -f state-migration-output
FILES="../etl/*.tf"
for f in $FILES
do
    grep -Eo -e '^module \".*\"' -e '^data \".*\"' "$f" | tr -s " \"" "." | sed 's/\.$//' | \
    while read -r resource_address; do aws-vault exec hackney-dataplatform-"${1}" -- terraform state mv -dry-run -state-out=./tfstate-etl.tfstate "$resource_address" "$resource_address"; done

    grep -Eo '^resource \".*\"' "$f" | tr -s " \"" "." | sed 's/\.$//' | sed 's/^resource\.//' | \
    while read -r resource_address; do aws-vault exec hackney-dataplatform-"${1}" -- terraform state mv -dry-run -state-out=./tfstate-etl.tfstate "$resource_address" "$resource_address"; done;
done

#cp ./tfstate-etl.tfstate ../etl/tfstate-etl.tfstate
#cd ../etl || exit
#aws-vault exec hackney-dataplatform-"${1}" -- terraform init
#aws-vault exec hackney-dataplatform-"${1}" -- terraform workspace select default
#aws-vault exec hackney-dataplatform-"${1}" -- terraform state push ./tfstate-etl.tfstate
