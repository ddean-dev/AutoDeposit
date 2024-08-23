set -a && source .env && set +a
rm -r "$WOW_ADDONS_FOLDER/AutoDeposit"
git submodule update
bash .packager/release.sh
mv ".release/AutoDeposit" "$WOW_ADDONS_FOLDER/AutoDeposit"
