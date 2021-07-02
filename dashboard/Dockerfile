FROM mcr.microsoft.com/powershell:latest

SHELL ["pwsh", "-Command"]

RUN Install-Module UniversalDashboard.Community -AcceptLicense

COPY dash.ps1 dash.ps1

CMD ["pwsh", "-File", "dash.ps1", "-Port", "8082"]
