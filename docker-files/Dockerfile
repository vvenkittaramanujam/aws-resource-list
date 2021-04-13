FROM php:7-apache

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY start-apache /usr/local/bin
RUN chmod 755 /usr/local/bin/start-apache
RUN a2enmod rewrite

RUN curl -O https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py --user
RUN export PATH=~/.local/bin:$PATH
RUN source ~/.bash_profile
RUN pip3 install awscli --upgrade --user

# Copy application source
COPY src /var/www/php
RUN chown -R www-data:www-data /var/www/php

EXPOSE 80

CMD ["start-apache"]
