if [[ "$(uname)" == "Darwin" ]]; then
  if [ -x "$(command -v minikube)" ]; then
    minikube start
    eval $(minikube docker-env)
  fi
fi
