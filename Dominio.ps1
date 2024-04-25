function ElevarPrivilegios{
    param([switch]$Elevated)

    function Test-Admin {
        $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    if ((Test-Admin) -eq $false)  {
        if ($elevated) {
        # tried to elevate, did not work, aborting
    } 
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
	}

	exit
    }

    Write-Host "`t`t Executando com privilégios elevados"
}

function Add-ComputerToDomain {
    param(
        [Parameter(Mandatory = $true)]
        [string] $NewComputerName,
        
        [Parameter(Mandatory = $true)]
        [string] $Domain,
        
        [Parameter(Mandatory = $true)]
        [PSCredential] $Credential
    )

    try {       
        # Adiciona o computador ao domínio
        if ($NewComputerName -match $env:computername) {
            Add-Computer -DomainName $Domain -Credential $Credential -ErrorAction Stop
        } 
        else {
            Add-Computer -DomainName $Domain -NewName $NewComputerName -Credential $Credential -ErrorAction Stop
        }
        Write-Host "Computador '$NewComputerName' adicionado com sucesso ao domínio '$Domain'."
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Acesso negado. Verifique se você tem as permissões necessárias para adicionar computadores ao domínio e renomear computadores."
    }
    Catch [System.Management.Automation.PSArgumentException] {
        Write-Error "Erro: As credenciais fornecidas estão incorretas."
    } 
    Catch [System.Net.NetworkInformation.NetworkInformationException] {
        Write-Error "Erro: Não foi possível conectar ao Active Directory. Verifique sua conexão de rede."
    }
    Catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException] {
        Write-Error "Erro: A máquina já existe no Active Directory."
    }
    catch {
        Write-Error "Um erro inesperado ocorreu: $_"
    }
}

Clear-Host
Write-Host "`n`t`t TI`n"
$hostname = Read-Host "`t"'Nome da Máquina ( ' $env:computername ' )'
$dominio = Read-Host "`t"'Domínio'
$usuario = Read-Host "`t"'Usuário'
$password = Read-Host "`t"'Senha' -AsSecureString
  
$cred = New-Object System.Management.Automation.PSCredential("$dominio\$usuario", $password)
ElevarPrivilegios
if ([string]::IsNullOrWhiteSpace($hostname)) {
    $hostname = $env:computername 
}
Add-ComputerToDomain -NewComputerName $hostname -Domain $dominio -Credential $cred
