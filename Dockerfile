FROM ubuntu:trusty
MAINTAINER Christian Höltje <choltje@us.ibm.com>
ENV REFRESHED_AT 2015-05-04

# Install packages
RUN apt-get -qq update && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl git apache2 php5 php5-mysql php5-pgsql php5-sqlite php5-gd php5-ldap && apt-get clean -y

# Create the data directory.
RUN mkdir /data && chown www-data:www-data -R /data && chmod 750 /data

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --filename=/usr/local/bin/composer

# Install Source
ENV KANBOARD_APP_VERSION 1.0.16
RUN cd /var/www && rm -rf html && git clone --depth=1 --branch=v${KANBOARD_APP_VERSION} https://github.com/fguillot/kanboard.git html

# Build PHP modules
RUN cd /var/www/html && composer --prefer-dist --no-dev --optimize-autoloader install

# Tools to configure kanboard and get it started.
COPY kanboard-configure.py /kanboard-configure.py
RUN chmod +x /kanboard-configure.py
COPY kanboard-start.sh /kanboard-start.sh
RUN chmod +x /kanboard-start.sh

# Some default variables.
ENV KANBOARD_DB_DRIVER sqlite
ENV KANBORAD_MARKDOWN_ESCAPE_HTML true
ENV KANBOARD_ENABLE_HSTS false
ENV KANBOARD_DB_NAME kanboard

EXPOSE 80
ENTRYPOINT ["/kanboard-start.sh"]
CMD ["start"]

# EOF
