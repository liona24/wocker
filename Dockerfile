FROM debian:latest

ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USERNAME=pleb

RUN apt-get update --fix-missing && apt upgrade -y

RUN apt-get install -y build-essential ca-certificates curl wget git python3-pip python3-neovim cmake fonts-powerline libfreetype6-dev libfontconfig1-dev xclip tmux ripgrep

# Add fish
RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_10/ /' > /etc/apt/sources.list.d/shells:fish:release:3.list
RUN wget -nv https://download.opensuse.org/repositories/shells:fish:release:3/Debian_10/Release.key -O Release.key
RUN apt-key add - < Release.key
RUN apt-get update
RUN apt-get install -y fish

RUN rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /usr/bin/fish --uid $USER_UID --gid $USER_GID -m $USERNAME

# Create home directory
WORKDIR /home/${USERNAME}
RUN chown $USERNAME:$USERNAME -R /home/${USERNAME}

USER ${USERNAME}

ENV LC_CTYPE C.UTF-8

RUN mkdir .wocker

# add custom utility scripts
RUN mkdir .local/
RUN git clone https://github.com/liona24/utility-scripts.git .local/utility-scripts
ENV PATH $(pwd)/.local/utility-scripts:$PATH

RUN curl -L https://get.oh-my.fish > install
RUN fish install --path=/home/${USERNAME}/.local/share/omf --config=/home/${USERNAME}/.config/omf --noninteractive --yes
RUN rm install
RUN fish -c "omf install batman"

# Upgrade VIM to the next level
RUN curl -fLo /home/${USERNAME}/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
RUN mkdir -p .config/nvim
COPY ./vimrc .config/nvim/init.vim
RUN vim --headless +PlugInstall +qall > /dev/null

COPY ./tmux.conf .tmux.conf

# Configure fish
COPY ./config.fish .config/fish/config.fish
RUN touch /home/${USERNAME}/.config/fish/functions/fish_mode_prompt.fish
RUN touch /home/${USERNAME}/.wocker/fish_history
RUN ln -s /home/${USERNAME}/.wocker/fish_history /home/${USERNAME}/.local/share/fish/fish_history

VOLUME .wocker

ENTRYPOINT tmux
