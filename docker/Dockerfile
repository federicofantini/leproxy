FROM php:7.4-cli AS builder

# apt dependencies
RUN apt update && apt-get install -y curl zip unzip git libzip-dev

# install php extensions provided by docker image
RUN docker-php-ext-install zip sockets

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# composer need to run as user
RUN useradd -ms /bin/bash user
USER user
WORKDIR /app
COPY . /app

# application install
RUN composer install --no-dev --optimize-autoloader && composer clear-cache

# multistage
FROM php:7.4-cli
WORKDIR /app
COPY --from=builder /app /app