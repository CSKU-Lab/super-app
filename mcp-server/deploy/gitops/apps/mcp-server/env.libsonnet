{
  namespace: 'cs-lab',
  env: 'production',
  imageTag: 'v0.1.0',
  replicas: 1,
  resources: {
    requests: { cpu: '50m', memory: '32Mi' },
    limits: { cpu: '250m', memory: '96Mi' },
  },
}
