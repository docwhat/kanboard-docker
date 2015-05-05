FROM ubuntu:trusty
MAINTAINER Christian Höltje <choltje@us.ibm.com>
ENV REFRESHED_AT 2015-05-04

# Setup apache and friends.
RUN apt-get -qq update && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl git apache2 php5 php5-mysql php5-pgsql php5-sqlite php5-gd php5-ldap && apt-get clean -y
RUN echo "ServerName \${APACHE_HOSTNAME}" >> /etc/apache2/apache2.conf

# Create the data directory.
RUN mkdir /data && chown www-data:www-data -R /data && chmod 750 /data

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --filename=/usr/local/bin/composer

# Install Source
RUN cd /var/www && rm -rf html && git clone --depth=1 --branch=v1.0.14 https://github.com/fguillot/kanboard.git html

# Build PHP modules
RUN cd /var/www/html && composer install

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
CMD ["/kanboard-start.sh"]

# EOF