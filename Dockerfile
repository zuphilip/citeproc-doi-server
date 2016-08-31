# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
# FROM phusion/passenger-full:0.9.19
# Or, instead of the 'full' variant, use one of these:
#FROM phusion/passenger-ruby20:<VERSION>
#FROM phusion/passenger-ruby21:<VERSION>
#FROM phusion/passenger-ruby22:<VERSION>
#FROM phusion/passenger-ruby23:<VERSION>
#FROM phusion/passenger-jruby91:<VERSION>
FROM phusion/passenger-nodejs:0.9.19
#FROM phusion/passenger-customizable:<VERSION>

# Set correct environment variables.
ENV HOME /home/app/webapp

# Use runit to manage sidekiq workers
# ENV RUNIT 1

# Allow app user to read /etc/container_environment
# RUN usermod -a -G app app
RUN usermod -a -G docker_env app

# Use baseimage-docker's init process
CMD ["/sbin/my_init"]
# CMD [ "npm", "start" ]

# Update installed APT packages, clean up when done
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get install ntp -y && \
    # apt-get install svn -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# If you're using the 'customizable' variant, you need to explicitly opt-in
# for features. Uncomment the features you want:
#
#   Build system and git.
#RUN /pd_build/utilities.sh
#   Ruby support.
#RUN /pd_build/ruby-2.0.*.sh
#RUN /pd_build/ruby-2.1.*.sh
#RUN /pd_build/ruby-2.2.*.sh
#RUN /pd_build/ruby-2.3.*.sh
#RUN /pd_build/jruby-9.1.*.sh
#   Python support.
#RUN /pd_build/python.sh
#   Node.js and Meteor support.
#RUN /pd_build/nodejs.sh

# ...put your own build instructions here...


# Enable Passenger and Nginx and remove the default site
# Preserve env variables for nginx
RUN rm -f /etc/service/nginx/down && \
    rm /etc/nginx/sites-enabled/default
COPY public/vendor/docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY public/vendor/docker/00_app_env.conf /etc/nginx/conf.d/00_app_env.conf
COPY public/vendor/docker/cors.conf /etc/nginx/conf.d/cors.conf

# Use Amazon NTP servers
COPY public/vendor/docker/ntp.conf /etc/ntp.conf

# Enable the memcached service
# RUN rm -f /etc/service/memcached/down

# Copy webapp folder
COPY . /home/app/webapp/
# RUN mkdir -p /home/app/webapp/tmp/pids && \
    # mkdir -p /home/app/webapp/vendor/bundle && \
RUN chown -R app:app /home/app/webapp && \
    chmod -R 755 /home/app/webapp

# Install npm and bower packages
WORKDIR /home/app/webapp/public/vendor
RUN /sbin/setuser app npm install
# && \
    # npm install -g phantomjs-prebuilt

# WORKDIR /home/app/webapp
# RUN svn export https://github.com/citation-style-language/styles/trunk && \
#     mv trunk styles && \
#     svn export https://github.com/citation-style-language/locales/trunk && \
#     mv trunk locales


# Install Ruby gems
# WORKDIR /home/app/webapp
# RUN /sbin/setuser app npm install
# RUN gem install bundler && \
#     /sbin/setuser app bundle install --path vendor/bundle

# Add Runit script for sidekiq workers
# RUN mkdir /etc/service/sidekiq
# ADD docker/sidekiq.sh /etc/service/sidekiq/run

# Run additional scripts during container startup (i.e. not at build time)
RUN mkdir -p /etc/my_init.d
# COPY docker/70_precompile.sh /etc/my_init.d/70_precompile.sh #ToDo
# COPY docker/80_cron.sh /etc/my_init.d/80_cron.sh
# COPY docker/90_migrate.sh /etc/my_init.d/90_migrate.sh


# Expose web
EXPOSE 80