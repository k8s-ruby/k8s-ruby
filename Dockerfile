FROM ruby:2.6.0

WORKDIR /app

COPY Gemfile *.gemspec ./
COPY lib/k8s/ruby/version.rb ./lib/k8s/ruby/

RUN gem install bundler
RUN bundle install
RUN bundle update --bundler

COPY . .

ENTRYPOINT ["bundle", "exec"]
