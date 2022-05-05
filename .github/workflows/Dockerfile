FROM swaggest/json-cli:v1.9.1

#COPY /bin/json-cli ./json-cli

FROM php:cli-buster

COPY --from=0 /bin/json-cli /bin/json-cli
