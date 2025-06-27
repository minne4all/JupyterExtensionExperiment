#!/bin/bash

NAMESPACE="jhub"
DEST_DIR="./user_data"
mkdir -p "$DEST_DIR"

# PVC list
kubectl get pvc -n $NAMESPACE -o name | grep 'claim-' | while read pvc; do
  pvc_name=$(basename "$pvc")
  username=${pvc_name#claim-}
  pod_name="copy-pvc-$username"
  mount_path="/mnt/userdata"

  echo "🔄 Processing PVC: $pvc_name (user: $username)"

  # Generate a temp pod manifest file
  pod_yaml=$(mktemp)
  cat <<EOF > $pod_yaml
apiVersion: v1
kind: Pod
metadata:
  name: $pod_name
  namespace: $NAMESPACE
spec:
  containers:
    - name: copy
      image: python:3.9-slim
      command: ["sleep", "3600"]
      volumeMounts:
        - name: userdata
          mountPath: $mount_path
  volumes:
    - name: userdata
      persistentVolumeClaim:
        claimName: $pvc_name
  restartPolicy: Never
EOF

  # Apply the pod manifest
  kubectl apply -f "$pod_yaml"

  # Wait for pod to be Running
  echo "⏳ Waiting for pod $pod_name to be ready..."
  for i in {1..30}; do
    phase=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [[ "$phase" == "Running" ]]; then
      break
    fi
    sleep 2
  done

  if [[ "$phase" != "Running" ]]; then
    echo "❌ Pod $pod_name failed to start. Skipping $username."
    kubectl delete pod "$pod_name" -n "$NAMESPACE" --ignore-not-found=true
    rm "$pod_yaml"
    continue
  fi

  # Copy files from mounted volume
  user_dir="$DEST_DIR/$username"
  mkdir -p "$user_dir"
  echo "📥 Copying files from $mount_path to $user_dir..."
  kubectl cp "$NAMESPACE/$pod_name:$mount_path/." "$user_dir/" --retries=3

#   # Clean up
  echo "🧹 Cleaning up pod $pod_name"
  kubectl delete pod "$pod_name" -n "$NAMESPACE" --ignore-not-found=true
  rm "$pod_yaml"

  echo "✅ Done with $username"
done
