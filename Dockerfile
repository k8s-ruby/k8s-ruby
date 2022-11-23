ARG BASE_IMAGE=ruby:2.7
FROM ${BASE_IMAGE}

RUN gem install bundler:2.3.5

WORKDIR /app

COPY Gemfile *.gemspec ./
COPY lib/k8s/ruby/version.rb ./lib/k8s/ruby/

RUN bundle install
RUN bundle update --bundler

COPY . .
ENTRYPOINT ["/app/entrypoint.sh"]
