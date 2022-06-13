# Build the runtime from source
ARG HOST_VERSION=4.5.0
ARG BRANCH=privatelinuxhost
ARG REPO="https://github.com/tjshen/azure-functions-host"
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS runtime-image
ARG HOST_VERSION
ARG BRANCH
ARG REPO

ENV PublishWithAspNetCoreTargetManifest=false

RUN mkdir -p /mnt/c/r/scratch/feed

ADD feed /mnt/c/r/scratch/feed

RUN BUILD_NUMBER=$(echo ${HOST_VERSION} | cut -d'.' -f 3) && \
    git clone --branch ${BRANCH} ${REPO} /src/azure-functions-host && \
    cd /src/azure-functions-host && \
    HOST_COMMIT=$(git rev-list -1 HEAD) && \
    dotnet publish -v q /p:BuildNumber=$BUILD_NUMBER /p:CommitHash=$HOST_COMMIT src/WebJobs.Script.WebHost/WebJobs.Script.WebHost.csproj -c Release --output /azure-functions-host --runtime linux-x64 && \
    mv /azure-functions-host/workers /workers && mkdir /azure-functions-host/workers && \
    rm -rf /root/.local /root/.nuget /src

RUN apt-get update && \
    apt-get install -y gnupg wget unzip && \
    EXTENSION_BUNDLE_VERSION_V2=2.12.1 && \
    EXTENSION_BUNDLE_FILENAME_V2=Microsoft.Azure.Functions.ExtensionBundle.${EXTENSION_BUNDLE_VERSION_V2}_linux-x64.zip && \
    wget https://functionscdn.azureedge.net/public/ExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/$EXTENSION_BUNDLE_VERSION_V2/$EXTENSION_BUNDLE_FILENAME_V2 && \
    mkdir -p /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/$EXTENSION_BUNDLE_VERSION_V2 && \
    unzip /$EXTENSION_BUNDLE_FILENAME_V2 -d /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/$EXTENSION_BUNDLE_VERSION_V2 && \
    rm -f /$EXTENSION_BUNDLE_FILENAME_V2 &&\
    EXTENSION_BUNDLE_VERSION_V3=3.9.1 && \
    EXTENSION_BUNDLE_FILENAME_V3=Microsoft.Azure.Functions.ExtensionBundle.${EXTENSION_BUNDLE_VERSION_V3}_linux-x64.zip && \
    wget https://functionscdn.azureedge.net/public/ExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/$EXTENSION_BUNDLE_VERSION_V3/$EXTENSION_BUNDLE_FILENAME_V3 && \
    mkdir -p /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/$EXTENSION_BUNDLE_VERSION_V3 && \
    unzip /$EXTENSION_BUNDLE_FILENAME_V3 -d /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/$EXTENSION_BUNDLE_VERSION_V3 && \
    rm -f /$EXTENSION_BUNDLE_FILENAME_V3 &&\
    find /FuncExtensionBundles/ -type f -exec chmod 644 {} \;

FROM mcr.microsoft.com/dotnet/runtime-deps:6.0
ARG HOST_VERSION

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    HOME=/home \
    FUNCTIONS_WORKER_RUNTIME=dotnet \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    HOST_VERSION=${HOST_VERSION} \
    ASPNETCORE_CONTENTROOT=/azure-functions-host \
    SERVERLESS_SECURITY_LOG_CONFIG=3fd2e3d4-485b-4bf1-aff1-77b30c02cbef \
    SERVERLESS_SECURITY_CONFIG=e6pbioYQImSkysdQyQpKL3Cb2/Kys214K1jaIB02V2iMnNcGe6i8aHTJglOxS3fKn1fPmbqL5Oxqsz8HcrwuHFahZOLEgnJh0VvoJkwOaYW152bApGoMpbJ/PecXUZdZ2MllfvxyVMSekpttRhfynKWS8cl+ZJNY/W5gu08+dJ52cm8XxAgtH48YMGG2KJN9OoBtL+RPHmVhjpaz8pVQRQ== \
    WEBSITE_OWNER_NAME=3e80626f-af91-4f0a-98ea-26ec24654d8e+RepoBuild-WestUS2webspace

# Fix from https://github.com/GoogleCloudPlatform/google-cloud-dotnet-powerpack/issues/22#issuecomment-729895157
RUN apt-get update && \
    apt-get install -y libc-dev

COPY --from=runtime-image [ "/azure-functions-host", "/azure-functions-host" ]
COPY --from=runtime-image [ "/FuncExtensionBundles", "/FuncExtensionBundles" ]

CMD [ "/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost" ]