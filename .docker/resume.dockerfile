FROM ubuntu

# prepare a user which runs everything locally! - required in child images!
RUN useradd --user-group --create-home --shell /bin/false app

ENV HOME=/home/app
WORKDIR $HOME

RUN apt-get update && \
    apt-get install -y \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    apt-get autoclean && \
    apt-get clean


# Install language tool
ENV VERSION 4.4
RUN echo Downloading languagetool... ; \
    wget -q https://www.languagetool.org/download/LanguageTool-$VERSION.zip \
    && unzip LanguageTool-4.4.zip -d /opt \
    && rm LanguageTool-$VERSION.zip \
    && find . -name '*.jar' -exec chmod a+x {} \;


RUN mkdir /nonexistent && touch /nonexistent/.languagetool.cfg

RUN wget -q https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh && \
    bash Miniconda3-4.5.11-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-4.5.11-Linux-x86_64.sh && \
    ln -s /usr/local/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /usr/local/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc

ENV PATH="/usr/local/miniconda/bin:$PATH" \
        CPATH="/usr/local/miniconda/include/:$CPATH" \
        LANG="C.UTF-8" \
        LC_ALL="C.UTF-8" \
        PYTHONNOUSERSITE=1

RUN conda install -y \
    beautifulsoup4 \
    git \
    openjdk \
    pandoc \
    make \
    && chmod -R a+wrX /usr/local/miniconda; sync && \
    conda clean -tiqly; sync

RUN pip install pylanguagetool

ENV APP_NAME=resume

# before switching to user we need to set permission properly
# copy all files, except the ignored files from .dockerignore
COPY . $HOME/$APP_NAME/
COPY ./Makefile $HOME/$APP_NAME/
RUN chown -R app:app $HOME/*

USER app
WORKDIR $HOME/$APP_NAME
# RUN java -cp /opt/LanguageTool-4.4/languagetool-server.jar org.languagetool.server.HTTPServer --port 8010 &
# RUN pylanguagetool output/resume.html --api-url http://localhost:8010

RUN make clean
# EXPOSE 8010
