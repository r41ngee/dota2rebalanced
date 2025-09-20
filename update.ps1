$contentPath = "G:\SteamLibrary\steamapps\common\dota 2 beta\content\dota_addons\dota_rebalanced\*"
$gamePath = "G:\SteamLibrary\steamapps\common\dota 2 beta\game\dota_addons\dota_rebalanced\*"

Copy-Item -Path $contentPath -Destination "./content";
Copy-Item -Path $gamePath -Destination "./game";