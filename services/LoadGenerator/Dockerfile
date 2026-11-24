FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY src/DiSaMart.LoadGenerator.Api/DiSaMart.LoadGenerator.Api.csproj ./DiSaMart.LoadGenerator.Api/
RUN dotnet restore ./DiSaMart.LoadGenerator.Api/DiSaMart.LoadGenerator.Api.csproj
COPY src/DiSaMart.LoadGenerator.Api/. ./DiSaMart.LoadGenerator.Api/
RUN dotnet publish ./DiSaMart.LoadGenerator.Api/DiSaMart.LoadGenerator.Api.csproj -c Release -o /app/publish /p:UseAppHost=false
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080 ASPNETCORE_ENVIRONMENT=Production
COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD wget -qO- http://127.0.0.1:8080/health/live || exit 1
ENTRYPOINT ["dotnet", "DiSaMart.LoadGenerator.Api.dll"]
