FROM php:7.4.33-zts-alpine

# apt dependencies
RUN apk add --no-cache --upgrade bash shadow curl zip unzip git libzip-dev net-tools

# install php extensions provided by docker image
RUN docker-php-ext-install zip sockets

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# composer need to run as user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup -s $(which bash)
USER appuser
WORKDIR /app
COPY . /app

# application install
RUN composer install --no-dev --optimize-autoloader && composer clear-cache
