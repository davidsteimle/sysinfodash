FROM ubuntu:latest

RUN apt install nodejs -y
RUN apt install npm -y
RUN npm install sqlite3 -y

COPY dash.ps1 dash.ps1

CMD ["pwsh", "-File", "dash.ps1", "-Port", "8082"]
