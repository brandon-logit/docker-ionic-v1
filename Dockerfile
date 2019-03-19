FROM ubuntu:16.04
MAINTAINER Brandon Lee
ENV VERSION_SDK_TOOLS "4333796"

ENV ANDROID_HOME "/sdk"



# Install apt packages
RUN apt-get update --fix-missing && apt-get install --yes curl unzip wget
RUN curl --silent --location https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y git lib32stdc++6 lib32z1 nodejs build-essential openjdk-8-jdk libio-socket-ssl-perl libnet-ssleay-perl bzip2 html2text libc6-i386 lib32gcc1 lib32ncurses5 ruby ruby-dev && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"  
ENV PATH "$PATH:${JAVA_HOME}/bin"

# Install android SDK, tools and platforms
RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
  unzip /sdk.zip -d /sdk && \
  rm -v /sdk.zip

RUN mkdir -p $ANDROID_HOME/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

RUN yes | $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-28"

ADD packages.txt /sdk

RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update 

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < /sdk/packages.txt && \
  ${ANDROID_HOME}/tools/bin/sdkmanager ${PACKAGES}

# RUN echo 'y' | /opt/android-sdk-linux/tools/android update sdk --no-ui -a -t platform-tools,build-tools-23.0.3,android-23,extra-android-support,extra-google-m2repository,extra-android-m2repository

# RUN mkdir "$ANDROID_HOME/licenses" && echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > "$ANDROID_HOME/licenses/android-sdk-license"
# Install npm packages
RUN npm i -g cordova ionic gulp bower grunt && npm cache clean

# Create dummy app to build and preload gradle and maven dependencies
RUN git config --global user.email "you@example.com" && git config --global user.name "Your Name"
RUN wget https://services.gradle.org/distributions/gradle-3.3-all.zip && mkdir /opt/gradle && unzip -d /opt/gradle gradle-3.3-all.zip
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin::/opt/gradle/gradle-3.3/bin
ENV PATH "$PATH:${ANDROID_HOME}/tools"

RUN gradle -v

COPY Gemfile.lock .
COPY Gemfile .

RUN gem install bundle
RUN bundle install

WORKDIR /app