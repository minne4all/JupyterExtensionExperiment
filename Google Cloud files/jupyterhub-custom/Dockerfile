FROM jupyter/base-notebook:python-3.10

# Install your JupyterLab extension
COPY exploratoryjupyterextension-0.2.0-py3-none-any.whl /tmp/exploratoryjupyterextension-0.2.0-py3-none-any.whl
RUN pip install /tmp/exploratoryjupyterextension-0.2.0-py3-none-any.whl && \
    jupyter lab build --dev-build=False --minimize=False

# Install python packages
RUN pip install pandas
RUN pip install scikit-learn
RUN pip install nltk
RUN pip install --upgrade "jupyterlab>=4.4,<5.0"

## Copy notebooks to /etc/skel so each new user gets a copy
# Copy both versions of the notebooks
COPY Experiment_notebooks_A/ /etc/skel/Experiment_notebooks_A/
COPY Experiment_notebooks_B/ /etc/skel/Experiment_notebooks_B/
# Copy logs directory to skel so it's copied for each user
COPY logs/ /etc/skel/logs/

# Add startup script that copies from /etc/skel to user's home
COPY init-user.sh /usr/local/bin/init-user.sh
COPY lab-settings/@jupyterlab/docmanager-extension/plugin.jupyterlab-settings /etc/skel/.jupyter/lab/user-settings/@jupyterlab/docmanager-extension/plugin.jupyterlab-settings


# Temporarily become root to set permissions
USER root
RUN chmod +x /usr/local/bin/init-user.sh

# Revert back to Jupyter's non-root user (jovyan)
USER ${NB_USER}

# Use your script to set up per-user content, then start notebook server
ENTRYPOINT ["/usr/local/bin/init-user.sh"]
CMD ["start-notebook.sh"]
