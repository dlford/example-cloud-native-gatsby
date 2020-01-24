FROM node:11-alpine AS builder_gatsby
RUN apk add --no-cache --virtual .gyp python make g++
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

FROM golang:alpine AS builder_go
WORKDIR $GOPATH
COPY ./docker/healthcheck ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/healthcheck

FROM nginx:alpine
COPY --from=builder_gatsby --chown=nginx:nginx /app/public /usr/share/nginx/html
COPY --from=builder_go --chown=nginx:nginx /go/bin/healthcheck /usr/local/bin/healthcheck
COPY ./docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx:nginx /var/cache/nginx

ENV NODE_ENV=production
ENV HEALTHCHECK_PORT=8000
USER nginx
EXPOSE 8000
HEALTHCHECK --start-period=15s --interval=1m --timeout=5s CMD /usr/local/bin/healthcheck
