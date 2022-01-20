ARG BASE_IMAGE=ruby:2.7
FROM ${BASE_IMAGE}

WORKDIR /app

COPY Gemfile *.gemspec ./
COPY lib/k8s/ruby/version.rb ./lib/k8s/ruby/

RUN gem install bundler:2.3.5
RUN bundle install
RUN bundle update --bundler

COPY . .

ENTRYPOINT ["bundle", "exec"]
