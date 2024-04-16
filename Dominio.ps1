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

    Write-Host "`t`t Executando com privil�gios elevados"
}


function Dominio{

   Clear-Host
   Write-Host "`n`t`t TI`n"
   $hostname = Read-Host "`t"'Nome da M�quina ( ' $env:computername ' )'
   $dominio = Read-Host "`t"'Dom�nio'
   $usuario = Read-Host "`t"'Usu�rio'
   $password = Read-Host "`t"'Senha' -AsSecureString
   
   $Cred = New-Object System.Management.Automation.PSCredential("$dominio\$usuario", $password)
   Write-Host "`t""Adicionando m�quina $hostname ao dom�nio $dominio"
   ElevarPrivilegios
   
   Try {
    # Tenta adicionar a m�quina ao AD
    if ($hostname -match $env:computername -or [string]::IsNullOrWhiteSpace($hostname)) {
        Add-Computer -Domain $dominio -Credential $Cred -ErrorAction Stop
    } else {
        Add-Computer -Domain $dominio -NewName $hostname -Credential $Cred -ErrorAction Stop
    }
    Write-Host "M�quina adicionada ao Active Directory com sucesso."
    } Catch [System.Management.Automation.RuntimeException] {
    # Erro gen�rico para problemas de runtime
    Write-Host "Erro: Ocorreu um problema ao adicionar a m�quina ao AD."
    } Catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException] {
    # Erro espec�fico se a m�quina j� existe no AD
    Write-Host "Erro: A m�quina j� existe no Active Directory."
    } Catch [System.Management.Automation.PSArgumentException] {
    # Erro espec�fico para argumentos inv�lidos, como credenciais erradas
    Write-Host "Erro: As credenciais fornecidas est�o incorretas."
    } Catch [System.Net.NetworkInformation.NetworkInformationException] {
    # Erro espec�fico se a rede est� offline
    Write-Host "Erro: N�o foi poss�vel conectar ao Active Directory. Verifique sua conex�o de rede."
    } Catch {
    # Captura qualquer outra exce��o n�o especificada anteriormente
    Write-Host "Ocorreu um erro inesperado: $($_.Exception.Message)"
    }

}

Dominio
