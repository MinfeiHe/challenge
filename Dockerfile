FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

WORKDIR /app
COPY app/ .

# Build project
RUN mkdir build
RUN dotnet build -c Release -o /app/build --no-restore

# Publish project
RUN mkdir publish
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:6.0
COPY --from=build /app/publish .

EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "MyWebApp.dll"]
