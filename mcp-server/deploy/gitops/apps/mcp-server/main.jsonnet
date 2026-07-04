local deployment = import '../../lib/deployment.libsonnet';
local service = import '../../lib/service.libsonnet';
local configmap = import '../../lib/configmap.libsonnet';
local params = import './params.libsonnet';

// No ExternalSecret: the MCP holds no secrets. It validates nothing itself —
// it forwards each caller's cs-lab access_token to main-server, which owns
// JWT + admin/RBAC/permission enforcement.

local cm = configmap.new({
  name: params.name + '-config',
  namespace: params.namespace,
  data: {
    MCP_TRANSPORT: 'http',
    MCP_ADDR: ':' + std.toString(params.port),
    MCP_PATH: '/mcp',
    MAIN_SERVER_URL: params.mainServerUrl,
    OTEL_SERVICE_NAME: 'mcp-server',
    OTEL_EXPORTER_OTLP_ENDPOINT: 'http://jaeger.cs-lab.svc.cluster.local:4317',
  },
});

local deploy = deployment.new({
  name: params.name,
  namespace: params.namespace,
  env: params.env,
  image: params.image,
  replicas: params.replicas,
  port: params.port,
  envFrom: [
    { configMapRef: { name: params.name + '-config' } },
  ],
  resources: params.resources,
});

local svc = service.new({
  name: params.name,
  namespace: params.namespace,
  env: params.env,
  ports: [{ name: 'http', port: params.port, targetPort: params.port, protocol: 'TCP' }],
});

{ apiVersion: 'v1', kind: 'List', items: [cm, deploy, svc] }
