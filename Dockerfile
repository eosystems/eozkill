FROM ruby:2.3

RUN mkdir -p /var/www/eozkill
WORKDIR /var/www/eozkill

RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y mysql-client postgresql-client sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y cron rsyslog supervisor vim locales locales-all --no-install-recommends
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# timezone
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN git clone https://github.com/eosystems/eozkill.git ./current
WORKDIR /var/www/eozkill/current

ENV RAILS_VERSION 5.0.1
RUN gem install rails --version "$RAILS_VERSION"
RUN bundle install --without development test

ADD .git/index /data/dummy_eozkill
COPY supervisord.conf /etc/

ARG gitbranch="master"
RUN git fetch
RUN git checkout $gitbranch
RUN git pull origin HEAD
RUN bundle install

RUN ln -s /data/eozkill/config/database.yml config/database.yml
RUN ln -s /data/eozkill/config/settings.yml config/settings.yml
RUN ln -s /data/eozkill/config/secrets.yml config/secrets.yml

# Cron
COPY /config/cron/cron.txt /var/crontab.txt
RUN crontab /var/crontab.txt
RUN chmod 600 /etc/crontab

CMD ["/usr/bin/supervisord"]
