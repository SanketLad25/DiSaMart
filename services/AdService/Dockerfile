FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY src/DiSaMart.AdService.Api/DiSaMart.AdService.Api.csproj ./DiSaMart.AdService.Api/
RUN dotnet restore ./DiSaMart.AdService.Api/DiSaMart.AdService.Api.csproj
COPY src/DiSaMart.AdService.Api/. ./DiSaMart.AdService.Api/
RUN dotnet publish ./DiSaMart.AdService.Api/DiSaMart.AdService.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080 ASPNETCORE_ENVIRONMENT=Production
COPY --from=build /app/publish .
EXPOSE 8080
USER $APP_UID
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD wget -qO- http://127.0.0.1:8080/health/live || exit 1
ENTRYPOINT ["dotnet", "DiSaMart.AdService.Api.dll"]
