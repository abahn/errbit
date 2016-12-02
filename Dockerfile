FROM ruby:2.3.3

RUN apt-get update -qq && \
  apt-get install -y build-essential \
  libpq-dev \
  nodejs
COPY . /app
RUN cd app && \
  bundle install --without test development && \
  bundle exec rake assets:precompile

WORKDIR /app

CMD ["bundle","exec","puma","-C","config/puma.default.rb"]
