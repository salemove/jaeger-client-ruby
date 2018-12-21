FROM ruby:2.5-alpine

ENV APP_HOME /app

# git is required by bundler to run jaeger gem with local path
RUN apk add --no-cache git

# Add only files needed for installing gem dependencies. This allows us to
# change other files without needing to install gems every time when building
# the docker image.
ADD Gemfile Gemfile.lock jaeger-client.gemspec $APP_HOME/
ADD lib/jaeger/client/version.rb $APP_HOME/lib/jaeger/client/
ADD crossdock/Gemfile crossdock/Gemfile.lock $APP_HOME/crossdock/

RUN apk add --no-cache --virtual .app-builddeps build-base \
  && cd $APP_HOME && bundle install \
  && cd $APP_HOME/crossdock && bundle install \
  && apk del .app-builddeps

ADD . $APP_HOME

RUN chown -R nobody:nogroup $APP_HOME
USER nobody

WORKDIR $APP_HOME/crossdock

CMD ["bundle", "exec", "./server"]

EXPOSE 8080-8082
