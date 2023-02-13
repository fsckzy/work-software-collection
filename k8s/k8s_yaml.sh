#!/bin/bash

appId=$1
appPort=$2
replicas=$3
dcHost=$4
REGISTRY=$5
build_number=${BUILD_NUMBER}

cat > ${appId}.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ${appId}
  name: ${appId}
  namespace: app
spec:
  progressDeadlineSeconds: 600
  replicas: ${replicas}
  selector:
    matchLabels:
      app: ${appId}
  template:
    metadata:
      labels:
        app: ${appId}
    spec:
      containers:
        - image: $REGISTRY/$appId:$build_number
          imagePullPolicy: Always
          name: ${appId}
          readinessProbe:
            tcpSocket:
              port: ${appPort}
            timeoutSeconds: 50
            periodSeconds: 50
            successThreshold: 1
            failureThreshold: 3
          ports:
            - name: tcp-${appPort}
              containerPort: ${appPort}
              protocol: TCP
          resources:
            limits:
              cpu: 500m
              memory: 2Gi
            requests:
              cpu: 300m
              memory: 1Gi
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: ${appId}
                topologyKey: kubernetes.io/hostname
      restartPolicy: Always
      hostAliases:
      - ip: "192.168.96.252"
        hostnames:
        - "xx.cn"
        - "xxx.cn"
      terminationGracePeriodSeconds: 30
      imagePullSecrets:
        - name: smy

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: ${appId}
  name: ${appId}-svc
  namespace: app
spec:
  ports:
    - name: http-${appPort}
      port: ${appPort}
      protocol: TCP
      targetPort: ${appPort}
  selector:
    app: ${appId}
  type: ClusterIP

---

kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: ${appId}-ingress
  namespace: app
  labels:
    app: ${appId}

  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 50m
    nginx.ingress.kubernetes.io/proxy-connect-timeout: '600'
    nginx.ingress.kubernetes.io/proxy-read-timeout: '600'
    nginx.ingress.kubernetes.io/proxy-send-timeout: '600'
spec:
  rules:
    - host: ${dcHost}
      http:
        paths:
          - path: /${appId}
            backend:
              serviceName: ${appId}-svc
              servicePort: ${appPort}
EOF
