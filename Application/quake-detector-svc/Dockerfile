# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["quake-detector-svc.csproj", "./"]
RUN dotnet restore "./quake-detector-svc.csproj"

COPY . .
RUN dotnet publish "./quake-detector-svc.csproj" -c Release -o /app/publish

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "quake-detector-svc.dll"]
