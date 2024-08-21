set -a && source .env && set +a
rm -r "$WOW_ADDONS_FOLDER/NibTweaks"
git submodule update
bash .packager/release.sh
mv ".release/NibTweaks" "$WOW_ADDONS_FOLDER/NibTweaks"
