# MongoDB Operator

Percona Operator for MongoDB CRDs, RBAC, and deployment for the `dev` namespace.

## Files

| File | Description |
|---|---|
| `ns.yaml` | Namespace definition (`dev`) |
| `mongo-operator-crds.yaml` | Custom Resource Definitions for PerconaServerMongoDB |
| `mongo-operator-rbac.yaml` | Operator ServiceAccount, Roles, and RoleBindings |
| `mongo-operator.yaml` | Operator Deployment (helm-templated) |
| `mongo-operator-patch.yaml` | Kustomize patch — sets `WATCH_NAMESPACE=dev` |
| `kustomization.yaml` | Composes resources and applies the namespace patch |
| `Makefile` | Self-contained targets for operator lifecycle |

## Notes

The Percona CRD is too large for a normal `kubectl apply`. Use server-side apply:

```
make -C operator/mongo apply
```

## Makefile targets

```
make -C operator/mongo apply             # kubectl apply --server-side --force-conflicts
make -C operator/mongo dump              # kustomize render
make -C operator/mongo diff              # kubectl diff --server-side
make -C operator/mongo update-operator   # re-download CRDs, RBAC, and operator from Percona v1.15.0
```
