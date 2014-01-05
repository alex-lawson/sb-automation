@echo off
echo { >testplayer.config
echo   "__merge": [], >>testplayer.config
echo   "defaultBlueprints" : { >>testplayer.config
echo     "tier1" : [ >>testplayer.config
for /r recipes\ %%a in (*.recipe) do (
  echo       { "item" : "%%~na" }, >>testplayer.config
)
for /r recipes_creative\ %%a in (*.recipe) do (
  echo       { "item" : "%%~na" }, >>testplayer.config
)
echo     ] >>testplayer.config
echo   } >>testplayer.config
echo } >>testplayer.config
pause