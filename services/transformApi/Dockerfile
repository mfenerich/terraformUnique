# Using an image for dependency build stage which provides Poetry
# see: https://github.com/max-pfeiffer/python-poetry/blob/main/build/Dockerfile
FROM pfeiffermax/python-poetry:1.8.0-poetry1.7.1-python3.12.0-slim-bookworm AS dependencies-build-stage
ENV POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_CACHE_DIR="/application_root/.cache" \
    PYTHONPATH=/application_root  \
    HF_HOME=/data/huggingface

# Set the WORKDIR to the application root.
WORKDIR ${PYTHONPATH}

# Install dependencies from pyproject.toml
COPY ./pyproject.toml ${PYTHONPATH}
RUN poetry install --no-interaction --no-root --without dev

# Using the standard Python image here for a lean production image.
FROM python:3.12.0-slim-bookworm AS production-image
ARG APPLICATION_SERVER_PORT=8000

# Set environment variables for production, including TRANSFORMERS_CACHE
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/application_root \
    VIRTUAL_ENVIRONMENT_PATH="/application_root/.venv" \
    APPLICATION_SERVER_PORT=$APPLICATION_SERVER_PORT \
    HF_HOME=/data/huggingface

# Add the virtual environment to PATH
ENV PATH="$VIRTUAL_ENVIRONMENT_PATH/bin:$PATH"

# Create a new user for running the application
RUN groupadd -g 10001 python_application && \
    useradd -r -u 10001 -g python_application python_application

# Set the working directory and adjust ownership
WORKDIR ${PYTHONPATH}
RUN chown python_application:python_application ${PYTHONPATH}

# Copy the virtual environment from the dependencies stage
COPY --from=dependencies-build-stage --chown=python_application:python_application ${VIRTUAL_ENVIRONMENT_PATH} ${VIRTUAL_ENVIRONMENT_PATH}

# Copy application files
COPY --chown=python_application:python_application /app ${PYTHONPATH}/app/

# Expose the application port
EXPOSE ${APPLICATION_SERVER_PORT}

# Start the uvicorn application server
CMD exec uvicorn --workers 1 --host 0.0.0.0 --port $APPLICATION_SERVER_PORT app.main:app
