local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.renovate;

local redisUrl = 'redis://%s.%s.svc.cluster.local:6379/0' % [
  params.components.valkey.release_name,
  params.components.valkey.namespace,
];

local component =
  if params.components.valkey.enabled then
    {
      env: {
        RENOVATE_REDIS_URL: redisUrl,
      },
    }
  else
    {};

{
  'values-component': component,
  'values-overrides': params.helm_values,
}
