FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY src/DiSaMart.CurrencyService.Api/DiSaMart.CurrencyService.Api.csproj ./DiSaMart.CurrencyService.Api/
RUN dotnet restore ./DiSaMart.CurrencyService.Api/DiSaMart.CurrencyService.Api.csproj
COPY src/DiSaMart.CurrencyService.Api/. ./DiSaMart.CurrencyService.Api/
RUN dotnet publish ./DiSaMart.CurrencyService.Api/DiSaMart.CurrencyService.Api.csproj -c Release -o /app/publish /p:UseAppHost=false
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
ENV ASPNETCORE_HTTP_PORTS=8080 ASPNETCORE_ENVIRONMENT=Production
COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD curl -fsS http://127.0.0.1:8080/health/live || exit 1
ENTRYPOINT ["dotnet", "DiSaMart.CurrencyService.Api.dll"]
