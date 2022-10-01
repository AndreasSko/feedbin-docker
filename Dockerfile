FROM ruby:3.1.2 AS builder

ARG FEEDBIN_URL
ARG FEEDBIN_REPO

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libldap-2.4-2 \
    libidn11-dev \
    dnsutils \
    nodejs \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && gem install idn-ruby -v '0.1.0'

RUN git clone ${FEEDBIN_REPO:-https://github.com/feedbin/feedbin.git} /app

RUN gem install bundler -v '2.1.2' \
    && bundle install \
    && bundle exec rake assets:precompile

RUN rm -rf .git

RUN sed -i 's/-c [[:digit:]]*/-c ${SIDEKIQ_CONCURRENCY:-1}/g' /app/Procfile

FROM ruby:3.1.2

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libidn11-dev nodejs postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle

ENV RAILS_SERVE_STATIC_FILES=true

EXPOSE 3000

