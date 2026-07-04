local env = import './env.libsonnet';

{
  name: 'mcp-server',
  namespace: env.namespace,
  env: env.env,
  image: 'cskulab/mcp-server:' + env.imageTag,
  replicas: env.replicas,
  port: 8090,

  // NOTE: verify main-server's in-cluster port. The MCP forwards the caller's
  // access_token cookie to these REST endpoints; it holds no secrets of its own.
  mainServerUrl: 'http://main-server.' + env.namespace + '.svc.cluster.local:3000',

  resources: env.resources,
}
