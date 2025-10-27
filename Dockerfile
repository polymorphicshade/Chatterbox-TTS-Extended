FROM python:3.10-slim

# Set default UID/GID arguments
ARG UID=0
ARG GID=0
ARG USER_HOME=/root

# Set Gradio arguments
ARG GRADIO_SERVER_PORT=7860
ARG GRADIO_SERVER_NAME=0.0.0.0
ARG GRADIO_ANALYTICS_ENABLED=False
ARG GRADIO_SHARE=False  

RUN apt-get update --quiet=2 \
  && apt-get upgrade --assume-yes \
  && apt-get --quiet=2 install --no-install-recommends --assume-yes ffmpeg \
  && apt-get clean \
  && rm -rf /var/lib/apt

# Add user/group
ENV HOME=$USER_HOME
RUN if [ $UID -ne 0 ]; then \
      if [ $GID -ne 0 ]; then \
        addgroup --system --gid $GID app; \
      fi; \
      adduser --system --no-create-home --uid $UID --gid $GID \
      --home $USER_HOME app; \
    fi

# Handle paths
RUN mkdir --parents $HOME /app
RUN chown --recursive $UID:$GID $HOME /app

# Populate environment
ENV GRADIO_SERVER_PORT=$GRADIO_SERVER_PORT
ENV GRADIO_SERVER_NAME=$GRADIO_SERVER_NAME
ENV GRADIO_ANALYTICS_ENABLED=$GRADIO_ANALYTICS_ENABLED
ENV GRADIO_SHARE=$GRADIO_SHARE

EXPOSE $GRADIO_SERVER_PORT

# Switch user
USER $UID:$GID

# Configure Python virtual vnvironment
ENV VIRTUAL_ENV=$HOME/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /app

# Copy application files
COPY --chown=$UID:$GID . .

# Install dependencies
RUN pip install --upgrade pip
RUN pip install --requirement requirements.txt

# Fix CUDA cudnn path
ENV LD_LIBRARY_PATH=$VIRTUAL_ENV/lib/python3.10/site-packages/nvidia/cudnn/lib:$VIRTUAL_ENV/lib/python3.10/site-packages/nvidia/cuda_runtime/lib:$LD_LIBRARY_PATH

# Run the app
CMD ["python", "Chatter.py"]
