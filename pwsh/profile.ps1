oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/night-owl.omp.json" | Invoke-Expression

function GetIIS {
    Get-Process | Where-Object -Property ProcessName -Match "iis"
}

function KillIIS {
    GetIIS | Where-Object -Property ProcessName -Match "iis" | Stop-Process -Force
}

$monolith = Join-Path $env:FORM1 'Blikk\code\monolith'
$tools = Join-Path $env:FORM1 'tools'
$config = Join-Path $env:FORM1 'Blikk\config'

function GHCIPrompt {
    ghci
}

function InvoiceFrontend {
    cd $monolith\Blikk.Web\Scripts\app\blikk-vue; 
    npm install;
    npm run dev;
}

function CleanMonolith {
    cd $monolith;
    Write-Host "Cleaning monolith..."
    Write-Host "Deleting project local bin/obj"
    fd "Blikk\.[^\\]+\\(bin|obj)$" -t d -u -p | ForEach-Object { rm $_ -Recurse -Force }
    Get-ChildItem .\ -include bin,obj -Recurse -Depth 3 | foreach ($_) { remove-item $_.fullname -Force -Recurse }
    Write-Host "Deleting shared output folder contents"
    Remove-Item .\output\build\* -Recurse -Force
    Write-Host "Done"
    #Write-Host "Copying excel to signalrweb"
    #mkdir .\Blikk.SignalrWeb\bin > $null
    #cp .\packages\Excel.1.0.0\lib\dotnet\Excel.dll .\Blikk.SignalrWeb\bin\
    #Write-Host "Done"
}

function FullCleanMonolith {
    cd $monolith;
    CleanMonolith;
    Write-Host "Deleting .vs folder"
    Remove-Item .\.vs -Recurse -Force
    Write-Host "Done"
}

function SimpleDotnetTest {
    param (
        $project
    )

    dotnet test $project -v m --nologo /clp:ErrorsOnly
}

function InvoiceTests {
    cd $monolith;
    SimpleDotnetTest Blikk.Invoice.DataTests .\Blikk.Tests\Blikk.Tests.csproj
    SimpleDotnetTest Blikk.Invoice.ApplicationTests .\Blikk.Tests\Blikk.Tests.csproj
    SimpleDotnetTest Blikk.Invoice.DomainTests .\Blikk.Tests\Blikk.Tests.csproj
}

function StartAzurite {
    Start-Process -FilePath 'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator\azurite.exe' -ArgumentList "-l `"C:\Users\OlleJernelöf\dev\Form1\Blikk\storage\azurite`"" -WindowStyle Hidden
}

function StopAzurite {
    Get-Process | Where-Object -Property ProcessName -Match "azurite" | Stop-Process -Force
}

function Explore {
    explorer .
}

function Todo {
    nvim -o $HOME\docs\continuous\todo.md $HOME\docs\continuous\retrospects\platform\nextRetro.md
}


$env:PYTHONIOENCODING='utf-8'

iex "$(thefuck --alias)"

