FROM mcr.microsoft.com/powershel:latest

SHELL ["pwsh", "-Command"]

RUN Install-Module -Name Polaris -Force
RUN Install-Module -Name PSSQLite -Force

COPY api.ps1 api.ps1

CMD ["pwsh", "-File", "api.ps1", "-Port", "8082"]
