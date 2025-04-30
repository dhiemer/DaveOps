# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["alert-dispatcher-svc.csproj", "./"]
RUN dotnet restore "./alert-dispatcher-svc.csproj"

COPY . .
RUN dotnet publish "./alert-dispatcher-svc.csproj" -c Release -o /app/publish

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "alert-dispatcher-svc.dll"]
