local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.renovate;
local instance = inv.parameters._instance;
local argocd = import 'lib/argocd.libjsonnet';

local componentName = 'renovate';
local appName =
  if instance == componentName then componentName else '%s-%s' % [componentName, instance];
local app = argocd.App(appName, params.namespace);

local appPath =
  local project = std.get(std.get(app, 'spec', {}), 'project', 'syn');
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/%s' % [appPath, appName]]: app,
}
