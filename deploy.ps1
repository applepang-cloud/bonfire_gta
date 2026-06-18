# GitHub Pages 배포: 웹 빌드(/bonfire_gta/) → gh-pages 브랜치 푸시
$ErrorActionPreference = "Stop"
flutter build web --no-tree-shake-icons --base-href /bonfire_gta/
$tmp = Join-Path $env:TEMP "gta_pages_deploy"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory $tmp | Out-Null
Copy-Item "build\web\*" $tmp -Recurse
New-Item -ItemType File (Join-Path $tmp ".nojekyll") | Out-Null
Push-Location $tmp
git init -q
git checkout -q -b gh-pages
git add -A
git -c user.name="applepang-cloud" -c user.email="applepang@thebricks.kr" commit -q -m "Deploy GitHub Pages"
git remote add origin https://github.com/applepang-cloud/bonfire_gta.git
git push -q -f origin gh-pages
Pop-Location
Write-Host "Deployed -> https://applepang-cloud.github.io/bonfire_gta/"
