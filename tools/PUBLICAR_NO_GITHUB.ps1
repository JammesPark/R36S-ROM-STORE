# Publicacao da R36S ROMS STORE (repositorio substituido apos backup do usuario)
$ErrorActionPreference = "Stop"
$NewRepo = "JammesPark/R36S-ROMS-HUB-STORE"
$Src = Split-Path -Parent $PSScriptRoot
function Need($command) {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
    throw "Comando '$command' nao encontrado. Instale Git e GitHub CLI (gh) e tente novamente."
  }
}
Need git
Need gh
if (-not (Test-Path (Join-Path $Src '.github/workflows/build.yml'))) { throw 'Projeto incompleto: nao ha workflow.' }
& gh auth status -h github.com
if ($LASTEXITCODE -ne 0) { throw 'Execute: gh auth login -h github.com' }

$Work = Join-Path $env:TEMP ('r36s-roms-store-upload-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $Work | Out-Null
try {
  # NUNCA apaga arquivos na pasta pessoal: trabalha em um clone temporario.
  Write-Host 'Clonando R36S-ROMS-HUB-STORE para pasta temporaria...'
  & gh repo clone $NewRepo $Work
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao clonar repositorio.' }
  Push-Location $Work
  try {
    & git checkout main
    if ($LASTEXITCODE -ne 0) { throw 'Branch main nao encontrada.' }
    & git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Falha no pull; nada foi publicado.' }
    # Apenas no clone, remover arquivos antigos do indice e disco.
    & git rm -r -f -- .
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao limpar arquivos do clone.' }
    # Restaurar a nova arvore pronta, com diretorios ocultos e workflows.
    Get-ChildItem -LiteralPath $Src -Force | Where-Object { $_.Name -notin @('.git','build','dist') } | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination $Work -Recurse -Force
    }
    & git add -A
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao adicionar a nova arvore.' }
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { throw 'Nenhuma alteracao detectada para publicar.' }
    & git config user.name | Out-Null
    if ($LASTEXITCODE -ne 0) { & git config user.name 'R36S ROMS STORE' }
    & git config user.email | Out-Null
    if ($LASTEXITCODE -ne 0) { & git config user.email 'r36s-roms-store@users.noreply.github.com' }
    & git commit -m 'Publicar R36S ROMS STORE com GitHub Actions'
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao gravar commit local.' }
    & git push origin main
    if ($LASTEXITCODE -ne 0) { throw 'Falha no push. Repositorio remoto nao foi alterado por esse passo.' }
  } finally { Pop-Location }
  Write-Host "Publicado em https://github.com/$NewRepo/actions"
} finally {
  # Os arquivos do clone podem ser apagados depois do push.
  if (Test-Path $Work) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
}
