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


function Dominio{

   Clear-Host
   Write-Host "`n`t`t TI`n"
   $hostname = Read-Host "`t"'Nome da Máquina ( ' $env:computername ' )'
   $dominio = Read-Host "`t"'Domínio'
   $usuario = Read-Host "`t"'Usuário'
   $password = Read-Host "`t"'Senha' -AsSecureString
   
   $Cred = New-Object System.Management.Automation.PSCredential("$dominio\$usuario", $password)
   Write-Host "`t""Adicionando máquina $hostname ao domínio $dominio"
   ElevarPrivilegios
   
   Try {
    # Tenta adicionar a máquina ao AD
    if ($hostname -match $env:computername -or [string]::IsNullOrWhiteSpace($hostname)) {
        Add-Computer -Domain $dominio -Credential $Cred -ErrorAction Stop
    } else {
        Add-Computer -Domain $dominio -NewName $hostname -Credential $Cred -ErrorAction Stop
    }
    Write-Host "Máquina adicionada ao Active Directory com sucesso."
    } Catch [System.Management.Automation.RuntimeException] {
    # Erro genérico para problemas de runtime
    Write-Host "Erro: Ocorreu um problema ao adicionar a máquina ao AD."
    } Catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException] {
    # Erro específico se a máquina já existe no AD
    Write-Host "Erro: A máquina já existe no Active Directory."
    } Catch [System.Management.Automation.PSArgumentException] {
    # Erro específico para argumentos inválidos, como credenciais erradas
    Write-Host "Erro: As credenciais fornecidas estão incorretas."
    } Catch [System.Net.NetworkInformation.NetworkInformationException] {
    # Erro específico se a rede está offline
    Write-Host "Erro: Não foi possível conectar ao Active Directory. Verifique sua conexão de rede."
    } Catch {
    # Captura qualquer outra exceção não especificada anteriormente
    Write-Host "Ocorreu um erro inesperado: $($_.Exception.Message)"
    }

}

Dominio
