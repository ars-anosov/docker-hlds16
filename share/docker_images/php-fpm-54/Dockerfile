FROM php:5.4-fpm

# Set environment variables
ARG TZ=Europe/Moscow
ENV TZ ${TZ}
# Set the timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libcurl4-nss-dev \
        libc-client-dev \
        libkrb5-dev \
        libicu-dev \
        libxml2-dev \
        libxslt1-dev \
        libssh2-1-dev \
        ssmtp \
        cron \
        vim

RUN docker-php-ext-install mcrypt \
    && docker-php-ext-install curl \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install iconv \
    && docker-php-ext-install intl \
    && docker-php-ext-install soap \
    && docker-php-ext-install xmlrpc \
    && docker-php-ext-install xsl \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-install mysql mysqli pdo pdo_mysql \
    && docker-php-ext-install zip

# redis module
# RUN \
#   pecl install -o -f redis \
#   &&  echo "extension=redis.so" > /usr/local/etc/php/conf.d/ext-redis.ini

# ssh2 module
RUN \
  pecl install ssh2 \
  && echo "extension=ssh2.so" > /usr/local/etc/php/conf.d/ext-ssh2.ini

# Install the xdebug extension
RUN pecl install -f xdebug-2.4.0 && \
    docker-php-ext-enable xdebug

# Copy xdebug configration for remote debugging
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Copy the php-fpm config
COPY ./dockerhero.php.ini /usr/local/etc/php/conf.d/dockerhero.php.ini
COPY ./dockerhero.fpm.conf /usr/local/etc/php-fpm.d/zzz-dockerhero.fpm.conf

# Setup sSMTP
RUN cp /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.bak
COPY ./ssmtp.conf /etc/ssmtp/ssmtp.conf

# Cleanup all downloaded packages
RUN apt-get -y autoclean && apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/* && apt-get update

# Set the proper permissions
RUN usermod -u 1000 www-data

CMD ["php-fpm"]